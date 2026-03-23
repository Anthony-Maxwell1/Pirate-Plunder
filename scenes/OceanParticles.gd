## OceanVFX.gd
## Attach to any Node3D in your scene — no parent GPUParticles3D needed.
## Creates and manages its own particle systems as children.
## Keep shader uniforms in sync with your ShaderMaterial.
extends Node3D

# ── Ocean shader uniforms ─────────────────────────────────────────────────────
@export_group("Ocean Shader Uniforms")
@export var min_height: float = -3.0
@export var max_height: float =  3.0
@export var height_weight: float = 1.0
@export var time_scale: float = 0.5
@export var choppiness: float = 0.5

# ── Spawn area ────────────────────────────────────────────────────────────────
@export_group("Spawn Area")
## World-space half-extent to randomly place effects within.
@export var area_radius: float = 40.0
## Centre offset from this node's position (useful if your ocean is offset).
@export var area_center: Vector3 = Vector3.ZERO

# ── Timing randomisation ──────────────────────────────────────────────────────
@export_group("Timing")
@export var splash_interval_min: float = 0.4
@export var splash_interval_max: float = 1.8
@export var foam_interval_min:   float = 0.6
@export var foam_interval_max:   float = 2.4
@export var mist_interval_min:   float = 1.0
@export var mist_interval_max:   float = 3.5

# ── Pool sizes ────────────────────────────────────────────────────────────────
@export_group("Pool Sizes")
@export var splash_pool_size: int = 6
@export var foam_pool_size:   int = 5
@export var mist_pool_size:   int = 4

# ── Runtime ───────────────────────────────────────────────────────────────────
var _time: float = 0.0
var _splash_pool: Array[GPUParticles3D] = []
var _foam_pool:   Array[GPUParticles3D] = []
var _mist_pool:   Array[GPUParticles3D] = []

var _splash_timer: float = 0.0
var _foam_timer:   float = 0.0
var _mist_timer:   float = 0.0

var _splash_next: float = 0.0
var _foam_next:   float = 0.0
var _mist_next:   float = 0.0


# ════════════════════════════════════════════════════════════════════════════
# Wave maths
# ════════════════════════════════════════════════════════════════════════════

func _dwave(p: Vector2, freq: float, speed: float, amp: float, dir: Vector2) -> float:
	var t: float = _time * speed * time_scale
	return sin(p.dot(dir) * freq + t) * amp


func ocean_height(p: Vector2) -> float:
	var w0: float = _dwave(p, 0.11, 1.0,  1.0,  Vector2( 0.72,  0.69))
	var w1: float = _dwave(p, 0.19, 1.4,  0.7,  Vector2(-0.55,  0.83))
	var w2: float = _dwave(p, 0.28, 0.8,  0.5,  Vector2( 0.88, -0.47))
	var w3: float = _dwave(p, 0.38, 1.9,  0.35, Vector2(-0.38, -0.92))
	var warped: Vector2 = p + Vector2(w0 + w1, w2 + w3) * choppiness
	var w4: float = _dwave(warped, 0.14, 1.2,  0.9,  Vector2( 0.60, -0.80))
	var w5: float = _dwave(warped, 0.23, 0.7,  0.6,  Vector2(-0.82,  0.57))
	var w6: float = _dwave(warped, 0.42, 2.1,  0.3,  Vector2( 0.45,  0.89))
	var warped2: Vector2 = warped + Vector2(w4, w5) * choppiness * 0.6
	var w7: float = _dwave(warped2, 0.18, 1.6, 0.55, Vector2(-0.66, -0.75))
	var w8: float = _dwave(warped2, 0.33, 0.9, 0.35, Vector2( 0.91,  0.41))
	var raw: float = (w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8) * 0.28
	var mid: float       = (min_height + max_height) * 0.5
	var half_range: float = (max_height - min_height) * 0.5
	return -(mid + raw * half_range * height_weight)


func _random_ocean_pos() -> Vector3:
	var angle: float  = randf() * TAU
	var radius: float = randf() * area_radius
	var xz: Vector2   = Vector2(cos(angle), sin(angle)) * radius
	var base: Vector3 = global_position + area_center
	return Vector3(base.x + xz.x, ocean_height(xz + Vector2(base.x, base.z)), base.z + xz.y)


# ════════════════════════════════════════════════════════════════════════════
# Particle material builders
# ════════════════════════════════════════════════════════════════════════════

