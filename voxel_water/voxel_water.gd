class_name VoxelWater
extends MeshInstance3D
## Stepped voxel water (voxel_water.gdshader). Builds a grid of cells centred on this node and
## drives its wind. For a big sea, keep the patch small and move it with the camera in whole
## cells (see follow()), so the pattern, which lives in world space, never slides.

@export var cells_x := 96
@export var cells_z := 64
@export var cell_size := 1.0
@export_range(0.0, 1.0) var wind := 0.4            ## 0 calm .. 1 strong
@export var wind_direction := Vector2(1.0, 0.3)
@export var material: ShaderMaterial                ## (default: a new one with the shader)

var _wave_t := 0.0
var _drift := Vector2.ZERO


func _ready() -> void:
	if material == null:
		material = ShaderMaterial.new()
		material.shader = preload("voxel_water.gdshader")
	mesh = build_mesh(cells_x, cells_z, cell_size)
	mesh.surface_set_material(0, material)


func _process(delta: float) -> void:
	_wave_t += delta * (0.28 + 0.42 * wind)
	_drift += wind_direction.normalized() * (0.3 + 1.5 * wind) * delta
	material.set_shader_parameter("wave_t", _wave_t)
	material.set_shader_parameter("drift", _drift)
	material.set_shader_parameter("wind", wind)


## Keep the patch under a point (the camera's focus), moving only in whole cells.
func follow(point: Vector3) -> void:
	global_position.x = snappedf(point.x, cell_size)
	global_position.z = snappedf(point.z, cell_size)


## Each cell: a top quad plus its +X and +Z side faces (enough for a camera looking from that
## side; add the other two for one that can go all the way round). Every vertex of a cell
## carries the cell's centre in UV, and in UV2 whether it moves with the wave and whether it's
## a side face.
static func build_mesh(nx: int, nz: int, s: float, drop := 1.0) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var idx := PackedInt32Array()
	var ox := -nx * s * 0.5
	var oz := -nz * s * 0.5
	for iz in nz:
		for ix in nx:
			var x0 := ox + ix * s
			var z0 := oz + iz * s
			var c := Vector2(x0 + s * 0.5, z0 + s * 0.5)
			var faces := [
				[[Vector3(x0, 0, z0), Vector3(x0 + s, 0, z0), Vector3(x0 + s, 0, z0 + s), Vector3(x0, 0, z0 + s)],
					[1, 1, 1, 1], Vector3.UP, 0.0],
				[[Vector3(x0 + s, 0, z0), Vector3(x0 + s, -drop, z0), Vector3(x0 + s, -drop, z0 + s), Vector3(x0 + s, 0, z0 + s)],
					[1, 0, 0, 1], Vector3.RIGHT, 1.0],
				[[Vector3(x0, 0, z0 + s), Vector3(x0 + s, 0, z0 + s), Vector3(x0 + s, -drop, z0 + s), Vector3(x0, -drop, z0 + s)],
					[1, 1, 0, 0], Vector3.BACK, 1.0],
			]
			for f in faces:
				var base := verts.size()
				for k in 4:
					verts.append(f[0][k])
					norms.append(f[2])
					uvs.append(c)
					uv2s.append(Vector2(f[1][k], f[3]))
				idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# the vertex shader moves cells up and down: give the culling box room for it
	m.custom_aabb = AABB(Vector3(ox, -drop - 1.0, oz), Vector3(nx * s, drop + 2.0, nz * s))
	return m
