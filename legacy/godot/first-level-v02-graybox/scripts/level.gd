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

func setup(g: Node,m: Node,data: Dictionary,entry: String="left") -> void:
	game=g
	main=m
	room=data
	room_width=float(room.width)*64
	death_y=float(room.height)*64+30
	platforms=room.platforms.filter(func(p):return str(p.id).begins_with("P") or (game.room_index in [2,3] and str(p.id).begins_with("U")))
	for p in platforms:
		var body=StaticBody2D.new()
		body.position=Vector2(float(p.x)*64,float(p.y)*64)
		body.collision_layer=1
		var c=CollisionShape2D.new()
		var shape=RectangleShape2D.new()
		shape.size=Vector2(float(p.w)*64,64)
		c.shape=shape
		c.position=Vector2(shape.size.x/2,32)
		if str(p.id).begins_with("U"):
			c.one_way_collision=true
			c.one_way_collision_margin=6
		body.add_child(c)
		add_child(body)
	player=CharacterBody2D.new()
	player.set_script(PLAYER)
	player.game=game
	player.level=self
	var main_platforms=platforms.filter(func(p):return str(p.id).begins_with("P"))
	var start=main_platforms[-1] if entry=="right" else main_platforms[0]
	player.position=Vector2((float(start.x)+float(start.w)-2 if entry=="right" else 3.0)*64,float(start.y)*64-3)
	if game.room_index==3 and entry=="right": player.position=Vector2(33*64,14*64-3)
	player.last_safe=player.position
	add_child(player)
	camera=Camera2D.new()
	camera.position=Vector2(player.position.x+160,player.position.y-200)
	camera.limit_left=0
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
		add_child(enemy)
		enemies.append(enemy)
	for asset in ["background","terrain","checkpoint","foreground"]:
		var suffix="throat.png" if asset=="background" and game.room_index==4 else asset+".png"
		if ResourceLoader.exists("res://assets/runtime/"+suffix): set(asset,load("res://assets/runtime/"+suffix))
	for i in range(70): motes.append(Vector2(fmod(i*389.7,room_width),fmod(i*151.1,death_y)))
	game.record("room_enter",{"id":room.id,"entry":entry})
	if game.room_index==2 and game.data.get("latch",false): open_bridge()

func _process(delta: float) -> void:
	time+=delta
	if game.room_index==2 and game.data.get("latch",false): latch_anim=minf(1,latch_anim+delta*2)
	if not is_instance_valid(player): return
	var focus=Vector2(player.position.x+player.facing*145,player.position.y-200)
	if game.room_index==3 and boss_started and not game.data.boss:
		camera.zoom=Vector2(0.68,0.68)
		focus=Vector2(21*64,14*64-260)
	else: camera.zoom=Vector2.ONE
	camera.position=camera.position.lerp(focus,1.0-exp(-5*delta))
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
	if x<1.4 and game.room_index>0:
		if game.room_index==3 and boss_started and not game.data.boss:
			message("负壳蟹挡住退路 · 击败它，或暂停后回营地")
			return
		main.change_room(game.room_index-1,"right")
	elif x>float(room.width)-2.7:
		if game.room_index==3 and not game.data.dash:
			message("前路未开 · 击败负壳蟹后在右侧承接能力")
			game.record("gate_denied")
			return
		if game.room_index==4:
			if not game.data.dash: return
			game.data.complete=true
			game.save_game()
			game.record("level_complete")
			sfx("collect")
			main.finish()
		else: main.change_room(game.room_index+1)

func respawn() -> void:
	game.hp=4
	game.energy=4
	main.change_room(int(game.data.checkpoint))
	main.notify("在营地重新出发 · 永久收获仍在")

func message(text: String) -> void: main.notify(text)
func sfx(name: String) -> void: main.sfx(name)

