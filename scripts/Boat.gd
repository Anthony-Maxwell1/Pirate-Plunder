@tool
extends Node3D

## Attach this to a MeshInstance3D (or any Node3D) that should float on the ocean.
## The wave math mirrors the ShaderMaterial exactly.

# ── Ocean shader uniforms (keep in sync with your ShaderMaterial) ────────────
@export_group("Ocean Shader Uniforms (Should match Shader)")
@export var min_height: float = -3.0
@export var max_height: float =  3.0
@export var height_weight: float = 1.0
@export var time_scale: float = 0.5
@export var choppiness: float = 0.5

# ── Buoyancy feel ────────────────────────────────────────────────────────────
@export_group("Buoyancy")
@export var height_spring: float = 8.0
@export var height_damping: float = 3.5
## Vertical offset so the boat sits *on* the surface rather than centred on it.
@export var draft: float = 0.0

# ── Rotation wobble ──────────────────────────────────────────────────────────
@export_group("Wobble")
@export var probe_radius: float = 1.2
@export var tilt_spring: float = 5.0
@export var tilt_damping: float = 2.5
@export var max_tilt_deg: float = 22.0

# ── Wave-push drift ──────────────────────────────────────────────────────────
@export_group("Drift")
## Scales the orbital velocity transferred to the boat. 1.0 = fully carried by wave.
@export var orbital_strength: float = 0.6
## Drag – bleeds off velocity between pushes (higher = stops faster).
@export var drift_drag: float = 1.8
## Seconds between orbital velocity samples (smaller = more responsive, more CPU).
@export var orbital_dt: float = 0.05

@export_group("Movement")
@export var move_speed := 48.0
@export var turn_speed := 2.5
@export var accel := 4.0
@export var drag := 2.0

var _input_vel: Vector3 = Vector3.ZERO

# ── Runtime state ────────────────────────────────────────────────────────────
var _vel_y: float = 0.0
var _ang_vel: Vector2 = Vector2.ZERO
var _drift_vel: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _prev_warp: Vector2 = Vector2.ZERO
var _orbital_accum: float = 0.0


# ════════════════════════════════════════════════════════════════════════════
# Wave maths — exact mirror of the GLSL
# ════════════════════════════════════════════════════════════════════════════

func _dwave(p: Vector2, freq: float, speed: float, amp: float, dir: Vector2) -> float:
	var t: float = _time * speed * time_scale
	return sin(p.dot(dir) * freq + t) * amp


func ocean_height(p: Vector2) -> float:
	var w0 := _dwave(p, 0.11, 1.0,  1.0,  Vector2( 0.72,  0.69))
	var w1 := _dwave(p, 0.19, 1.4,  0.7,  Vector2(-0.55,  0.83))
	var w2 := _dwave(p, 0.28, 0.8,  0.5,  Vector2( 0.88, -0.47))
	var w3 := _dwave(p, 0.38, 1.9,  0.35, Vector2(-0.38, -0.92))

	var warped := p + Vector2(w0 + w1, w2 + w3) * choppiness

	var w4 := _dwave(warped, 0.14, 1.2,  0.9,  Vector2( 0.60, -0.80))
	var w5 := _dwave(warped, 0.23, 0.7,  0.6,  Vector2(-0.82,  0.57))
	var w6 := _dwave(warped, 0.42, 2.1,  0.3,  Vector2( 0.45,  0.89))

	var warped2 := warped + Vector2(w4, w5) * choppiness * 0.6

	var w7 := _dwave(warped2, 0.18, 1.6, 0.55, Vector2(-0.66, -0.75))
	var w8 := _dwave(warped2, 0.33, 0.9, 0.35, Vector2( 0.91,  0.41))

	var raw := (w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8) * 0.28
	var mid := (min_height + max_height) * 0.5
	var half_range := (max_height - min_height) * 0.5
	return -(mid + raw * half_range * height_weight)


## Returns the dominant XZ warp displacement that the shader applies at p.
## Tracking how this changes over time gives us the horizontal orbital velocity
## of the wave surface — the actual force that pushes floating objects along.
func _warp_displacement(p: Vector2) -> Vector2:
	var w0 := _dwave(p, 0.11, 1.0,  1.0,  Vector2( 0.72,  0.69))
	var w1 := _dwave(p, 0.19, 1.4,  0.7,  Vector2(-0.55,  0.83))
	var w2 := _dwave(p, 0.28, 0.8,  0.5,  Vector2( 0.88, -0.47))
	var w3 := _dwave(p, 0.38, 1.9,  0.35, Vector2(-0.38, -0.92))
	# First warp layer only — dominant horizontal motion.
	# Deeper layers are already baked into warped/warped2 and would double-count.
	return Vector2(w0 + w1, w2 + w3) * choppiness