func _make_splash_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.direction          = Vector3(0, 1, 0)
	m.spread             = 40.0
	m.initial_velocity_min = 2.5
	m.initial_velocity_max = 6.0
	m.gravity            = Vector3(0, -9.8, 0)
	m.scale_min          = 0.04
	m.scale_max          = 0.14
	m.lifetime_randomness = 0.4

	# White-blue water droplet colour, fades out
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.95, 1.0, 1.0))
	grad.set_color(1, Color(0.7,  0.88, 1.0, 0.0))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	m.color_ramp = gtex

	m.turbulence_enabled      = true
	m.turbulence_noise_strength = 0.6
	m.turbulence_noise_scale    = 2.5
	return m


func _make_foam_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.direction          = Vector3(0, 1, 0)
	m.spread             = 80.0
	m.initial_velocity_min = 0.3
	m.initial_velocity_max = 1.2
	m.gravity            = Vector3(0, -1.5, 0)  # foam floats
	m.scale_min          = 0.12
	m.scale_max          = 0.35
	m.lifetime_randomness = 0.6

	var grad := Gradient.new()
	grad.set_color(0, Color(0.95, 0.97, 1.0, 0.9))
	grad.set_color(1, Color(0.88, 0.93, 1.0, 0.0))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	m.color_ramp = gtex

	m.turbulence_enabled        = true
	m.turbulence_noise_strength = 0.9
	m.turbulence_noise_scale    = 1.2
	return m


func _make_mist_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.direction          = Vector3(0, 1, 0)
	m.spread             = 90.0
	m.initial_velocity_min = 0.1
	m.initial_velocity_max = 0.6
	m.gravity            = Vector3(0, 0.05, 0)  # drifts upward slowly
	m.scale_min          = 0.5
	m.scale_max          = 1.8
	m.lifetime_randomness = 0.5

	var grad := Gradient.new()
	grad.set_color(0, Color(0.75, 0.88, 0.95, 0.0))
	grad.set_color(1, Color(0.80, 0.90, 0.98, 0.25))
	# mist fades in then out — add midpoint
	grad.add_point(0.3, Color(0.78, 0.89, 0.96, 0.18))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	m.color_ramp = gtex

	m.turbulence_enabled        = true
	m.turbulence_noise_strength = 1.4
	m.turbulence_noise_scale    = 0.6
	return m


# ════════════════════════════════════════════════════════════════════════════
# Pool management
# ════════════════════════════════════════════════════════════════════════════

func _build_particles(material: ParticleProcessMaterial,
		lifetime: float, amount: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.process_material  = material
	p.lifetime          = lifetime
	p.amount            = amount
	p.one_shot          = true
	p.explosiveness     = 0.85   # burst-style
	p.emitting          = false
	p.draw_pass_1       = SphereMesh.new()   # default sphere stand-in; swap for your atlas
	add_child(p)
	return p


func _build_pools() -> void:
	var splash_mat := _make_splash_material()
	for _i in splash_pool_size:
		_splash_pool.append(_build_particles(splash_mat, 1.4, 28))

	var foam_mat := _make_foam_material()
	for _i in foam_pool_size:
		_foam_pool.append(_build_particles(foam_mat, 2.2, 22))

	var mist_mat := _make_mist_material()
	for _i in mist_pool_size:
		_mist_pool.append(_build_particles(mist_mat, 3.5, 16))


## Grab the first non-emitting particle system from a pool (simple round-robin).
func _get_free(pool: Array[GPUParticles3D]) -> GPUParticles3D:
	for p in pool:
		if not p.emitting:
			return p
	# All busy — reuse oldest (first in list) by forcing it.
	return pool[0]


func _fire(pool: Array[GPUParticles3D], pos: Vector3) -> void:
	var p: GPUParticles3D = _get_free(pool)
	p.global_position = pos
	p.restart()
	p.emitting = true


# ════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_pools()
	# Stagger initial timers so effects don't all fire at once on load.
	_splash_next = randf_range(splash_interval_min, splash_interval_max)
	_foam_next   = randf_range(foam_interval_min,   foam_interval_max)
	_mist_next   = randf_range(mist_interval_min,   mist_interval_max)


func _process(delta: float) -> void:
	_time         += delta
	_splash_timer += delta
	_foam_timer   += delta
	_mist_timer   += delta

	if _splash_timer >= _splash_next:
		_splash_timer = 0.0
		_splash_next  = randf_range(splash_interval_min, splash_interval_max)
		_fire(_splash_pool, _random_ocean_pos())

	if _foam_timer >= _foam_next:
		_foam_timer = 0.0
		_foam_next  = randf_range(foam_interval_min, foam_interval_max)
		# Foam often appears in small clusters.
		var base: Vector3 = _random_ocean_pos()
		_fire(_foam_pool, base)
		if randf() > 0.5:
			_fire(_foam_pool, base + Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8)))

	if _mist_timer >= _mist_next:
		_mist_timer = 0.0
		_mist_next  = randf_range(mist_interval_min, mist_interval_max)
		_fire(_mist_pool, _random_ocean_pos())
