extends Node2D
const PLAYER=preload("res://scripts/player.gd")
const ENEMY=preload("res://scripts/enemy.gd")
var game: Node
var main: Node
var player: CharacterBody2D
var camera: Camera2D
var enemies: Array=[]
var platforms: Array=[]
var room: Dictionary
var room_width:=1920.0
var death_y:=1200.0
var boss_started:=false
var time:=0.0
var background: Texture2D
var terrain: Texture2D
var checkpoint: Texture2D
var foreground: Texture2D
var motes: Array=[]
var bridge: StaticBody2D
var latch_anim:=0.0
var effects: Node2D
var feedback_shake:=0.0
var environment_layers: Array=[]
var scenery: Node2D
var route_system: Node2D
var actors: Node2D

func setup(g: Node,m: Node,data: Dictionary,entry: String="left") -> void:
	game=g
	main=m
	room=data
	room_width=float(room.width)*64
	death_y=float(room.height)*64+30
	platforms=room.platforms.duplicate(true)
	scenery=load("res://scenes/r1/"+str(room.id)+".tscn").instantiate()
	add_child(scenery)
	for child in scenery.find_children("*", "Node2D", true, false):
		if child.has_method("bind"): child.bind(self)
	actors=Node2D.new()
	actors.name="Actors"
	actors.z_index=2
	scenery.get_node("World").add_child(actors)
	player=CharacterBody2D.new()
	player.set_script(PLAYER)
	player.game=game
	player.level=self
	var main_platforms=platforms.filter(func(p):return str(p.id).begins_with("P"))
	var start=main_platforms[-1] if entry=="right" else main_platforms[0]
	player.position=Vector2((float(start.x)+float(start.w)-2 if entry=="right" else 3.0)*64,float(start.y)*64-3)
	if game.room_index==3 and entry=="right": player.position=Vector2(33*64,14*64-3)
	if entry.begins_with("door:"):
		for door in room.doors:
			if str(door.id)==entry.trim_prefix("door:"):
				var inset=1.15 if door.side=="left" else (-1.15 if door.side=="right" else 0.0)
				player.position=Vector2((door.x+inset)*64,door.y*64-3)
	player.last_safe=player.position
	player.name="Player"
	actors.add_child(player)
	camera=Camera2D.new()
	camera.position=Vector2(player.position.x+160,player.position.y-200)
	camera.limit_left=-300 if game.room_index==0 else 0
	camera.limit_right=int(room_width)
	camera.limit_top=0
	camera.limit_bottom=int(death_y)
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=5
	add_child(camera)
	for item in room.enemies:
		if game.room_index==3 and game.data.boss: continue
		var enemy=Node2D.new()
		enemy.set_script(ENEMY)
		enemy.level=self
		enemy.game=game
		enemy.boss=game.room_index==3
		enemy.position=Vector2(float(item.x)*64,float(item.y)*64)
		actors.add_child(enemy)
		enemies.append(enemy)
	for asset in ["background","terrain","checkpoint","foreground"]:
		var suffix="throat.png" if asset=="background" and game.room_index==4 else asset+".png"
		if ResourceLoader.exists("res://assets/runtime/"+suffix): set(asset,load("res://assets/runtime/"+suffix))
	for i in range(70): motes.append(Vector2(fmod(i*389.7,room_width),fmod(i*151.1,death_y)))
	route_system=load("res://scripts/room_routes.gd").new()
	route_system.name="DoorsAnchorsAndMechanisms"
	scenery.get_node("World").add_child(route_system)
	route_system.setup(self)
	game.record("room_enter",{"id":room.id,"entry":entry})
	if game.room_index==2 and game.data.get("latch",false): open_bridge(true)
	effects=Node2D.new()
	effects.set_script(preload("res://scripts/event_fx.gd"))
	effects.z_index=8
	effects.name="EventEffects"
	scenery.get_node("World").add_child(effects)
	var far=scenery.get_node("Far/FarDrift")
	environment_layers.append(far)
	for mode in [0,1]:
		var layer=Node2D.new()
		layer.set_script(preload("res://scripts/atmosphere.gd"))
		add_child(layer)
		layer.setup(self,mode)
		environment_layers.append(layer)

