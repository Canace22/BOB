class_name WhalebellyCampaignCamera
extends Camera2D
@export var gameplay_zoom: float = 1.0
@export var edge_softness: float = 120.0
# 兼容旧场景和设置接口；内部居中、世界外缘软限位，不使用前视、探看或冲刺缩放。
@export var lookahead:float=56.0 # Small lead: turning around must not swing the view.
@export var shake_pixels:float=8.0
@export var dash_zoom:float=1.05 # New default; Inspector adjustable.
@export var follow_rate:float=8.0
@export var vertical_follow_rate: float = 3.5
@export var lookahead_rate: float = 4.0
@export var dead_zone: Vector2 = Vector2(32, 65)
@export var look_distance: float = 150.0 # Hold up/down while standing still to peek.
@export var look_delay: float = 0.45
@export var look_rate: float = 6.0
@export var fall_lead: float = 110.0 # Shift down and catch up faster during a long fall.
@export var fall_lead_start: float = 350.0
@export var fall_lead_full: float = 850.0
@export var fall_follow_rate: float = 10.0
var host:Node2D
var tracked_room:String=""
var follow_anchor: Vector2
var smoothed_lookahead: float = 0.0
var smoothed_look: float = 0.0
var look_hold: float = 0.0
var was_following: bool = false
var world_edges := CampaignCameraWorldBounds.new()

func configure_world(layout: Dictionary) -> void:
	world_edges.configure(layout)

func update_follow(dt:float) -> void:
	if not is_instance_valid(host.player):return
	var follow:bool=not host.reference_visible and host.capture_path.is_empty() and host.layer_solo < 0
	var world_size:Vector2=host.point(host.room.size)
	# 正常镜头使用全局坐标；房间父节点移动不能造成视角跳变。
	position_smoothing_enabled = false
	rotation_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	limit_enabled = false
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	offset = Vector2.ZERO
	if follow:
		zoom = Vector2.ONE * maxf(gameplay_zoom, 0.01)
		# 用完整世界轮廓限制视口；跨房不重新初始化镜头，不按当前房矩形夹住。
		global_position = follow_target(host.player.global_position)
		follow_anchor = global_position
		smoothed_lookahead = 0.0
		smoothed_look = 0.0
		look_hold = 0.0
	else:
		var fit:float=minf(get_viewport_rect().size.x/world_size.x,get_viewport_rect().size.y/world_size.y)
		var scenery: Node2D = host.get("scenery") as Node2D
		var room_origin: Vector2 = scenery.global_position if is_instance_valid(scenery) else host.global_position
		zoom=Vector2.ONE*fit
		global_position=room_origin+world_size*.5
	tracked_room=str(host.room.id)
	was_following = follow
	host.camera_feedback=maxf(0,host.camera_feedback-dt)
	# 节点位置相同并不保证实际画面中心相同，立即提交去除旧限位/平滑残留。
	force_update_scroll()

func follow_target(actor: Vector2) -> Vector2:
	return world_edges.target(actor,get_viewport_rect().size/(Vector2.ONE*maxf(gameplay_zoom,0.01))*0.5,edge_softness)

func fall_amount() -> float:
	var actor: CharacterBody2D = host.player as CharacterBody2D
	if actor == null: return 0.0
	return clampf((actor.velocity.y - fall_lead_start) / maxf(1.0, fall_lead_full - fall_lead_start), 0.0, 1.0)

func update_look(dt: float) -> void:
	var actor: TidePlayer = host.player as TidePlayer
	var axis: float = 0.0
	# Only a settled, idle actor peeks; up/down stay free as attack and spell modifiers.
	if actor != null and actor.controls_enabled and actor.is_on_floor() and actor.state == "idle" and actor.velocity.length() < 5.0:
		axis = Input.get_axis("tp_up", "tp_down")
	look_hold = look_hold + dt if not is_zero_approx(axis) else 0.0
	var goal: float = signf(axis) * look_distance if look_hold >= look_delay else 0.0
	smoothed_look = lerpf(smoothed_look, goal, 1.0 - exp(-dt * look_rate))

static func retain_dead_zone(anchor: Vector2, actor: Vector2, half_zone: Vector2) -> Vector2:
	var delta: Vector2 = actor - anchor
	return anchor + Vector2(signf(delta.x) * maxf(0.0, absf(delta.x) - half_zone.x), signf(delta.y) * maxf(0.0, absf(delta.y) - half_zone.y))

static func center_bounds(world: Vector2, half_view: Vector2, margin: Vector2) -> Rect2:
	var available: Vector2 = (world * .5 - half_view).max(Vector2.ZERO)
	var safe_margin: Vector2 = margin.min(available)
	var minimum: Vector2 = half_view.min(world * .5) + safe_margin
	return Rect2(minimum, (world - minimum * 2.0).max(Vector2.ZERO))

static func clamp_center(point: Vector2, bounds: Rect2) -> Vector2:
	return point.clamp(bounds.position, bounds.end)
