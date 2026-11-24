extends PathFollow3D
## Example only: drives the tractor round the path at a steady speed.

@export var speed := 4.0


func _process(delta: float) -> void:
	progress += speed * delta
