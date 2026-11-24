class_name TiltShiftBand
extends Node
## Optional helper for tilt_shift.gdshader: aims the sharp band at your world every frame, so
## it stays on what matters however the camera moves.
##
## Place four Marker3Ds: two along the line the band should follow (a road, a shoreline), and
## one at each edge of what should be sharp. The band runs parallel to the first two (as they
## look on screen) and spans the other two.

@export var camera: Camera3D           ## (default: the current camera)
@export var target: CanvasItem         ## the ColorRect with tilt_shift.gdshader
@export var line_a: Node3D             ## two points along the band's direction
@export var line_b: Node3D
@export var edge_near: Node3D          ## the sharp band reaches from here...
@export var edge_far: Node3D           ## ...to here


func _process(_delta: float) -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if camera == null or target == null or line_a == null or line_b == null or edge_near == null or edge_far == null:
		return
	var mat := target.material as ShaderMaterial
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / vp.y
	var a := _aspect_pos(line_a.global_position, vp, aspect)
	var b := _aspect_pos(line_b.global_position, vp, aspect)
	var dir := (b - a).normalized()
	var n := Vector2(-dir.y, dir.x)
	var e1 := _aspect_pos(edge_near.global_position, vp, aspect)
	var e2 := _aspect_pos(edge_far.global_position, vp, aspect)
	var d1 := e1.dot(n)
	var d2 := e2.dot(n)
	# a point on the band's centre line, back in screen UV
	var c := e1 + n * ((d2 - d1) * 0.5)
	mat.set_shader_parameter("band_center", Vector2(c.x / aspect, c.y))
	mat.set_shader_parameter("band_angle", rad_to_deg(atan2(dir.y, dir.x)))
	mat.set_shader_parameter("band_half_width", absf(d2 - d1) * 0.5)


## Where a world point lands on screen, in "aspect space" (UV with x times width/height).
func _aspect_pos(p: Vector3, vp: Vector2, aspect: float) -> Vector2:
	var s := camera.unproject_position(p) / vp
	return Vector2(s.x * aspect, s.y)
