class_name SeeThroughBoxes
extends Node
## Feeds see_through.gdshader: each frame, the world bounding boxes of the `targets` (the
## things that must stay visible) go to every `occluders` material, and the occluders go
## see-through wherever they'd hide one.
##
## Each occluder needs a ShaderMaterial with see_through.gdshader as its material_override.

const MAX_BOXES := 32     # must match MAX_BOXES in see_through.gdshader

@export var occluders: Array[GeometryInstance3D] = []
@export var targets: Array[VisualInstance3D] = []


func _process(_delta: float) -> void:
	var lo := PackedVector4Array()
	var hi := PackedVector4Array()
	lo.resize(MAX_BOXES)
	hi.resize(MAX_BOXES)
	var n := 0
	for t in targets:
		if t == null or not t.is_visible_in_tree() or n >= MAX_BOXES:
			continue
		var bb: AABB = t.global_transform * t.get_aabb()
		lo[n] = Vector4(bb.position.x, bb.position.y, bb.position.z, 0.0)
		hi[n] = Vector4(bb.end.x, bb.end.y, bb.end.z, 0.0)
		n += 1
	for o in occluders:
		var m := o.material_override as ShaderMaterial
		if m == null:
			continue
		m.set_shader_parameter("box_count", n)
		m.set_shader_parameter("box_lo", lo)
		m.set_shader_parameter("box_hi", hi)
