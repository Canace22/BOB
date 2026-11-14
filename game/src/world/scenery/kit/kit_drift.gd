class_name KitDriftField
extends Node2D
## Bounded pool of one library bitmap drifting with wrap-around: fat motes,
## current streaks. Deterministic per seed; pauses with its room.
@export var texture: Texture2D
@export var bounds: Rect2 = Rect2(0, 0, 400, 300)
@export var population: int = 24
@export var velocity: Vector2 = Vector2(6, 10)
@export var sway: float = 8.0
@export var size_range: Vector2 = Vector2(6, 16) # longest side in pixels
@export_range(0.0, 1.0) var opacity: float = 0.4
@export var tint: Color = Color.WHITE
@export var turn_degrees: float = 0.0
@export var seed_id: int = 1
@export var progress_flag: String = ""
@export var unlocked_velocity: Vector2 = Vector2.ZERO
@export_range(0.0, 1.0) var unlocked_opacity: float = 0.2
@export_range(0.0, 5.0) var transition_seconds: float = 0.8
var time: float = 0.0
var motes: Array[Dictionary] = []
var progress_mix: float = 0.0
var drift_offset: Vector2 = Vector2.ZERO
var progress_host: Node

func _ready() -> void:
	progress_mix = 1.0 if progress_unlocked() else 0.0
	var random := RandomNumberGenerator.new()
	random.seed = seed_id * 7919 + 13
	for i: int in population:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * random.randf_range(size_range.x, size_range.y) / maxf(float(texture.get_width()), 1.0)
		sprite.rotation_degrees = turn_degrees
		add_child(sprite)
		motes.append({"node":sprite, "origin":Vector2(random.randf() * bounds.size.x, random.randf() * bounds.size.y), "speed":random.randf_range(0.6, 1.4), "phase":random.randf() * TAU, "alpha":random.randf_range(0.5, 1.0)})
	update_at(0.0)

func _process(delta: float) -> void:
	update_at(time + delta)

func update_at(t: float) -> void:
	var next_time: float = maxf(t, 0.0)
	var delta: float = next_time - time
	var target: float = 1.0 if progress_unlocked() else 0.0
	if delta < 0.0:
		# Explicit seek/reload has no transition history; use the saved state.
		progress_mix = target
		drift_offset = velocity.lerp(unlocked_velocity, progress_mix) * next_time
	elif transition_seconds <= 0.0:
		progress_mix = target
		drift_offset += velocity.lerp(unlocked_velocity, progress_mix) * delta
	else:
		# Integrate the blend, not velocity * total time: changing progress must
		# never teleport an existing particle or depend on the render frame rate.
		var rate: float = 3.0 / transition_seconds
		var decay: float = exp(-rate * delta)
		var integral: float = target * delta + (progress_mix - target) * (1.0 - decay) / rate
		drift_offset += velocity * delta + (unlocked_velocity - velocity) * integral
		progress_mix = target + (progress_mix - target) * decay
	time = next_time
	var current_opacity: float = lerpf(opacity, unlocked_opacity, progress_mix)
	for mote: Dictionary in motes:
		var travelled: Vector2 = mote.origin + drift_offset * float(mote.speed)
		var local := Vector2(fposmod(travelled.x, bounds.size.x) + sin(time * 0.5 + float(mote.phase)) * sway, fposmod(travelled.y, bounds.size.y))
		# Fade at the field edge so wrap-around never pops.
		var edge: float = minf(minf(local.x, bounds.size.x - local.x), minf(local.y, bounds.size.y - local.y))
		mote.node.position = bounds.position + local
		mote.node.modulate = Color(tint, smoothstep(0.0, 40.0, edge) * current_opacity * float(mote.alpha))

func progress_unlocked() -> bool:
	if progress_flag.is_empty(): return false
	if not is_instance_valid(progress_host):
		var candidate: Node = get_parent()
		while candidate != null:
			if "abilities" in candidate:
				progress_host = candidate
				break
			candidate = candidate.get_parent()
	if not is_instance_valid(progress_host): return false
	# Practice unlocks are transient; only actual saved progress changes water.
	var flags: Variant = progress_host.get("abilities")
	return flags is Dictionary and bool(flags.get(progress_flag, false))
