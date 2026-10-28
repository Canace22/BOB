extends Node2D

var level: Node
var game: Node
var boss := false
var hp := 30
var radius := 30.0
var state := "idle"
var timer := 0.0
var kind := "sweep"
var facing := -1.0
var dead := false
var attack_count := 0
var damaged := false
var earned := false
var hit_flash := 0.0
var stagger_cooldown := 0.0
var origin := 0.0
var sprite: Sprite2D
var texture: Texture2D

func _ready() -> void:
	origin=position.x
	if boss:
		hp=180
		radius=60
	var f="res://assets/runtime/"+("boss.png" if boss else "crab.png")
	if ResourceLoader.exists(f): texture=load(f)

func _physics_process(delta: float) -> void:
	if dead: return
	timer+=delta
	hit_flash=maxf(0,hit_flash-delta)
	stagger_cooldown=maxf(0,stagger_cooldown-delta)
	var player=level.player
	var dx=player.position.x-position.x
	if state=="idle":
		facing=signf(dx)
		var close=absf(dx)<(145 if boss else 85)
		var same_floor=absf(player.position.y-position.y)<120
		if boss and not level.boss_started: return
		if absf(dx)<500 and same_floor:
			if not close:
				var next=position.x+facing*(78 if boss else 48)*delta
				if level.floor_at(Vector2(next,position.y)): position.x=next
			elif timer>0.45: start_tell("slam" if boss and attack_count%3==2 else "sweep")
	elif state=="tell":
		var tell=1.1 if kind=="slam" else (0.55 if kind=="second" else 0.8)
		if timer>=tell:
			state="active"
			timer=0
			damaged=false
			level.sfx("slam" if kind=="slam" else "sweep")
	elif state=="active":
		var range_x=190 if boss and kind=="slam" else (175 if boss else 100)
		var above=position.y-player.position.y
		if not damaged and absf(dx)<range_x and dx*facing>-radius and above< (125 if kind=="slam" else 28) and above>-60:
			var before=game.hp
			player.take_hit(position.x)
			if game.hp!=before: damaged=true
		if timer>0.18:
			if boss and hp<=90 and kind=="sweep": start_tell("second")
			else:
				state="recover"
				timer=0
	elif state=="recover":
		if timer> (1.0 if kind=="slam" else 0.75):
			state="idle"
			timer=0
	elif state=="stagger" and timer>0.12:
		state="idle"
		timer=0
	queue_redraw()

func start_tell(attack: String) -> void:
	kind=attack
	state="tell"
	timer=0
	attack_count+=1
	game.record("enemy_tell",{"boss":boss,"kind":kind})

func take_hit(damage: int, heavy: bool) -> void:
	if dead: return
	hp-=damage
	hit_flash=0.12
	level.sfx("hit")
	game.record("enemy_hit",{"boss":boss,"hp":hp,"heavy":heavy})
	if boss:
		if not heavy:
			game.hits_on_boss+=1
			if game.hits_on_boss%6==0: game.energy=mini(4,game.energy+1)
	elif not earned:
		earned=true
		game.energy=mini(4,game.energy+1)
	if not boss and stagger_cooldown<=0:
		state="stagger"
		timer=0
		stagger_cooldown=0.8
	if hp<=0:
		dead=true
		state="dead"
		if boss:
			game.data.boss=true
			game.save_game()
			game.record("boss_defeated")
			level.message("负壳蟹退让了。前往右侧，按 E 承接贴流冲。")
	queue_redraw()

func _draw() -> void:
	var size=Vector2(210,155) if boss else Vector2(96,70)
	var tint=Color(0.32,0.37,0.38,0.7) if dead else Color.WHITE
	if hit_flash>0: tint=Color(2,1.4,0.9)
	var pulse=sin(timer*4)*2 if state=="idle" else 0.0
	if texture:
		var tilt=-0.08*facing if state=="tell" else (0.12*facing if state=="active" else 0.0)
		var push=facing*15 if state=="active" else 0.0
		draw_set_transform(Vector2(push,pulse),tilt,Vector2(facing,1))
		draw_texture_rect(texture,Rect2(Vector2(-size.x/2,-size.y),size),false,tint)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_circle(Vector2(0,-radius*0.65),radius,Color("806d5c")*tint)
		for i in range(3):
			draw_line(Vector2(-radius/2,-15),Vector2(-radius-10+i*12,0),Color("d3c5a2"),5)
			draw_line(Vector2(radius/2,-15),Vector2(radius+10-i*12,0),Color("d3c5a2"),5)
		draw_circle(Vector2(facing*(radius+10),-40),radius*0.4,Color("bba984"))
	if dead: return
	if state=="tell":
		var range_x=190 if boss and kind=="slam" else (175 if boss else 100)
		var color=Color(1,0.65,0.25,0.6+sin(timer*20)*0.2)
		draw_line(Vector2(0,-4),Vector2(facing*range_x,-4),color,3)
		draw_arc(Vector2(facing*(radius+6),-size.y*0.65),18+timer*12,0,TAU,24,color,3,true)
	if state=="active":
		draw_line(Vector2(0,-10),Vector2(facing*(175 if boss else 100),-10),Color(1,0.65,0.4,0.65),12)
