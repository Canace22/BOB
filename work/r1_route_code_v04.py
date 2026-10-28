from pathlib import Path
p=Path('G:/鲸落万物生/BOB/godot/first-level')
f=p/'scripts/level.gd';s=f.read_text('utf8')
s=s.replace('var scenery: Node2D','var scenery: Node2D\nvar route_system: Node2D')
s=s.replace('\tplayer.last_safe=player.position','''	if entry.begins_with("door:"):
		for door in room.doors:
			if str(door.id)==entry.trim_prefix("door:"):
				var inset=1.15 if door.side=="left" else (-1.15 if door.side=="right" else 0.0)
				player.position=Vector2((door.x+inset)*64,door.y*64-3)
	player.last_safe=player.position''',1)
s=s.replace('\tgame.record("room_enter",', '\troute_system=load("res://scripts/room_routes.gd").new()\n\tadd_child(route_system)\n\troute_system.setup(self)\n\tgame.record("room_enter",',1)
s=s.replace('camera.zoom=Vector2(0.80,0.80)','''camera.zoom=Vector2.ONE*minf(1180.0/room_width,540.0/(death_y-30)) if main.preview_fit else Vector2(0.80,0.80)
		if main.preview_fit:camera.position=Vector2(room_width/2,(death_y-30)/2)''')
start=s.index('\tif x<1.4 and game.room_index>0:',s.index('func interact'))
end=s.index('\nfunc respawn',start)
s=s[:start]+'''	if route_system.collect_revisit(): return
	route_system.use_door()
'''+s[end:]
start=s.index('\tvar floor_y=',s.index('func _draw'))
end=s.index('\tif game.room_index==2 and not game.data.fragment:',start)
s=s[:start]+s[end:]
s=s.replace('draw_collect(Vector2(24.5*64,11.3*64-45)','draw_collect(Vector2(24.5*64,10.5*64)')
s=s.replace('\tif game.room_index>0 and x<1.4: return "E · 返回上一段"','')
s=s.replace('\tif x>float(room.width)-2.7: return "E · 前往下一段" if game.room_index<4 else "E · 完成须门遗港"','''	if game.room_index>=5:
		for reward in room.rewards:
			if player.position.distance_to(Vector2(reward.x,reward.y)*64)<100:return "E · 领取回访奖励"
	var door=route_system.nearest_door()
	if not door.is_empty():
		var reason=route_system.denied(door)
		return "E · "+str(door.to) if reason=="" else reason
	if main.route_sandbox:return "回访验证 · W 浮升（落台补压） · J 挂环/换环 · Space 脱环 · E 房门"''')
f.write_text(s,encoding='utf8')
f=p/'scripts/game.gd';s=f.read_text('utf8').replace('var qa := false','var qa := false\nvar transient := false')
s=s.replace('func save_game() -> void:\n','func save_game() -> void:\n\tif transient: return\n')
f.write_text(s,encoding='utf8')
f=p/'scripts/player.gd';s=f.read_text('utf8').replace('var qa := false','''var qa := false
var float_pressure:=1.35
var anchor_index:=-1
var last_anchor_index:=-1
var anchor_arrived:=false''')
s=s.replace('\tif is_on_floor():\n\t\tgrounded_time','\tif is_on_floor():\n\t\tfloat_pressure=1.35\n\t\tlast_anchor_index=-1\n\t\tgrounded_time',1)
s=s.replace('\tif Input.is_action_just_pressed("attack"):', '\tif Input.is_action_just_pressed("attack") and anchor_index<0:')
s=s.replace('if Input.is_action_just_pressed("heavy") and attack_time','if Input.is_action_just_pressed("heavy") and anchor_index<0 and attack_time')
s=s.replace('\tmove_and_slide()','''	if Input.is_action_just_pressed("anchor") and level.route_system.has_ability("A3"):
		choose_anchor()
	if anchor_index>=0:
		if Input.is_action_just_pressed("jump"):
			last_anchor_index=anchor_index
			anchor_index=-1
			velocity.y=-380
		else:
			var a=level.route_system.rings[anchor_index]
			var target=Vector2(a.x,a.y)*64+Vector2(0,52)
			var difference=target-position
			velocity=difference.normalized()*minf(520,difference.length()/maxf(delta,0.001))
			attack_time=-1
			if difference.length()<5 and not anchor_arrived:
				anchor_arrived=true
				game.record("anchor_arrive",{"index":anchor_index,"x":position.x/64,"y":position.y/64})
	elif Input.is_action_pressed("up") and level.route_system.has_ability("A2") and float_pressure>0 and attack_time<0 and dash_time<=0:
		float_pressure=maxf(0,float_pressure-delta)
		velocity.y=-230
	move_and_slide()''',1)
s=s.replace('\tposition=last_safe','\tanchor_index=-1\n\tposition=last_safe',1)
s=s.replace('func _draw() -> void:\n','''func choose_anchor() -> void:
	var best=-1
	var score=100000.0
	for i in range(level.route_system.rings.size()):
		if i==anchor_index or (anchor_index<0 and i==last_anchor_index):continue
		var a=level.route_system.rings[i]
		var at=Vector2(a.x,a.y)*64
		var distance=(position-Vector2(0,30)).distance_to(at)
		var dx=at.x-position.x
		if distance>float(a.get("reach",4.5))*64:continue
		var value=distance+(250 if dx*facing<-10 else 0)
		if value<score:score=value;best=i
	if best>=0:
		anchor_index=best
		anchor_arrived=false
		attack_time=-1
		heal_time=-1
		game.record("anchor_grab",{"index":best})

func _draw() -> void:
	if anchor_index>=0:
		var a=level.route_system.rings[anchor_index]
		draw_line(Vector2(0,-30),Vector2(a.x,a.y)*64-position,Color("d77555"),3,true)
	if level.route_system.has_ability("A2") and float_pressure<1.35:
		draw_arc(Vector2(0,-35),45,-PI/2,-PI/2+TAU*float_pressure/1.35,32,Color("8cd0da"),3,true)
''')
f.write_text(s,encoding='utf8')
# Procedural organisms should not appear inside cranial plates.
f=p/'scripts/atmosphere.gd';s=f.read_text('utf8').replace('for i in range(9):','for i in range(0 if level.game.room_index==5 else 9):');f.write_text(s,encoding='utf8')
print('Door graph, return positions, late-ability traversal and scene events integrated.')