func _process(delta: float) -> void:
	time+=delta
	if main.scenery_preview:
		camera.position=main.preview_camera
		camera.zoom=Vector2.ONE*minf(1180.0/room_width,540.0/(death_y-30)) if main.preview_fit else Vector2(0.80,0.80)
		if main.preview_fit:camera.position=Vector2(room_width/2,(death_y-30)/2)
		camera.position_smoothing_enabled=false
		return
	feedback_shake=maxf(0,feedback_shake-delta)
	if game.room_index==2 and game.data.get("latch",false): latch_anim=minf(1,latch_anim+delta*2)
	if is_instance_valid(bridge) and latch_anim>=1 and bridge.get_child(0).disabled:
		bridge.get_child(0).set_deferred("disabled",false)
	if not is_instance_valid(player): return
	var focus=Vector2(player.position.x+player.facing*145,player.position.y-200)
	if game.room_index==3 and boss_started and not game.data.boss:
		camera.zoom=Vector2(0.68,0.68)
		focus=Vector2(21*64,14*64-260)
	else: camera.zoom=Vector2.ONE
	camera.position=camera.position.lerp(focus,1.0-exp(-5*delta))
	camera.offset=Vector2(sin(time*145),cos(time*127))*feedback_shake*25
	if game.room_index==3 and player.position.x>7*64 and not game.data.boss: boss_started=true
	queue_redraw()

func safe_at(pos: Vector2) -> bool:
	for p in platforms:
		if pos.x>float(p.x)*64+24 and pos.x<(float(p.x)+float(p.w))*64-24 and absf(pos.y-float(p.y)*64)<8: return true
	return false

func floor_at(pos: Vector2) -> bool:
	for p in platforms:
		if pos.x>float(p.x)*64+15 and pos.x<(float(p.x)+float(p.w))*64-15 and absf(pos.y-float(p.y)*64)<8: return true
	return false

func interact() -> void:
	if main.scenery_preview: return
	if not player.is_on_floor() or player.respawning: return
	var x=player.position.x/64
	if game.room_index in [0,3] and x>=1.5 and x<4.5 and not (boss_started and not game.data.boss) and absf(player.position.y-14*64)<20:
		game.data.checkpoint=game.room_index
		game.hp=4
		game.energy=4
		game.save_game()
		game.record("checkpoint",{"room":game.room_index})
		sfx("save")
		message("营地已记录 · 生命与蓄振恢复")
		return
	if game.room_index==2 and player.position.distance_to(Vector2(24.5,11.3)*64)<80 and not game.data.fragment:
		game.data.fragment=true
		game.save_game()
		game.record("fragment")
		sfx("collect")
		message("获得生命碎片 1/4 · 永久保存")
		return
	if game.room_index==2 and player.position.distance_to(Vector2(24.5,11.3)*64)<80 and not game.data.get("latch",false):
		game.data.latch=true
		game.save_game()
		open_bridge()
		game.record("latch_open",{"id":"R1_03_SHELL_LATCH"})
		message("支路壳闩已开 · 下方短桥接回主路 · 永久保存")
		return
	if game.room_index==3 and game.data.boss and not game.data.dash and x>30 and x<34 and absf(player.position.y-14*64)<20:
		game.data.dash=true
		game.save_game()
		game.record("dash_unlock")
		sfx("collect")
		message("贴流冲已获得 · Shift · 每次离地一次")
		return
	if game.room_index==4 and x>2.5 and x<5 and not game.data.habitat:
		game.data.habitat=true
		game.save_game()
		game.record("habitat")
		sfx("collect")
		message("清流窝已修通 · 幼体开始停靠")
		return
	if route_system.collect_revisit(): return
	route_system.use_door()

func respawn() -> void:
	game.hp=4
	game.energy=4
	main.change_room(int(game.data.checkpoint))
	main.notify("在营地重新出发 · 永久收获仍在")

func message(text: String) -> void: main.notify(text)
func sfx(name: String) -> void: main.sfx(name)

func _draw() -> void:
	if game.room_index in [0,3]: draw_camp(Vector2(2*64,14*64))
	if game.room_index==2 and not game.data.fragment: draw_collect(Vector2(24.5*64,10.5*64),Color("e0ce92"))
	if game.room_index==3 and game.data.boss and not game.data.dash: draw_collect(Vector2(32*64,14*64-65),Color("89edeb"))
	if game.room_index==4:
		for i in range(4): draw_circle(Vector2(4*64+i*10,14*64-20-sin(time+i)*10),4,Color("80caca") if game.data.habitat else Color("5d6c65"))
	if game.room_index==2:
		var origin=Vector2(24.5,11.3)*64
		draw_rect(Rect2(origin-Vector2(15,35),Vector2(30,35)),Color("c49965"))
		draw_line(origin-Vector2(0,25),origin+Vector2(20*latch_anim-15,-60+20*latch_anim),Color("ede0b5"),6)
		if game.data.get("latch",false):
			draw_rect(Rect2(28*64,12.8*64,64*latch_anim,16),Color("79c7bb"))
		else: draw_dashed_line(Vector2(28,12.8)*64,Vector2(29,12.8)*64,Color("927e61"),2,8)
	if game.room_index==3 and boss_started and not game.data.boss:
		for edge in [7.1,35.4]:
			draw_line(Vector2(edge*64,10*64),Vector2(edge*64,14*64),Color(0.65,0.34,0.22,0.5),10,true)

