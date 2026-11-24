class_name LensDOF
extends Node
## Depth of field that also works on the Compatibility renderer (which has none built in).
##
## Add this node anywhere in your scene. It blurs what the camera sees by distance from a
## focus point, like a real lens wide open. Two passes:
##   1. A hidden SubViewport (sharing your world) holds a copy of the camera. It sees one
##      full-screen quad that turns the depth buffer into a blur map (lens_coc.gdshader).
##   2. A full-screen ColorRect on a CanvasLayer blurs the finished frame by that map
##      (lens_blur.gdshader). It's below your UI (canvas_layer -1), so the UI stays sharp.
## Doing it in two passes keeps transparent objects (smoke, glass): a single 3D full-screen
## quad would read the screen before they're drawn and paint over them.
##
## Cost: the scene is drawn twice. Fine for cut-scenes, photo modes and recorded clips.

@export var camera: Camera3D                  ## the camera to blur (default: the current one)
@export var focus_target: Node3D              ## keep this in focus (or use focus_distance)
@export var focus_distance := 10.0            ## metres along the view, when there's no target
@export_range(0.0, 3.0) var aperture := 0.7   ## how quickly things blur away from the focus
@export_range(0.0, 0.2) var sharp_zone := 0.06    ## a little depth that stays fully sharp
@export_range(0.0, 0.05) var max_blur := 0.014    ## the most blur, as a share of screen height
@export_range(0.0, 20.0) var focus_speed := 6.0   ## how fast the focus eases to its target (0 = instantly)
@export_range(1, 20) var render_layer := 20   ## a render layer nothing else uses (for the quad)
@export var canvas_layer := -1                ## under your UI's CanvasLayers

var _vp: SubViewport
var _dcam: Camera3D
var _coc_mat: ShaderMaterial
var _blur_mat: ShaderMaterial
var _focus := -1.0


func _ready() -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()
	var bit := 1 << (render_layer - 1)
	# pass 1: the hidden camera and its quad
	_vp = SubViewport.new()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.size = Vector2i(get_viewport().get_visible_rect().size)
	add_child(_vp)                                 # (a SubViewport shares its parent's World3D)
	_dcam = Camera3D.new()
	var env := Environment.new()                   # no tonemapping or fog on the grey levels
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_dcam.environment = env
	_dcam.cull_mask = camera.cull_mask | bit
	_vp.add_child(_dcam)
	var quad := MeshInstance3D.new()
	quad.mesh = QuadMesh.new()
	quad.layers = bit
	quad.extra_cull_margin = 16384.0               # never culled
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_coc_mat = ShaderMaterial.new()
	_coc_mat.shader = preload("lens_coc.gdshader")
	_coc_mat.render_priority = 127
	quad.material_override = _coc_mat
	_dcam.add_child(quad)
	quad.position = Vector3(0, 0, -1)
	camera.cull_mask &= ~bit                       # your camera never sees the quad
	# pass 2: the blur over the finished frame
	var layer := CanvasLayer.new()
	layer.layer = canvas_layer
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur_mat = ShaderMaterial.new()
	_blur_mat.shader = preload("lens_blur.gdshader")
	_blur_mat.set_shader_parameter("coc_tex", _vp.get_texture())
	rect.material = _blur_mat
	layer.add_child(rect)
	_check_encoding()


## Some setups store a SubViewport's colors with an sRGB curve. Write a known 0.5 for a
## couple of frames, read it back and decode to match.
func _check_encoding() -> void:
	_coc_mat.set_shader_parameter("debug_value", 0.5)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	var v := img.get_pixel(img.get_width() / 2, img.get_height() / 2).r
	_blur_mat.set_shader_parameter("coc_gamma", log(0.5) / log(v) if v > 0.6 and v < 0.99 else 1.0)
	_coc_mat.set_shader_parameter("debug_value", -1.0)


func _process(delta: float) -> void:
	if camera == null:
		return
	_vp.size = Vector2i(get_viewport().get_visible_rect().size)
	_dcam.global_transform = camera.global_transform
	_dcam.projection = camera.projection
	_dcam.fov = camera.fov
	_dcam.size = camera.size
	_dcam.keep_aspect = camera.keep_aspect
	_dcam.near = camera.near
	_dcam.far = camera.far
	# the focus: the target's distance along the view (like a camera's focus distance), eased
	var want := focus_distance
	if focus_target != null:
		want = maxf((focus_target.global_position - camera.global_position).dot(-camera.global_transform.basis.z), 0.05)
	if _focus < 0.0 or focus_speed <= 0.0:
		_focus = want
	else:
		_focus = lerpf(_focus, want, 1.0 - exp(-focus_speed * delta))
	_coc_mat.set_shader_parameter("focus", _focus)
	_coc_mat.set_shader_parameter("aperture", aperture)
	_coc_mat.set_shader_parameter("sharp", sharp_zone)
	_blur_mat.set_shader_parameter("max_radius", max_blur)
