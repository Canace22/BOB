extends Node2D
## Coordinates and stable edge IDs are the contract. Never infer exits from room index.
var level: Node2D
var rings: Array=[]
var clock:=0.0
var membrane_load:=0.0
var membrane_offset:=0.0
var membrane_body: StaticBody2D
var door_nodes: Dictionary={}
var blueprint: Node2D
var hazard_phase:="idle"

func setup(owner_level: Node2D) -> void:
	level=owner_level
	rings=level.room.get("anchors",[])
	z_index=2
	for d in level.room.doors:
		var root=Node2D.new()
		root.name=str(d.id)
		root.position=Vector2(d.x,d.y)*64
		add_child(root)
		var art=Sprite2D.new()
		art.texture=load("res://assets/runtime/v02/gate.png")
		art.position=Vector2(0,-70)
		art.scale=Vector2(130,140)/art.texture.get_size()
		root.add_child(art)
		var label=Label.new()
		label.name="CoordinateLabel"
		label.text=str(d.id)+" → "+str(d.to)
		label.position=Vector2(-65,-170)
		label.add_theme_font_size_override("font_size",15)
		root.add_child(label)
		door_nodes[d.id]=root
	# Hide former decorative duplicate gate images; interactions are world-fixed here.
	for name in ["Gate_A2","Gate_A3","GateLabel_A2","GateLabel_A3","LungSideLockedGate"]:
		var n=level.scenery.get_node_or_null("World/"+name)
		if n:n.hide()
	if level.game.room_index==2: membrane_body=level.scenery.get_node("World/Shelf_P2")
	blueprint=load("res://scripts/route_blueprint.gd").new()
	add_child(blueprint)
	blueprint.level=level
	blueprint.z_index=15
	queue_redraw()

func nearest_door() -> Dictionary:
	for d in level.room.doors:
		if level.player.position.distance_to(Vector2(d.x,d.y)*64)<100: return d
	return {}

func denied(d: Dictionary) -> String:
	var g=level.game
	for ability in d.condition.get("requiresAll",[]):
		if not has_ability(str(ability)): return "需要 "+str(ability)+" · 按设计从后续区域获得后回访"
	if d.condition.get("completionFlags",[]).has("BOSS_R1") and not g.data.boss: return "负壳蟹仍封锁口咽"
	if g.room_index==3 and level.boss_started and not g.data.boss: return "战斗封场 · 先击败负壳蟹"
	if g.room_index==3 and d.to=="R1-05" and not g.data.dash: return "先在右岸承接贴流冲"
	if d.id=="E34" and not g.data.get("SC_BLOWHOLE",false): return "远侧壳闩关闭 · 只能从 R2-05 开启，此侧没有把手"
	return ""

func has_ability(id: String) -> bool:
	if id=="A1":return level.game.data.dash
	return level.game.data.get(id,false)

func use_door() -> bool:
	var d=nearest_door()
	if d.is_empty():return false
	var reason=denied(d)
	if reason!="":
		level.message(reason)
		level.game.record("gate_denied",{"edge":d.id,"reason":reason})
		return true
	var target=-1
	for i in range(level.main.rooms.size()):
		if level.main.rooms[i].id==d.to: target=i
	if target<0:
		if d.to=="R3-01":
			level.game.data.complete=true
			level.game.save_game()
			level.game.record("level_complete",{"edge":d.id,"destination":d.to})
			level.main.finish()
		else: level.message(str(d.to)+" 是后续区域边界，本交付未包含该区域")
		return true
	level.game.record("door_transition",{"edge":d.id,"from":level.room.id,"to":d.to})
	level.main.change_room(target,"door:"+str(d.id))
	return true

func reward_key(index: int) -> String:
	return str(level.room.id)+"_REWARD_"+str(index)

