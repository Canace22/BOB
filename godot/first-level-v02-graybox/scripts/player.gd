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
	if Input.is_action_just_pressed("attack"):
		if attack_time<0 and heal_time<0 and dash_time<=0: begin_attack("short1")
		elif attack_kind=="short1" and attack_time>=0.30: combo=true
	if Input.is_action_just_pressed("heavy") and attack_time<0 and heal_time<0 and dash_time<=0 and game.energy>=2:
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
		game.record("dash",{"x":position.x,"grounded":is_on_floor()})
	if jump_buffer>0 and grounded_time>0 and heal_time<0 and dash_time<=0:
		velocity.y=-460
		grounded_time=0
		jump_buffer=0
		level.sfx("jump")
		game.record("jump",{"x":position.x})
	if dash_time>0:
		dash_time-=delta
		velocity=Vector2(facing*2.6*U/0.22,0)
	else:
		velocity.y=minf(850,velocity.y+1000*delta)
		if hurt_time<=0:
			velocity.x=axis*204.8 if heal_time<0 else 0.0
			if attack_time>=0: velocity.x*=0.55
	move_and_slide()
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
	if game.hp<=0:
		respawning=true
		game.deaths+=1
		game.record("death")
		level.call_deferred("respawn")

func fall_recover() -> void:
	position=last_safe
	velocity=Vector2.ZERO
	invulnerable=1
	game.record("fall_recover",{"x":position.x})
	if game.room_index in [1,2]:
		game.hp-=1
		if game.hp<=0:
			respawning=true
			game.deaths+=1
			level.call_deferred("respawn")

func update_visual(_delta: float) -> void:
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

func _draw() -> void:
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
