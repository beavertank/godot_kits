extends MeshInstance3D
## Example only: draws where the tractor has been (cyan) and where the last trailer's rear
## axle has been (pink), so you can see the trailer cut inside on the turns.

@export var chain: TrailerChain
@export var length := 400

var _tractor: Array[Vector3] = []
var _axle: Array[Vector3] = []
var _im := ImmediateMesh.new()


func _ready() -> void:
	mesh = _im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	material_override = m
	process_priority = 200


func _process(_delta: float) -> void:
	if chain == null or chain.axles.is_empty():
		return
	var tp: Vector3 = chain.tractor.global_position
	if _tractor.is_empty() or _tractor.back().distance_to(tp) > 0.2:
		_tractor.append(tp)
		_axle.append(chain.axles.back())
		if _tractor.size() > length:
			_tractor.pop_front()
			_axle.pop_front()
	_im.clear_surfaces()
	if _tractor.size() < 2:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_ribbons(_tractor, Color(0.1, 0.9, 1.0))
	_ribbons(_axle, Color(1.0, 0.25, 0.85))
	_im.surface_end()


func _ribbons(pts: Array[Vector3], col: Color) -> void:
	for i in range(1, pts.size()):
		var a := pts[i - 1] + Vector3(0, 0.03, 0)
		var b := pts[i] + Vector3(0, 0.03, 0)
		var side := Vector3(-(b - a).z, 0, (b - a).x).normalized() * 0.07
		for p in [a - side, b - side, b + side, a - side, b + side, a + side]:
			_im.surface_set_color(col)
			_im.surface_add_vertex(p)