func _draw() -> void:
	var center=camera.position if is_instance_valid(camera) else Vector2(640,500)
	if background:
		draw_texture_rect(background,Rect2(Vector2(center.x*0.88-1100,center.y*0.9-700),Vector2(2400,1500)),false,Color(0.65,0.76,0.8))
	else:
		for i in range(17):
			var x=i*190.0+center.x*0.4
			draw_line(Vector2(x,0),Vector2(x-45,560+sin(i)*90),Color("193b49"),35)
	for p in platforms:
		var x=float(p.x)*64
		var y=float(p.y)*64
		var w=float(p.w)*64
		if not str(p.id).begins_with("U"):
			draw_rect(Rect2(x,y+20,w,death_y-y+250),Color("192e36"))
		if terrain:
			for k in range(ceili(w/256)):
				var width=minf(256,w-k*256)
				draw_texture_rect_region(terrain,Rect2(x+k*256,y-7,width,145),Rect2(0,0,terrain.get_width()*width/256.0,terrain.get_height()))
			draw_line(Vector2(x+3,y+2),Vector2(x+w-3,y+2),Color(0.72,0.76,0.62,0.65),3,true)
		else:
			draw_line(Vector2(x,y),Vector2(x+w,y),Color("b8bca1"),8)
			draw_line(Vector2(x,y+12),Vector2(x+w,y+12),Color("7d5a57"),10)
		for j in range(int(w/45)):
			draw_line(Vector2(x+j*45,y+80),Vector2(x+j*45-10,y+150+sin(j*3)*30),Color(0.12,0.25,0.28,0.6),2)
	if game.room_index in [0,3]: draw_camp(Vector2(2*64,14*64))
	var floor_y=float(platforms[0].y)*64
	if game.room_index>0: draw_door(Vector2(55,floor_y),false)
	var right_y=14*64 if game.room_index in [0,3,4] else 17*64
	if game.room_index==2: right_y=int(float(platforms[4].y)*64)
	draw_door(Vector2(room_width-60,right_y),game.room_index==3 and not game.data.dash)
	if game.room_index==2 and not game.data.fragment: draw_collect(Vector2(24.5*64,11.3*64-45),Color("e0ce92"))
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
	for i in range(motes.size()):
		var pos=motes[i]
		pos.y=fposmod(pos.y-time*(7+i%5),death_y)
		pos.x+=sin(time*0.3+i)*20
		draw_circle(pos,1.2+i%3*0.4,Color(0.6,0.85,0.85,0.14+i%4*0.04))

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
	if not player.is_on_floor(): return ""
	var x=player.position.x/64
	if game.room_index>0 and x<1.4: return "E · 返回上一段"
	if game.room_index in [0,3] and x>=1.5 and x<4.5 and not (boss_started and not game.data.boss): return "E · 营地记录 / 恢复"
	if game.room_index==2 and not game.data.fragment and player.position.distance_to(Vector2(24.5,11.3)*64)<80: return "E · 拾取生命碎片"
	if game.room_index==2 and not game.data.get("latch",false) and player.position.distance_to(Vector2(24.5,11.3)*64)<80: return "E · 拉动支路壳闩"
	if game.room_index==3 and game.data.boss and not game.data.dash and x>30 and x<34: return "E · 承接贴流冲"
	if game.room_index==4 and not game.data.habitat and x>2.5 and x<5: return "E · 清理育窝"
	if x>float(room.width)-2.7: return "E · 前往下一段" if game.room_index<4 else "E · 完成须门遗港"
	return ""

func open_bridge() -> void:
	if is_instance_valid(bridge): return
	bridge=StaticBody2D.new()
	bridge.collision_layer=1
	bridge.position=Vector2(28,12.8)*64
	var shape=RectangleShape2D.new()
	shape.size=Vector2(64,16)
	var c=CollisionShape2D.new()
	c.shape=shape
	c.position=Vector2(32,8)
	bridge.add_child(c)
	add_child(bridge)
	platforms.append({"id":"BRIDGE","x":28,"y":12.8,"w":1})
