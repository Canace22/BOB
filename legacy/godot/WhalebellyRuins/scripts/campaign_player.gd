extends "res://scripts/tide_player.gd"
# Compatibility boundary: authored rooms, enemy dictionaries and V6 saves stay owned by main.gd.
@export var spawn_input_lock:float=0.1 # New default: discard carried input on room load.
var spawn_lock_left:float=0
@export var automatic_doors:bool=true # Added default; preserve E as alternate interaction.
@export var door_entry_radius:float=48.0
@export var door_rearm_distance:float=160.0
var armed_doors:Dictionary={}
var host: Node2D
var art: Node2D
var last_safe:=Vector2.ZERO
var grapple_target:=Vector2.INF
var float_left:float=1.5
var drop_timer:float=0
var floating:bool=false
var membrane_boost:bool=false
var qa_mode:bool=false
var qa_axis:float=0
var transition_locked:bool=false
var run_visual: Node

func _ready() -> void:
	spawn_lock_left=spawn_input_lock
	world_bounds=Rect2(Vector2.ZERO,host.point(host.room.size))
	super._ready()
	floor_max_angle=deg_to_rad(55)
	floor_snap_length=24
	var target_height:float=94
	for actor:Dictionary in host.room.get("actors",[]):
		if actor.get("name","")=="PlayerArt":
			var top:float=100000;var bottom:float=-100000
			for vertex:Array in actor.get("shape",[]):top=minf(top,float(vertex[1]));bottom=maxf(bottom,float(vertex[1]))
			if bottom>top:target_height=clampf(bottom-top,80,110)
	var source_height:float=textures.idle[0].get_image().get_used_rect().size.y
	visual_scale=target_height/maxf(source_height,1)
	$Visual.scale=Vector2.ONE*visual_scale
	run_visual=preload("res://scripts/campaign_run_visual.gd").new()
	run_visual.name="RunVisualController"
	add_child(run_visual)
	run_visual.setup(self,target_height)
	for ray:RayCast2D in [$Foot0,$"Foot-10",$Foot10]:ray.target_position.y=30
	health=clampi(host.health,0,max_health)
	soul=host.player_soul
	last_safe=position
	if art!=null:art.visible=false
	stats_changed.connect(_sync_stats)
	interaction_requested.connect(_interact_campaign)
	notification.connect(func(text):host.notify(text))
	hit_confirmed.connect(func():host.camera_feedback=.12)
	damaged.connect(func():host.sfx("hurt");host.camera_feedback=.18;host.record_event("player_hurt",{"health":health}))
	died.connect(func():host.respawn.call_deferred())
	animation_tag.connect(_campaign_tag)
	stats_changed.emit(health,soul)

func _sync_stats(h:int,s:int) -> void:
	host.health=h
	host.player_soul=s

func _campaign_tag(tag:String) -> void:
	if tag=="jump":host.sfx("jump");host.record_event("jump")
	elif tag=="A1_dash:start":host.sfx("dash");host.record_event("dash")
	elif tag=="strike_01:start":host.sfx("strike");host.record_event("attack",{"room":host.room_index})
	elif tag=="heavy:release":host.sfx("heavy")
	elif tag=="recover:end":host.sfx("heal")

func _physics_process(dt:float) -> void:
	var reference_mode:bool=host.reference_visible or host.layer_solo>=0 or not host.capture_path.is_empty()
	$Visual.visible=not reference_mode
	if art!=null:art.visible=reference_mode
	if reference_mode or transition_locked:return
	if host.health!=health:
		health=clampi(host.health,0,max_health)
		stats_changed.emit(health,soul)
	spawn_lock_left=maxf(0,spawn_lock_left-dt)
	drop_timer=maxf(0,drop_timer-dt)
	if is_on_floor():float_left=1.5;membrane_boost=false
	interacted_target=host if interaction_nearby() else null
	var before_move_x:float=position.x
	super._physics_process(dt)
	run_visual.update(dt,position.x-before_move_x)
	_check_door_entry()
	position.x=clampf(position.x,18,1460 if host.room_index==6 else float(host.room.size[0])-18)
	if is_on_floor() and position.y<float(host.room.size[1])-65 and stable_floor_point():last_safe=position
	if health<=0:return
	for bed:Dictionary in host.room.get("soft_beds",[]):
		if position.x>float(bed["from"]) and position.x<float(bed.to) and position.y>float(bed.y):
			host.record_event("soft_bed_recover",{"position":[position.x,position.y],"return":[last_safe.x,last_safe.y]})
			hurt(1,true);break

