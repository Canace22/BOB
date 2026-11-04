class_name StorySpriteAnimator
extends Sprite2D
## Authored 4x4 sprite sheets; movement and game-state timing remain with the actor.

signal action_finished(action: StringName)

var animation_paused: bool = false
var playback_speed: float = 1.0
var current_action: StringName = &""
var elapsed: float = 0.0
var action_map: Dictionary = {}
var finished: bool = false


func configure(atlas: Texture2D, actions: Dictionary, display_height: float,
		source_body_height: float, root_pixels: Vector2) -> void:
	texture = atlas
	hframes = 4
	vframes = 4
	centered = true
	if atlas == null or source_body_height <= 0.0:
		visible = false
		push_error("Story sprite requires a valid atlas and measured source height.")
		return
	offset = atlas.get_size() / Vector2(8.0, 8.0) - root_pixels
	scale = Vector2.ONE * display_height / source_body_height
	action_map = actions.duplicate(true)
	current_action = &""
	visible = true
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if not action_map.is_empty():
		set_action(StringName(action_map.keys()[0]))


func set_action(action: StringName, restart: bool = false) -> void:
	if not action_map.has(action) or (current_action == action and not restart):
		return
	current_action = action
	elapsed = 0.0
	finished = false
	_update_frame()


func set_facing(direction: float) -> void:
	if not is_zero_approx(direction):
		flip_h = direction < 0.0


func _process(delta: float) -> void:
	if animation_paused or playback_speed <= 0.0 or finished or texture == null:
		return
	if not action_map.has(current_action):
		return
	elapsed += maxf(0.0, delta) * playback_speed
	_update_frame()


func _update_frame() -> void:
	var spec: Dictionary = action_map.get(current_action, {})
	var frames: Array = spec.get("frames", [])
	if frames.is_empty():
		return
	var fps: float = maxf(0.01, float(spec.get("fps", 6.0)))
	var index: int = floori(elapsed * fps)
	if bool(spec.get("loop", true)):
		index %= frames.size()
	else:
		index = mini(index, frames.size() - 1)
	frame = clampi(int(frames[index]), 0, hframes * vframes - 1)
	if not bool(spec.get("loop", true)) and elapsed >= float(frames.size()) / fps:
		finished = true
		action_finished.emit(current_action)