func collect_revisit() -> bool:
	if level.game.room_index<5:return false
	for i in range(level.room.rewards.size()):
		var r=level.room.rewards[i]
		if level.player.position.distance_to(Vector2(r.x,r.y)*64)>100:continue
		var id=reward_key(i)
		if level.game.data.get(id,false):continue
		level.game.data[id]=true
		level.game.save_game()
		level.game.record("revisit_reward",{"id":id})
		level.message(str(r.label)+" · "+("路线验证中，退出恢复原进度" if level.game.transient else "已记录"))
		level.sfx("collect")
		return true
	return false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(level):return
	clock+=delta
	for d in level.room.doors:
		door_nodes[d.id].modulate=Color("9abbbc") if denied(d)=="" else Color("9e8276")
		door_nodes[d.id].get_node("CoordinateLabel").visible=level.main.scenery_preview or level.main.route_overlay
	blueprint.visible=level.main.route_overlay
	blueprint.queue_redraw()
	if level.main.scenery_preview: return
	var p=level.player
	# Visible warning -> active interval -> recovery. The hazard is not a decorative fish school.
	if level.game.room_index in [1,5]:
		var h=level.room.hazards[0]
		var t=fmod(clock,5.0)
		hazard_phase="tell" if t<0.8 else ("active" if t<1.5 else "idle")
		if hazard_phase=="active" and p.invulnerable<=0 and Rect2(h.x*64,(h.y-1.1)*64,h.w*64,70).has_point(p.position-Vector2(0,20)):
			p.take_hit(h.x*64)
			if not p.respawning:
				p.position=p.last_safe
				p.velocity=Vector2.ZERO
			level.game.record("route_hazard",{"type":h.type})
	# Load-bearing membrane deforms after 0.7s, but does not pull collision from under the player.
	if is_instance_valid(membrane_body):
		var loaded=p.is_on_floor() and p.position.x>16*64 and p.position.x<21*64 and absf(p.position.y-(14*64+membrane_offset))<10
		membrane_load=membrane_load+delta if loaded else 0.0
		var next=move_toward(membrane_offset,20.0 if membrane_load>=0.7 else 0.0,delta*22)
		if loaded: p.position.y+=next-membrane_offset
		membrane_offset=next
		membrane_body.position.y=14*64+membrane_offset
		for pl in level.platforms:
			if pl.id=="P2":pl.y=14+membrane_offset/64
	# Each teaching gap has a local visible rescue bed; it cannot become a route under the boss.
	if level.game.room_index==4:
		for h in level.room.hazards:
			if p.position.x>h.x*64 and p.position.x<(h.x+h.w)*64 and p.position.y>h.y*64:
				p.fall_recover()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(level):return
	for i in range(rings.size()):
		var a=rings[i];var at=Vector2(a.x,a.y)*64
		# Original authored cord art stays in room07; room02's missing three rings are restored here.
		if level.game.room_index!=6:
			draw_line(at-Vector2(5,150),at,Color("773c35"),4,true)
			draw_arc(at,17,0,TAU,32,Color("ecd6a2"),5,true)
		if level.player.get("anchor_index")==i:draw_arc(at,24,0,TAU,32,Color("8be8df"),3,true)
	for i in range(level.room.get("rewards",[]).size()):
		if level.game.room_index<5:continue
		var r=level.room.rewards[i];var at=Vector2(r.x,r.y)*64
		var n=level.scenery.get_node_or_null("World/Reward_"+str(i))
		if n:n.visible=not level.game.data.get(reward_key(i),false)
		if not level.game.data.get(reward_key(i),false):
			draw_circle(at,12,Color("a9d5dd"))
			draw_arc(at,23,0,TAU,24,Color(0.6,0.8,0.9,0.4),2,true)
	if level.game.room_index in [1,5]:
		var h=level.room.hazards[0]
		var origin=Vector2(h.x,h.y)*64
		if hazard_phase=="tell":
			draw_dashed_line(origin-Vector2(0,24),origin+Vector2(h.w*64,-24),Color("f3b86f"),3,12)
		elif hazard_phase=="active":
			for j in range(12):
				var at=origin+Vector2(fmod(clock*500+j*19,h.w*64),-20-j%3*17)
				draw_line(at,at+Vector2(12,-4),Color("f49c65"),3,true)
	if level.game.room_index==4:
		for h in level.room.hazards:
			var a=Vector2(h.x,h.y)*64
			draw_style_box(soft_bed(),Rect2(a,Vector2(h.w*64,20)))
			draw_arc(a+Vector2(h.w*32,4),25,PI,TAU,20,Color("9fced0"),2,true)

func soft_bed() -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.45,0.64,0.65,0.35)
	style.corner_radius_top_left=18
	style.corner_radius_top_right=18
	return style
