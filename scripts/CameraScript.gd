@tool
extends Node3D

@export var target: Node3D
@export var follow_speed := 5.0
@export var fixed_y := 0.0
@export var distance: Vector2

func _process(delta):
	if target == null:
		return

	var target_pos = target.global_position

	# Keep your Y, follow X and Z
	var desired_pos = Vector3(
		target_pos.x + distance.x,
		fixed_y,
		target_pos.z + distance.y
	)

	# Smooth movement
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