func draw_camp(pos: Vector2) -> void:
	if checkpoint: draw_texture_rect(checkpoint,Rect2(pos-Vector2(70,100),Vector2(140,100)),false)
	else:
		draw_arc(pos+Vector2(0,-30),43,PI,TAU,20,Color("aa997d"),12,true)
		draw_circle(pos+Vector2(0,-28),14,Color("e9b761"))

func draw_door(pos: Vector2, locked: bool) -> void:
	var color=Color("b77c65") if locked else Color("83b8b4")
	draw_arc(pos-Vector2(0,48),41,PI,TAU,20,color,5,true)
	draw_line(pos-Vector2(41,48),pos-Vector2(41,0),color,5)
	draw_line(pos+Vector2(41,-48),pos+Vector2(41,0),color,5)
	if locked: draw_line(pos-Vector2(30,75),pos+Vector2(30,-15),color,5)
	else: draw_circle(pos-Vector2(0,42),8,Color(color,0.55+sin(time*2)*0.2))

func draw_collect(pos: Vector2,color: Color) -> void:
	draw_circle(pos+Vector2(0,sin(time*2)*5),12,color)
	draw_arc(pos,23,0,TAU,24,Color(color,0.35),2,true)

func interaction_hint() -> String:
	if main.scenery_preview: return "巡览镜头 · WASD 平移 · 数字 1–7 切房 · Tab 全景位置 · F6 返回游戏"
	if not player.is_on_floor(): return ""
	var x=player.position.x/64

	if game.room_index in [0,3] and x>=1.5 and x<4.5 and not (boss_started and not game.data.boss): return "E · 营地记录 / 恢复"
	if game.room_index==2 and not game.data.fragment and player.position.distance_to(Vector2(24.5,11.3)*64)<80: return "E · 拾取生命碎片"
	if game.room_index==2 and not game.data.get("latch",false) and player.position.distance_to(Vector2(24.5,11.3)*64)<80: return "E · 拉动支路壳闩"
	if game.room_index==3 and game.data.boss and not game.data.dash and x>30 and x<34: return "E · 承接贴流冲"
	if game.room_index==4 and not game.data.habitat and x>2.5 and x<5: return "E · 清理育窝"
	if game.room_index>=5:
		for reward in room.rewards:
			if player.position.distance_to(Vector2(reward.x,reward.y)*64)<100:return "E · 领取回访奖励"
	var door=route_system.nearest_door()
	if not door.is_empty():
		var reason=route_system.denied(door)
		return "E · "+str(door.to) if reason=="" else reason
	if main.route_sandbox:return "回访验证 · W 浮升（落台补压） · J 挂环/换环 · Space 脱环 · E 房门"
	return ""

func open_bridge(instant: bool=false) -> void:
	if is_instance_valid(bridge): return
	if instant:latch_anim=1.0
	bridge=StaticBody2D.new()
	bridge.collision_layer=1
	bridge.position=Vector2(28,12.8)*64
	var shape=RectangleShape2D.new()
	shape.size=Vector2(64,16)
	var c=CollisionShape2D.new()
	c.shape=shape
	c.disabled=not instant
	c.position=Vector2(32,8)
	bridge.add_child(c)
	add_child(bridge)
	platforms.append({"id":"BRIDGE","x":28,"y":12.8,"w":1})

func emit_fx(kind: String,at: Vector2,direction: float=1.0) -> void:
	if is_instance_valid(effects): effects.emit(kind,at,direction)
	main.effect_counts[kind]=int(main.effect_counts.get(kind,0))+1
	if kind=="hit": feedback_shake=0.10
	if kind=="land": emit_water_ripple(at)

func emit_water_ripple(foot: Vector2) -> void:
	# Landing shakes a nearby visible strip below the platform. This is an
	# environment response, not a water volume or a swimming mechanic.
	if not is_instance_valid(effects) or environment_layers.size()<3: return
	var front=environment_layers[2]
	if not front.textures.has("water"): return
	for p in platforms:
		if not str(p.id).begins_with("P"): continue
		var x=float(p.x)*64+32
		var y=float(p.y)*64
		if game.room_index==3 and x>400 and x<2000: continue
		var width=minf(240,float(p.w)*64-25)
		var local_x=foot.x-(x-15)
		if absf(foot.y-y)>8 or local_x<0 or local_x>width: continue
		# Same centerline equation as atmosphere.draw_foreground().
		var surface=Vector2(foot.x,y+225+sin(local_x*0.045-front.elapsed*2.1)*2.5)
		effects.emit("ripple",surface)
		main.effect_counts["ripple"]=int(main.effect_counts.get("ripple",0))+1
		return

