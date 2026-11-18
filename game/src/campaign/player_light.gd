class_name CampaignPlayerLight
extends Node2D
## Bitmap light with moving scattering bands and bounded, world-space particles.
const BEAM := preload("res://art/whalebelly/soft_light/UNDERWATER-SOFT-LIGHT.png")
const HALO := preload("res://art/world-kit/fx-particle-soft.png")
const LIGHT_SHADER := preload("res://src/campaign/player_light.gdshader")
const MOTE_SHADER := preload("res://src/campaign/player_light_motes.gdshader")
const WATER_LIGHT_Z := -1 # Backgrounds < 0; the painted world terrain is at 0.
var effect_time: float = 0.0
var materials: Array[ShaderMaterial] = []
var emitters: Array[CPUParticles2D] = []
var last_origin: Vector2
var tracking: bool = false
var beam_light: Sprite2D

func _ready() -> void:
	name = "PlayerLight"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_as_relative = false
	beam_light = _add_light("Beam", BEAM, Vector2(-18,-272), 0.82, 0.42, true)
	beam_light.z_as_relative = false
	beam_light.z_index = WATER_LIGHT_Z
	_add_light("Halo", HALO, Vector2(0,-54), 0.82, 0.14, false)
	_add_particles("SuspendedMotes", 56, Vector2(0.009,0.022), 0.72, 9.0)
	_add_particles("SoftScatter", 12, Vector2(0.045,0.095), 0.08, 12.0)
	visibility_changed.connect(_sync_visibility)
	_sync_visibility()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	effect_time += delta
	for effect: ShaderMaterial in materials:
		effect.set_shader_parameter("effect_time", effect_time)

func _sync_visibility() -> void:
	for particles: CPUParticles2D in emitters:
		particles.speed_scale = 1.0 if is_visible_in_tree() else 0.0

func _add_light(id: String, bitmap: Texture2D, at: Vector2, ratio: float, strength: float, beam: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = id
	sprite.texture = bitmap
	sprite.position = at
	sprite.scale = Vector2.ONE * ratio
	var effect := ShaderMaterial.new()
	effect.shader = LIGHT_SHADER
	effect.set_shader_parameter("strength", strength)
	effect.set_shader_parameter("beam", beam)
	sprite.material = effect
	materials.append(effect)
	add_child(sprite)
	return sprite

func _add_particles(id: String, count: int, sizes: Vector2, strength: float, duration: float) -> void:
	var particles := CPUParticles2D.new()
	particles.name = id
	particles.z_as_relative = false
	particles.z_index = WATER_LIGHT_Z
	particles.texture = HALO
	particles.amount = count
	particles.lifetime = duration
	particles.preprocess = duration
	particles.use_fixed_seed = true
	particles.seed = 2741 + count
	particles.local_coords = false
	particles.position = Vector2(-12,-255)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(140,260)
	particles.gravity = Vector2.ZERO
	particles.direction = Vector2(0.3,-1.0)
	particles.spread = 65.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 11.0
	particles.scale_amount_min = sizes.x
	particles.scale_amount_max = sizes.y
	particles.draw_order = CPUParticles2D.DRAW_ORDER_LIFETIME
	var envelope := Gradient.new()
	envelope.offsets = PackedFloat32Array([0.0,0.15,0.65,1.0])
	envelope.colors = PackedColorArray([Color(0.7,0.9,1,0),Color(0.7,0.9,1,1),Color(0.6,0.85,1,0.7),Color(0.6,0.85,1,0)])
	particles.color_ramp = envelope
	var effect := ShaderMaterial.new()
	effect.shader = MOTE_SHADER
	effect.set_shader_parameter("strength", strength)
	particles.material = effect
	materials.append(effect)
	emitters.append(particles)
	add_child(particles)

func track(actor: Node2D) -> void:
	global_position = actor.global_position
	z_index = actor.z_index + 1
	for particles: CPUParticles2D in emitters:
		# Explicit loads/teleports rewarm at the destination; ordinary travel leaves
		# particles suspended in the water instead of dragging a panel of dots.
		if not tracking or last_origin.distance_to(global_position) > 800.0:
			particles.restart()
		(particles.material as ShaderMaterial).set_shader_parameter("light_origin", global_position)
	last_origin = global_position
	tracking = true
