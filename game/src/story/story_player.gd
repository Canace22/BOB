class_name StoryPlayer
extends TidePlayer
## Reuse the real player and atlas bridge without the old room-index/save host.

var action_visual: TideActionVisual

func _ready() -> void:
	preload_actions = false
	atlas_visual_enabled = true
	world_bounds = Rect2(0, 0, 3200, 1000)
	super._ready()
	floor_snap_length = 24.0
	floor_max_angle = deg_to_rad(55.0)
	for ray: RayCast2D in [$Foot0, $"Foot-10", $Foot10]:
		ray.target_position.y = 30.0
	action_visual = TideActionVisual.new()
	add_child(action_visual)
	action_visual.setup(self, 94.0)

func _physics_process(delta: float) -> void:
	var previous_x: float = position.x
	super._physics_process(delta)
	if controls_enabled:
		action_visual.update(delta, position.x - previous_x)
	position.x = clampf(position.x, 35.0, 3165.0)

func skill_unlocked(rule: String) -> bool:
	return rule == "always"

func skill_practice_enabled() -> bool:
	return false

func ability_available(action: String) -> bool:
	return action not in ["A1_dash", "A5_slit"]

func request_action(action: String) -> bool:
	if not ability_available(action):
		notification.emit("这段旅途使用移动、跳跃和骨鸣器短击。")
		return false
	return super.request_action(action)

func clear_input() -> void:
	skill_controller.input.clear()
	jump_buffer = 0.0
	pending_action = ""
	pending_left = 0.0
	short_jump = false
	velocity = Vector2.ZERO