func _surface_normal(p: Vector2) -> Vector3:
	var eps := probe_radius
	var hc  := ocean_height(p)
	var hx  := ocean_height(p + Vector2(eps, 0.0))
	var hz  := ocean_height(p + Vector2(0.0, eps))
	var tx  := Vector3(eps, hx - hc, 0.0).normalized()
	var tz  := Vector3(0.0, hz - hc, eps).normalized()
	return tz.cross(tx).normalized()


# ════════════════════════════════════════════════════════════════════════════
# _physics_process
# ════════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	_time += delta

	var xz := Vector2(global_position.x, global_position.z)
	var target_y := ocean_height(xz) + draft

	# ── Vertical spring-damper ────────────────────────────────────────────
	var err_y := target_y - global_position.y
	_vel_y += (err_y * height_spring - _vel_y * height_damping) * delta
	global_position.y += _vel_y * delta

	# ── Angular wobble ────────────────────────────────────────────────────
	var surf_n: Vector3 = _surface_normal(xz)

	var target_pitch: float = clamp(
		atan2(-surf_n.z, surf_n.y),
		deg_to_rad(-max_tilt_deg), deg_to_rad(max_tilt_deg))
	var target_roll: float = clamp(
		atan2(surf_n.x, surf_n.y),
		deg_to_rad(-max_tilt_deg), deg_to_rad(max_tilt_deg))

	var cur_rot: Vector3 = rotation
	var err_pitch: float = target_pitch - cur_rot.x
	var err_roll: float  = target_roll  - cur_rot.z

	_ang_vel.x += (err_pitch * tilt_spring - _ang_vel.x * tilt_damping) * delta
	_ang_vel.y += (err_roll  * tilt_spring - _ang_vel.y * tilt_damping) * delta

	rotation.x += _ang_vel.x * delta
	rotation.z += _ang_vel.y * delta

	# ── Orbital velocity drift ────────────────────────────────────────────
	# Instead of using the height gradient (which pushes perpendicular to
	# contours but has no sense of wave direction), we finite-difference the
	# warp displacement over time. This gives us the actual horizontal velocity
	# of the wave surface at this point — naturally pushing the boat down
	# crests in the wave's travel direction, exactly like a real buoy.
	_orbital_accum += delta
	if _orbital_accum >= orbital_dt:
		var cur_warp := _warp_displacement(xz)
		var warp_vel := (cur_warp - _prev_warp) / _orbital_accum  # XZ units/sec
		_prev_warp     = cur_warp
		_orbital_accum = 0.0

		# Blend toward the wave's surface velocity at this point.
		var orbital_target := Vector3(warp_vel.x, 0.0, warp_vel.y) * orbital_strength
		# Use a fast lerp so we track the wave rather than lag behind it.
		_drift_vel = _drift_vel.lerp(orbital_target, 0.35)

	# Drag bleeds off momentum when the wave isn't pushing hard.
	_drift_vel -= _drift_vel * drift_drag * delta
	var total_vel = _drift_vel + _input_vel

	global_position.x += total_vel.x * delta
	global_position.z += total_vel.z * delta
	
	var input_dir := 0.0
	if Input.is_action_pressed("ui_up"):
		input_dir += 1.0
	if Input.is_action_pressed("ui_down"):
		input_dir -= 1.0

	var turn_dir := 0.0
	if Input.is_action_pressed("ui_left"):
		turn_dir += 1.0
	if Input.is_action_pressed("ui_right"):
		turn_dir -= 1.0
	
	rotation.y += turn_dir * turn_speed * delta
	
	var forward := -transform.basis.z
	var target_vel := forward * input_dir * move_speed
	
	_input_vel = _input_vel.lerp(target_vel, accel * delta)
	
	_input_vel -= _input_vel * drag * delta
	
	


func _ready() -> void:
	var xz := Vector2(global_position.x, global_position.z)
	global_position.y = ocean_height(xz) + draft
	_prev_warp = _warp_displacement(xz)
