class_name PlayerVisual
extends Sprite2D
## Playback follows gameplay time/displacement. Legacy mirrored poses are a fault fallback only.

const METADATA := "res://art/player/animation-v2/animations.json"
const LEGACY_PIVOT := Vector2(192, 270)
const LEGACY_SCALE := 0.28

var animations := PlayerAnimationData.new()
var legacy_frames: Dictionary = {}
var effects: Dictionary = {}
var clip_name: String = "idle"
var direction: String = "right"
var frame_index: int = 0
var using_directional: bool = false
var phase_elapsed: float = 0
var run_distance: float = 0
var _previous_position := Vector2.ZERO
var _previous_grounded: bool = false
var _initialized: bool = false
var _landing_remaining: float = 0
var _file: String = ""
@onready var player: Player = get_parent() as Player
@onready var effect: Sprite2D = $Effect


func _ready() -> void:
	animations.load_file(METADATA)
	for issue: String in animations.issues:
		push_warning(issue)
	for state: String in ["idle", "run", "jump", "attack", "heavy", "hit", "dash", "heal"]:
		var images: Array[Texture2D] = []
		for index in 8:
			var path := "res://art/player/%s_%d.png" % [state, index]
			if ResourceLoader.exists(path):
				images.append(load(path) as Texture2D)
		legacy_frames[state] = images
	for kind: String in ["dash_trail", "heavy_ring", "short_swipe"]:
		effects[kind] = load("res://art/fx/%s.png" % kind) as Texture2D
	reset_playback()


func reset_playback() -> void:
	clip_name = "idle"
	phase_elapsed = 0
	run_distance = 0
	_landing_remaining = 0
	_initialized = false


func _physics_process(delta: float) -> void:
	direction = "left" if player.facing < 0 else "right"
	var grounded := player.is_on_floor() or not player.is_physics_processing()
	var displacement := player.global_position - _previous_position
	if not _initialized or displacement.length() > 64:
		displacement = Vector2.ZERO
		_previous_grounded = grounded
		_initialized = true
		_landing_remaining = 0
		phase_elapsed = 0
		run_distance = 0
	_landing_remaining = maxf(0, _landing_remaining - delta)
	if grounded and not _previous_grounded and player.actions.is_free():
		_landing_remaining = float(animations.clip(direction, "land").get("duration", 0))
	if not grounded or not player.actions.is_free() or _traveling(absf(displacement.x)):
		_landing_remaining = 0
	var next := _select_clip(grounded, absf(displacement.x))
	phase_elapsed = phase_elapsed + delta if next == clip_name else 0.0
	clip_name = next
	run_distance = run_distance + displacement.x * player.facing if next == "run" else 0.0
	_previous_position = player.global_position
	_previous_grounded = grounded
	_present()


func _select_clip(grounded: bool, traveled: float) -> String:
	var action := player.actions
	if player.dead:
		return "hurt"
	if not player.is_physics_processing():
		return "idle"
	if action.mode == "attack":
		if grounded and action.elapsed >= action.attack_active_end() and _traveling(traveled):
			return "run"
		return "heavy" if action.attack_kind == "heavy" else ("attack2" if action.attack_kind == "short2" else "attack")
	if action.mode in ["hurt", "dash", "heal"]:
		return action.mode
	if not grounded:
		return "jump_rise" if player.velocity.y < -10 else "jump_fall"
	if _landing_remaining > 0:
		return "land"
	return "run" if _traveling(traveled) else "idle"


func _traveling(distance: float) -> bool:
	return distance > 0.05 and absf(player.velocity.x) > 20


func _present() -> void:
	var animation := animations.clip(direction, clip_name)
	using_directional = not animation.is_empty()
	centered = false
	position = Vector2.ZERO
	if using_directional:
		frame_index = PlayerAnimationData.frame_at(animation, _clip_time(animation))
		texture = animation.textures[frame_index] as Texture2D
		_file = animation.files[frame_index]
		offset = -animations.pivot
		scale = Vector2.ONE * animations.display_scale
		flip_h = false
	else:
		_present_legacy()
	# Spawn/retry protection is not damage feedback. A real hurt action lasts 0.18s.
	var showing_hurt := player.is_physics_processing() and not player.dead and player.actions.mode == "hurt"
	modulate.a = 0.45 if showing_hurt and sin(player.actions.elapsed * 35) > 0 else 1.0
	_present_effect()


func _clip_time(animation: Dictionary) -> float:
	var action := player.actions
	if player.dead:
		return float(animation.duration)
	if clip_name == "run":
		return fposmod(run_distance / float(animation.stride), 1.0) * float(animation.duration)
	if clip_name in PlayerAnimationData.ATTACKS:
		return PlayerAnimationData.attack_time(animation, action.elapsed, action.attack_active_start(), action.attack_active_end(), action.attack_duration())
	if clip_name in ["hurt", "dash", "heal"]:
		var duration := 0.18 if clip_name == "hurt" else (player.tuning.dash_duration if clip_name == "dash" else player.tuning.heal_duration)
		return action.elapsed / duration * float(animation.duration)
	return phase_elapsed


func _present_legacy() -> void:
	var name := clip_name
	if name.begins_with("jump_"):
		name = "jump"
	elif name == "land":
		name = "idle"
	elif name == "hurt":
		name = "hit"
	elif name == "attack2":
		name = "attack"
	var images: Array = legacy_frames.get(name, [])
	frame_index = 0
	if name == "run" and not images.is_empty():
		frame_index = int(fposmod(run_distance / 80.0, 1.0) * images.size())
	elif name in ["attack", "heavy"]:
		frame_index = 0 if player.actions.elapsed < player.actions.attack_active_start() else (1 if player.actions.elapsed < player.actions.attack_active_end() else 2)
	if not images.is_empty():
		frame_index = mini(frame_index, images.size() - 1)
		texture = images[frame_index] as Texture2D
		_file = texture.resource_path
	offset = -LEGACY_PIVOT
	scale = Vector2.ONE * LEGACY_SCALE
	flip_h = player.facing < 0


func _present_effect() -> void:
	var action := player.actions
	effect.visible = player.is_physics_processing() and (player.hitbox.active or action.mode == "dash")
	if player.tuning.prototype_controls and action.mode != "dash":
		effect.visible = false
	if not effect.visible:
		return
	var kind := "dash_trail" if action.mode == "dash" else ("heavy_ring" if action.attack_kind == "heavy" else "short_swipe")
	effect.texture = effects[kind] as Texture2D
	var width := 200.0 if kind == "heavy_ring" else 120.0
	effect.scale = Vector2.ONE * width / effect.texture.get_width() / scale.x
	effect.position = Vector2(player.facing * (-22.4 if kind == "dash_trail" else 33.6), -35.28) / scale.x
	effect.flip_h = player.facing < 0


func animation_snapshot() -> Dictionary:
	var anchor := animations.pivot if using_directional else LEGACY_PIVOT
	var animation := animations.clip(direction, clip_name)
	return {"direction": direction, "clip": clip_name, "frame": frame_index, "file": _file,
		"opacity": modulate.a,
		"using_directional": using_directional, "pivot": [anchor.x, anchor.y],
		"frame_count": animation.get("files", []).size(), "stride_pixels": animation.get("stride", 0),
		"effects": (player.get_node("CombatEffects") as PlayerEffects).snapshot(),
		"phase": phase_elapsed, "run_distance": run_distance}
