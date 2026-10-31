extends CharacterBody2D

const U=64.0
var game: Node
var level: Node
var facing := 1.0
var time := 0.0
var grounded_time := 0.0
var jump_buffer := 0.0
var invulnerable := 0.0
var attack_time := -1.0
var attack_kind := ""
var attack_id := 0
var combo := false
var attack_hit: Array = []
var heal_time := -1.0
var dash_time := 0.0
var dash_cooldown := 0.0
var air_dash := false
var lamp := true
var last_safe := Vector2.ZERO
var respawning := false
var sprite: Sprite2D
var anim_assets: Dictionary = {}
var anim_name := "idle"
var hurt_time := 0.0
var qa := false
var float_pressure:=1.35
var anchor_index:=-1
var last_anchor_index:=-1
var anchor_arrived:=false
var attack_fx_sent:=false
var was_grounded:=false
var lamp_light: PointLight2D

func _ready() -> void:
	collision_layer=2
	collision_mask=1
	var c := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius=17
	shape.height=61
	c.shape=shape
	c.position=Vector2(0,-30.5)
	add_child(c)
	sprite=Sprite2D.new()
	sprite.position=Vector2(0,-35)
	add_child(sprite)
	lamp_light=PointLight2D.new()
	var gradient=Gradient.new()
	gradient.colors=PackedColorArray([Color(1,1,1,0.7),Color(1,1,1,0)])
	var glow=GradientTexture2D.new()
	glow.width=128
	glow.height=128
	glow.gradient=gradient
	glow.fill=GradientTexture2D.FILL_RADIAL
	glow.fill_from=Vector2(0.5,0.5)
	glow.fill_to=Vector2(1,0.5)
	lamp_light.texture=glow
	lamp_light.texture_scale=1.2
	lamp_light.color=Color("edb65b")
	lamp_light.energy=0.25
	add_child(lamp_light)
	for state in ["idle","run","jump","attack","heavy","hit","dash","heal"]:
		var files: Array = []
		for i in range(8):
			var f="res://assets/runtime/hero/"+state+"_"+str(i)+".png"
			if ResourceLoader.exists(f): files.append(load(f))
		if files.size()>0: anim_assets[state]=files

func _physics_process(delta: float) -> void:
	if respawning: return
	time+=delta
	invulnerable=maxf(0,invulnerable-delta)
	hurt_time=maxf(0,hurt_time-delta)
	dash_cooldown=maxf(0,dash_cooldown-delta)
	if is_on_floor():
		float_pressure=1.35
		last_anchor_index=-1
		grounded_time=0.1
		air_dash=false
		if level.safe_at(position): last_safe=position
	else: grounded_time=maxf(0,grounded_time-delta)
	jump_buffer=maxf(0,jump_buffer-delta)
	if Input.is_action_just_pressed("jump"): jump_buffer=0.12
	if Input.is_action_just_pressed("lamp"):
		lamp=not lamp
		game.record("lamp",{"on":lamp})
	if Input.is_action_just_pressed("interact"): level.interact()
	if Input.is_action_just_pressed("attack") and anchor_index<0:
		if attack_time<0 and heal_time<0 and dash_time<=0: begin_attack("short1")
		elif attack_kind=="short1" and attack_time>=0.30: combo=true
	if Input.is_action_just_pressed("heavy") and anchor_index<0 and attack_time<0 and heal_time<0 and dash_time<=0 and game.energy>=2:
		game.energy-=2
		begin_attack("heavy")
	if Input.is_action_just_pressed("heal") and is_on_floor() and game.hp<4 and game.energy>=2 and attack_time<0 and heal_time<0 and dash_time<=0:
		game.energy-=2
		heal_time=0
		game.record("heal_start")
	if heal_time>=0:
		heal_time+=delta
		if heal_time>=1.1:
			game.hp=mini(4,game.hp+1)
			heal_time=-1
			game.record("heal_complete")
			level.sfx("heal")
	var axis=Input.get_axis("left","right")
	if axis!=0 and attack_time<0 and dash_time<=0: facing=signf(axis)
	if Input.is_action_just_pressed("dash") and game.data.dash and dash_cooldown<=0 and not air_dash and heal_time<0 and attack_time<0:
		dash_time=0.22
		dash_cooldown=0.8
		air_dash=true
		level.sfx("dash")
		level.emit_fx("dash",position-Vector2(0,30),facing)
		game.record("dash",{"x":position.x,"grounded":is_on_floor()})
	if jump_buffer>0 and grounded_time>0 and heal_time<0 and dash_time<=0:
		velocity.y=-460
		grounded_time=0
		jump_buffer=0
		level.sfx("jump")
		level.emit_fx("jump",position)
		game.record("jump",{"x":position.x})
	if dash_time>0:
		dash_time-=delta
		velocity=Vector2(facing*2.6*U/0.22,0)
	else:
		velocity.y=minf(850,velocity.y+1000*delta)
		if hurt_time<=0:
			velocity.x=axis*204.8 if heal_time<0 else 0.0
			if attack_time>=0: velocity.x*=0.55
	if Input.is_action_just_pressed("anchor") and level.route_system.has_ability("A3"):
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
	move_and_slide()
	if is_on_floor() and not was_grounded: level.emit_fx("land",position)
	was_grounded=is_on_floor()
	if position.y>level.death_y: fall_recover()
	position.x=clampf(position.x,20,level.room_width-20)
	if game.room_index==3 and level.boss_started and not game.data.boss:
		position.x=clampf(position.x,7.2*U,35.3*U)
	update_attack(delta)
	update_visual(delta)
	queue_redraw()