func movement_axis() -> float:
	if spawn_lock_left>0:return 0
	if qa_mode:return qa_axis
	var axis:float=super.movement_axis()
	return axis if absf(axis)>0 else Input.get_axis("left","right")

func movement_collision_mask() -> int:
	return 0 if drop_timer>0 else super.movement_collision_mask()

func _read_input() -> void:
	if spawn_lock_left>0:return
	super._read_input()
	if Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("tp_jump"):jump_buffer=jump_buffer_time
	if Input.is_action_just_released("jump"):short_jump=true
	for old in ["attack","dash","interact"]:
		var modern:String={"attack":"tp_attack","dash":"tp_dash","interact":"tp_interact"}[old]
		if Input.is_action_just_pressed(old) and not Input.is_action_just_pressed(modern):request_action({"attack":"strike_01","dash":"A1_dash","interact":"interact"}[old])
	var pressed_jump:bool=Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("tp_jump")
	if pressed_jump and Input.is_action_pressed("down") and host.room_index==2 and position.x>700 and position.x<970 and position.y<730 and is_on_floor():
		var mechanism:Node=host.scenery.get_node_or_null("VisualMechanisms")
		if mechanism!=null and float(mechanism.membrane_drop)>15:
			drop_timer=.28;jump_buffer=0;coyote=0;velocity.y=180
			host.sfx("sweep");host.record_event("membrane_dive",{"position":[position.x,position.y],"drop":mechanism.membrane_drop})
	if Input.is_action_just_pressed("float") and not host.has_ability("float"):host.notify("浮游尚未解锁；F9可进入原有能力练习模式")
	if Input.is_action_just_pressed("grapple"):
		if not host.has_ability("anchor"):host.notify("锚环尚未解锁；F9可进入原有能力练习模式")
		else:_find_ring()

	if membrane_boost:short_jump=false

func _try_jump() -> void:
	var rebound:bool=host.room_index==2 and position.x>700 and position.x<970 and position.y>730 and is_on_floor()
	membrane_boost=rebound
	super._try_jump()
	if rebound and velocity.y<0:
		velocity.y=-670;short_jump=false;host.record_event("membrane_rebound",{"position":[position.x,position.y]})

func _find_ring() -> void:
	if state_duration>0:return
	if grapple_target!=Vector2.INF:grapple_target=Vector2.INF;return
	var distance:float=390
	for point:Array in host.room.get("rings",[]):
		var target:Vector2=host.point(point)+Vector2(0,55)
		if position.distance_to(target)<distance and position.distance_to(target)>90 and (target.x-position.x)*facing>-35:
			distance=position.distance_to(target);grapple_target=target
	if grapple_target!=Vector2.INF:host.record_event("anchor",{"target":[grapple_target.x,grapple_target.y]})

func _before_move(dt:float) -> void:
	floating=false
	if drop_timer>0:velocity.y=maxf(velocity.y,180)
	if grapple_target!=Vector2.INF:
		velocity=position.direction_to(grapple_target)*640
		if position.distance_to(grapple_target)<24:grapple_target=Vector2.INF;velocity.y=-340;float_left=1.5
	elif Input.is_action_pressed("float") and host.has_ability("float") and not is_on_floor() and float_left>0 and velocity.y>-160 and state_duration<=0:
		float_left-=dt;velocity.y=move_toward(velocity.y,-160,2200*dt);floating=true

func locomotion_animation() -> String:
	if grapple_target!=Vector2.INF:return "A3_anchor"
	if floating:return "A2_float"
	return super.locomotion_animation()

