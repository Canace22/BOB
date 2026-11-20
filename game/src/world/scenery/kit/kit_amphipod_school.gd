class_name KitAmphipodSchool
extends Node2D
## Background-only fixed pool. No collisions, targets, progress or damage events.
## Native source faces left; body articulation and the group route are separate.
@export var texture: Texture2D
@export var bounds: Rect2 = Rect2(0, 0, 1500, 200)
@export_range(1, 96) var population: int = 28
@export var body_width: float = 34.0
@export var source_visible_width_ratio: float = 0.888671875
@export var seed_id: int = 1
@export_enum("band", "orbit") var mode: String = "band"
@export var external_clock: bool = true
@export var flow_speed: float = 26.0
@export var opacity: float = 0.34
@export var tint: Color = Color(0.92, 0.79, 0.85, 1.0)
@export var body_motion_strength: float = 1.0
@export var hidden_when_flag: String = ""
var elapsed: float = 0.0
var members: Array[Dictionary] = []
var progress_host: Node
var hidden_mix: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if texture == null: return
	var candidate: Node=get_parent()
	while candidate!=null:
		if "abilities" in candidate:
			progress_host=candidate
			break
		candidate=candidate.get_parent()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_id * 5737 + 31
	var width: float = maxf(texture.get_width() * source_visible_width_ratio, 1.0)
	var shader: Shader = load("res://src/world/scenery/kit/amphipod_swim.gdshader")
	for index: int in clampi(population, 1, 96):
		var sprite := Sprite2D.new()
		sprite.name = "Amphipod%02d" % index
		sprite.texture = texture
		var phase: float = rng.randf() * TAU
		var scale_value: float = body_width / width * rng.randf_range(0.68, 1.05)
		sprite.scale = Vector2.ONE * scale_value
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("phase", phase)
		material.set_shader_parameter("motion_strength", body_motion_strength)
		sprite.material = material
		add_child(sprite)
		members.append({"node":sprite, "material":material, "phase":phase,
			"offset":rng.randf(), "lane":rng.randf_range(0.2, 0.8),
			"pace":rng.randf_range(0.82, 1.16), "scale":scale_value,
			"orbit":rng.randf_range(0.56, 0.98)})
	update_at(0.0) # The initial pool is already dispersed; no emission burst.

func _process(delta: float) -> void:
	if not external_clock: update_at(elapsed + delta)

func update_at(time: float) -> void:
	var hidden_now: bool=not hidden_when_flag.is_empty() and is_instance_valid(progress_host) and bool(progress_host.get("abilities").get(hidden_when_flag,false))
	var target: float=1.0 if hidden_now else 0.0
	hidden_mix=target if time<=0.0 or time<elapsed else move_toward(hidden_mix,target,maxf(0.0,time-elapsed)*0.4)
	modulate.a=1.0-hidden_mix
	elapsed = maxf(0.0, time)
	for member: Dictionary in members:
		var sprite: Sprite2D = member.node
		var result: Dictionary = orbit_pose(member) if mode == "orbit" else band_pose(member)
		sprite.position = result.position
		sprite.flip_h = bool(result.rightward)
		sprite.rotation = float(result.angle)
		sprite.scale = Vector2(float(member.scale) * float(result.turn), float(member.scale))
		sprite.modulate = Color(tint.r, tint.g, tint.b, tint.a * opacity * float(result.alpha))
		# The stream fade wrapper replaces the original material on preparation.
		var material: ShaderMaterial = sprite.material
		material.set_shader_parameter("clock", elapsed)
		material.set_shader_parameter("motion_strength", body_motion_strength)

func band_pose(member: Dictionary) -> Dictionary:
	var length: float = maxf(bounds.size.x, 1.0)
	var speed: float = flow_speed * float(member.pace)
	var x: float = fposmod(float(member.offset) * length + speed * elapsed, length)
	var phase: float = float(member.phase)
	var wave: float = sin(elapsed * 0.65 + phase) * minf(bounds.size.y * 0.1, 14.0)
	var y: float = bounds.position.y + bounds.size.y * float(member.lane) + wave
	var margin: float = minf(length * 0.2, maxf(body_width * 2.5, length * 0.08))
	var alpha: float = smoothstep(0.0, margin, minf(x, length - x))
	var angle: float = cos(elapsed * 0.65 + phase) * 0.045
	return {"position":Vector2(bounds.position.x + x, y), "rightward":speed >= 0.0,
		"angle":angle, "alpha":alpha, "turn":1.0}

func orbit_pose(member: Dictionary) -> Dictionary:
	var phase: float = float(member.phase)
	var angle: float = phase + elapsed * 0.16 * float(member.pace) * signf(flow_speed)
	var radius: Vector2 = bounds.size * 0.42 * float(member.orbit)
	var position_: Vector2 = bounds.get_center() + Vector2(cos(angle), sin(angle)) * radius
	var direction: Vector2 = Vector2(-sin(angle) * radius.x, cos(angle) * radius.y) * signf(flow_speed)
	var side: float = absf(direction.x) / maxf(direction.length(), 1.0)
	var rightward: bool = direction.x >= 0.0
	var tilt: float = atan2(direction.y, absf(direction.x))
	if not rightward: tilt = -tilt
	return {"position":position_, "rightward":rightward,
		"angle":clampf(tilt, -0.35, 0.35), "alpha":lerpf(0.25, 1.0, side),
		"turn":lerpf(0.35, 1.0, side)}

func snapshot() -> Dictionary:
	return {"population":members.size(), "elapsed":elapsed, "bounds":bounds,
		"mode":mode, "external_clock":external_clock, "harmful":false}
