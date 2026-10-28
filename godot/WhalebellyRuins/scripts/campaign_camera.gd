extends Camera2D
@export var lookahead:float=120.0 # New default; Inspector adjustable.
@export var shake_pixels:float=6.0 # New default; Inspector adjustable.
@export var dash_zoom:float=1.05 # New default; Inspector adjustable.
@export var follow_rate:float=6.0 # Existing main.gd smooth-follow rate.
var host:Node2D
var tracked_room:String=""
func update_follow(dt:float) -> void:
	if not is_instance_valid(host.player):return
	var follow:bool=(host.zoomed or host.reference_camera_active()) and not host.reference_visible
	var world_size:Vector2=host.point(host.room.size)
	if follow:
		var z:float=1.0/(dash_zoom if host.player.state in ["A1_dash","A5_slit"] else 1.0)
		zoom=zoom.lerp(Vector2.ONE*z,1-exp(-dt*follow_rate))
		var half:Vector2=get_viewport_rect().size/(2*zoom)
		var margin:float=28 if host.room.get("layered_environment",false) else 0
		var vmargin:float=12 if host.room.get("layered_environment",false) else 0
		var target:Vector2=host.player.position+Vector2(host.player.facing*lookahead,-170)
		target.x=clampf(target.x,half.x+margin,maxf(half.x+margin,world_size.x-half.x-margin))
		target.y=clampf(target.y,half.y+vmargin,maxf(half.y+vmargin,world_size.y-half.y-vmargin))
		position=target if tracked_room!=str(host.room.id) else position.lerp(target,1-exp(-dt*follow_rate))
	else:
		var fit:float=minf(get_viewport_rect().size.x/world_size.x,get_viewport_rect().size.y/world_size.y)
		zoom=Vector2.ONE*fit;position=world_size*.5
	# Bounds follow the authored room dimensions; no scenery node is changed.
	limit_left=0;limit_top=0;limit_right=int(world_size.x);limit_bottom=int(world_size.y)
	tracked_room=str(host.room.id)
	host.camera_feedback=maxf(0,host.camera_feedback-dt)
	offset=Vector2(randf_range(-1,1),randf_range(-1,1))*shake_pixels*(host.camera_feedback/.18) if host.camera_feedback>0 else Vector2.ZERO