func ability_available(action:String) -> bool:
	return host.has_ability("dash") if action in ["A1_dash","A5_slit"] else true

func request_action(action:String) -> bool:
	if action in ["A1_dash","A5_slit"] and not host.has_ability("dash"):
		host.notify("冲刺尚未解锁：击败负壳守卫获得；F9可临时练习")
		return false
	var accepted:bool=super.request_action(action)
	if accepted:grapple_target=Vector2.INF
	return accepted

func _melee(downward:bool) -> void:
	if downward:super._melee(true);return
	# Preserve the existing boss and regular enemy reach instead of shrinking it to demo dimensions.
	for target in get_tree().get_nodes_in_group("tide_targets"):
		if not target.has_method("is_campaign_enemy"):continue
		var delta:Vector2=target.global_position-global_position
		if absf(delta.x)<(180 if target.data.boss else melee_reach) and absf(delta.y)<125 and delta.x*facing>-25:_hit(target,melee_damage,true)

func hurt(amount:int,fall:bool=false) -> void:
	if health<=0:return
	take_damage(amount,Vector2.ZERO,fall)
	if fall:position=last_safe;velocity=Vector2.ZERO;grapple_target=Vector2.INF

func interaction_nearby() -> bool:
	var reward:Array=host.room.get("reward",[])
	if reward.size()==2 and position.distance_to(host.point(reward))<100 and not host.collected.get(str(host.room.id),false):return true
	for door:Dictionary in host.room.get("doors",[]):
		if position.distance_to(host.point(door.pos))<125:return true
	var camp:Array=host.room.get("camp",{0:[93,550],3:[80,610],4:[110,503]}.get(host.room_index,[]))
	return camp.size()==2 and position.distance_to(host.point(camp))<180

func _interact_campaign(_target:Node) -> void:
	transition_locked=true
	_finish_interact.call_deferred()

func _finish_interact() -> void:
	# Defer the old room-changing callback until the physics/animation tick finishes.
	host.interact()
	if is_inside_tree():transition_locked=false

func respawn() -> void:
	if is_instance_valid(host):host.respawn.call_deferred()

func _check_door_entry() -> void:
	if not automatic_doors or not controls_enabled or health<=0 or transition_locked or state=="interact":return
	for i in range(host.room.get("doors",[]).size()):
		var door:Dictionary=host.room.doors[i]
		# Existing camps overlap some return-door triggers: keep those doors explicit E.
		var camp:Array=host.room.get("camp",{0:[93,550],3:[80,610],4:[110,503]}.get(host.room_index,[]))
		if camp.size()==2 and host.point(door.pos).distance_to(host.point(camp))<180:continue
		var delta:Vector2=host.point(door.pos)-position
		if delta.length()>door_rearm_distance:armed_doors[i]=true
		if armed_doors.get(i,false) and absf(delta.x)<door_entry_radius and absf(delta.y)<125 and absf(movement_axis())>.1:
			armed_doors[i]=false;transition_locked=true
			_finish_door.call_deferred(door)
			break

func _finish_door(door:Dictionary) -> void:
	host.enter_door(door)
	if is_inside_tree():transition_locked=false

func stable_floor_point() -> bool:
	for surface: Array in host.room.surfaces:
		if position.x<float(surface[0][0])+18.0 or position.x>float(surface[-1][0])-18.0: continue
		for i: int in range(surface.size()-1):
			var a: Vector2 = Vector2(float(surface[i][0]),float(surface[i][1]))
			var b: Vector2 = Vector2(float(surface[i+1][0]),float(surface[i+1][1]))
			if position.x>=minf(a.x,b.x) and position.x<=maxf(a.x,b.x) and absf(b.x-a.x)>0.01:
				var y: float = lerpf(a.y,b.y,(position.x-a.x)/(b.x-a.x))
				if absf(position.y-y)<22.0: return true
	return false

func take_damage(amount:int=1,source:Vector2=Vector2.ZERO,force:bool=false) -> bool:
	var accepted:bool=super.take_damage(amount,source,force)
	if accepted:grapple_target=Vector2.INF;floating=false;membrane_boost=false
	return accepted
