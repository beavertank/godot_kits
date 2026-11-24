class_name TrailerChain
extends Node
## Trailers that follow a truck the way real ones do: dragged, not steered. Move the tractor
## however you like (a PathFollow3D, a CharacterBody3D, your own code); each frame every
## trailer turns to point from its rear axle at its hitch and keeps its axle at a fixed length
## behind it. On a turn the trailers cut inside the tractor's path (the curve is a
## "tractrix"), and straighten out after. No physics, fully deterministic.
##
## Conventions: forward is -Z (Godot's). Each trailer node's origin is its kingpin (where it
## hitches on); its rear axle is `axle_length` behind that, and the next trailer hitches on
## `hitch_back` behind its kingpin.
##
## Wheels: `rolled[i]` is how far part i has rolled (0 = the tractor, 1.. = each trailer), so
## a wheel of radius r turns by rolled[i] / r radians. A trailer's wheels roll less on the
## inside of a turn, the same as the real thing.

@export var tractor: Node3D
@export var hitch_offset := Vector3(0, 0, 0.5)   ## the tractor's hitch, in its local space
@export var trailers: Array[Node3D] = []
@export var axle_length := 2.9                   ## kingpin to rear axle
@export var hitch_back := 3.9                    ## kingpin to the next trailer's kingpin

var rolled := PackedFloat32Array()
var axles: Array[Vector3] = []                   # each trailer's rear axle (world)
var _last_tractor := Vector3.ZERO


func _ready() -> void:
	# start straight out behind the tractor
	var back := tractor.global_transform.basis.z.normalized()
	var hitch: Vector3 = tractor.to_global(hitch_offset)
	for t in trailers:
		axles.append(hitch + back * axle_length)
		hitch += back * hitch_back
	rolled.resize(trailers.size() + 1)
	process_priority = 100
	_last_tractor = tractor.global_position
	_place(false)


func _process(_delta: float) -> void:
	_place(true)                  # (process_priority 100: after the tractor has moved)


func _place(count_roll: bool) -> void:
	if count_roll:
		var fwd := -tractor.global_transform.basis.z
		rolled[0] += (tractor.global_position - _last_tractor).dot(fwd)
	_last_tractor = tractor.global_position
	var hitch: Vector3 = tractor.to_global(hitch_offset)
	for i in trailers.size():
		var to_hitch: Vector3 = hitch - axles[i]
		to_hitch.y = 0.0
		var dir := to_hitch.normalized() if to_hitch.length() > 0.001 else -trailers[i].global_transform.basis.z
		var was: Vector3 = axles[i]
		axles[i] = hitch - dir * axle_length                     # the axle, dragged along
		if count_roll:
			rolled[i + 1] += (axles[i] - was).dot(dir)
		trailers[i].global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), hitch)
		hitch -= dir * hitch_back                                # the next one hitches on here