func begin_attack(kind: String) -> void:
	attack_kind=kind
	attack_time=0
	attack_id+=1
	attack_hit=[]
	attack_fx_sent=false
	combo=false
	level.sfx("heavy" if kind=="heavy" else "strike")
	game.record("attack",{"kind":kind})

func update_attack(delta: float) -> void:
	if attack_time<0: return
	attack_time+=delta
	var start=0.30 if attack_kind=="heavy" else (0.16 if attack_kind=="short2" else 0.12)
	var active=0.12 if attack_kind=="heavy" else 0.08
	var duration=0.82 if attack_kind=="heavy" else (0.50 if attack_kind=="short2" else 0.40)
	if attack_time>=start and attack_time<start+active:
		if not attack_fx_sent:
			if attack_kind=="heavy": level.emit_fx("heavy",position-Vector2(0,33),facing)
			attack_fx_sent=true
		var reach=2.4*U if attack_kind=="heavy" else 1.3*U
		for enemy in level.enemies:
			if not is_instance_valid(enemy) or enemy.dead or enemy in attack_hit: continue
			var dx=enemy.position.x-position.x
			if dx*facing>=-15 and absf(dx)<reach+enemy.radius and absf(enemy.position.y-position.y)<75:
				attack_hit.append(enemy)
				var damage=24 if attack_kind=="heavy" else (14 if attack_kind=="short2" else 10)
				enemy.take_hit(damage,attack_kind=="heavy")
	if attack_time>=duration:
		if attack_kind=="short1" and combo: begin_attack("short2")
		else: attack_time=-1

func take_hit(from_x: float) -> void:
	if invulnerable>0 or respawning: return
	if dash_time>0.06 and dash_time<0.16:
		game.record("dash_evade")
		return
	game.hp-=1
	invulnerable=1
	hurt_time=0.18
	heal_time=-1
	attack_time=-1
	velocity=Vector2(signf(position.x-from_x)*140,-130)
	game.record("hurt",{"hp":game.hp})
	level.sfx("hurt")
	level.emit_fx("hit",position-Vector2(0,30))
	if game.hp<=0:
		respawning=true
		game.deaths+=1
		game.record("death")
		level.emit_fx("death",position-Vector2(0,30))
		get_tree().create_timer(0.30,false).timeout.connect(level.respawn)

func fall_recover() -> void:
	anchor_index=-1
	position=last_safe
	velocity=Vector2.ZERO
	invulnerable=1
	game.record("fall_recover",{"x":position.x})
	if game.room_index in [1,2]:
		game.hp-=1
		if game.hp<=0:
			respawning=true
			game.deaths+=1
			game.record("death",{"cause":"fall"})
			level.emit_fx("death",position-Vector2(0,30))
			get_tree().create_timer(0.30,false).timeout.connect(level.respawn)

func update_visual(_delta: float) -> void:
	lamp_light.position=Vector2(-facing*12,-22)
	lamp_light.energy=(0.25+sin(time*2)*0.03) if lamp else 0.0
	anim_name="idle"
	if absf(velocity.x)>20: anim_name="run"
	if not is_on_floor(): anim_name="jump"
	if attack_time>=0: anim_name="heavy" if attack_kind=="heavy" else "attack"
	if heal_time>=0: anim_name="heal"
	if dash_time>0: anim_name="dash"
	if hurt_time>0: anim_name="hit"
	sprite.visible=anim_assets.has(anim_name)
	if sprite.visible:
		var frames: Array=anim_assets[anim_name]
		var clock=time*9
		if anim_name in ["attack","heavy"]:
			var active_start=0.30 if attack_kind=="heavy" else (0.16 if attack_kind=="short2" else 0.12)
			clock=0 if attack_time<active_start else (1 if attack_time<active_start+0.14 else 2)
		sprite.texture=frames[int(clock)%frames.size()]
		sprite.scale=Vector2(facing*0.28,0.28)
		sprite.position.y=-35.28
		if anim_name=="run": sprite.position.y-=absf(sin(time*9*PI))*2.0
		if anim_name=="idle": sprite.position.y-=sin(time*2)*0.5
		sprite.modulate=Color(1,1,1,0.45 if invulnerable>0 and sin(time*35)>0 else 1)

func choose_anchor() -> void:
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
	if not sprite.visible:
		draw_circle(Vector2(0,-46),18,Color("e5dac2"))
		draw_circle(Vector2(facing*8,-46),10,Color("182e38"))
		draw_colored_polygon(PackedVector2Array([Vector2(-15,-28),Vector2(12,-28),Vector2(19,-6),Vector2(-23,-6)]),Color("246879"))
		draw_line(Vector2(-8,-8),Vector2(-10,0),Color("b7bfae"),8)
		draw_line(Vector2(7,-8),Vector2(12,0),Color("b7bfae"),8)
		draw_circle(Vector2(-facing*10,-17),6,Color("f4b953"))
	if lamp: draw_circle(Vector2(-facing*12,-22),14,Color(1,0.65,0.18,0.09))
	if attack_time>=0:
		var start=0.30 if attack_kind=="heavy" else (0.16 if attack_kind=="short2" else 0.12)
		if attack_time>=start and attack_time<start+0.14:
			var reach=135 if attack_kind=="heavy" else 75
			draw_arc(Vector2(0,-33),reach,-0.65+(PI if facing<0 else 0),0.65+(PI if facing<0 else 0),18,Color(0.6,0.96,0.94,0.85),4,true)
	if heal_time>=0: draw_arc(Vector2(0,-25),42,-PI/2,-PI/2+TAU*heal_time/1.1,30,Color("e9be75"),3,true)
