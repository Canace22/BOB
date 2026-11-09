class_name WhalebellyCampaignCamera
extends Camera2D
@export var lookahead:float=120.0 # New default; Inspector adjustable.
@export var shake_pixels:float=6.0 # New default; Inspector adjustable.
@export var dash_zoom:float=1.05 # New default; Inspector adjustable.
@export var follow_rate:float=6.0 # Existing main.gd smooth-follow rate.
@export var vertical_follow_rate: float = 3.5
@export var lookahead_rate: float = 4.0
@export var dead_zone: Vector2 = Vector2(32, 65)
var host:Node2D
var tracked_room:String=""
var follow_anchor: Vector2
var smoothed_lookahead: float = 0.0
var was_following: bool = false

func update_follow(dt:float) -> void:
	if not is_instance_valid(host.player):return
	var follow:bool=(host.zoomed or host.reference_camera_active()) and not host.reference_visible and host.capture_path.is_empty() and host.layer_solo < 0
	var world_size:Vector2=host.point(host.room.size)
	var changed_room: bool = tracked_room != str(host.room.id)
	var bounds: Rect2
	if follow:
		var z:float=1.0/(dash_zoom if host.player.state in ["A1_dash","A5_slit"] else 1.0)
		# Zoom-out may not reveal beyond the authored room at either edge.
		var viewport_size: Vector2 = get_viewport_rect().size
		z = maxf(z, maxf(viewport_size.x / world_size.x, viewport_size.y / world_size.y))
		zoom=zoom.lerp(Vector2.ONE*z,1-exp(-dt*follow_rate))
		zoom = zoom.max(Vector2.ONE * maxf(viewport_size.x / world_size.x, viewport_size.y / world_size.y))
		var half:Vector2=get_viewport_rect().size/(2*zoom)
		var margin:float=28 if host.room.get("layered_environment",false) else 0
		var vmargin:float=12 if host.room.get("layered_environment",false) else 0
		bounds = center_bounds(world_size, half, Vector2(margin, vmargin))
		if changed_room or not was_following:
			follow_anchor = host.player.position
			smoothed_lookahead = host.player.facing * lookahead
		else:
			follow_anchor = retain_dead_zone(follow_anchor, host.player.position, dead_zone)
			smoothed_lookahead = lerpf(smoothed_lookahead, host.player.facing * lookahead, 1.0 - exp(-dt * lookahead_rate))
		var target: Vector2 = clamp_center(follow_anchor + Vector2(smoothed_lookahead, -170), bounds)
		if changed_room or not was_following:
			position = target
		else:
			position.x = lerpf(position.x, target.x, 1.0 - exp(-dt * follow_rate))
			position.y = lerpf(position.y, target.y, 1.0 - exp(-dt * vertical_follow_rate))
		position = clamp_center(position, bounds)
	else:
		var fit:float=minf(get_viewport_rect().size.x/world_size.x,get_viewport_rect().size.y/world_size.y)
		zoom=Vector2.ONE*fit;position=world_size*.5
	# Bounds follow the authored room dimensions; no scenery node is changed.
	limit_left=0;limit_top=0;limit_right=int(world_size.x);limit_bottom=int(world_size.y)
	tracked_room=str(host.room.id)
	was_following = follow
	host.camera_feedback=maxf(0,host.camera_feedback-dt)
	var shake: Vector2 = Vector2.ZERO
	if follow and host.camera_feedback > 0:
		shake = Vector2(randf_range(-1,1),randf_range(-1,1)) * maxf(0.0, shake_pixels) * clampf(host.camera_feedback / .18, 0.0, 1.0)
		shake = clamp_center(position + shake, bounds) - position
	offset = shake

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
