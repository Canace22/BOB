extends CharacterBody2D

const IDLE_FRAMES: SpriteFrames = preload("res://assets/runtime/tide-picker-idle-v03/idle.tres")
const IDLE_PIVOT := Vector2(128, 300)
const IDLE_ART_HEIGHT := 261.0

var host: Node2D
var facing: float = 1.0
var attack_timer: float = 0.0
var attack_cooldown: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var invulnerable: float = 0.0
var float_left: float = 1.5
var coyote: float = 0.0
var jump_buffer: float = 0.0
var clock: float = 0.0
var last_safe: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var art: Node2D
var idle_sprite: AnimatedSprite2D
var frames: Dictionary = {}
var frame_anchors: Dictionary = {}
var visual_scale: float = 0.4
var hurt_timer: float = 0.0
var visual_state: String = "idle"
var drop_timer: float = 0.0
var qa_axis: float = 0.0
var qa_mode: bool = false
var grapple_target: Vector2 = Vector2.INF

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(55)
	floor_snap_length = 24.0
	var shape: CapsuleShape2D = CapsuleShape2D.new()
	shape.radius = 14.0
	shape.height = 65.0
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = shape
	collider.position.y = -32.5
	add_child(collider)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.visible = art == null
	add_child(sprite)
	var target_height: float = 94.0
	for actor: Dictionary in host.room.get("actors",[]):
		if actor.get("name","") == "PlayerArt":
			var top: float = 100000.0
			var bottom: float = -100000.0
			for vertex: Array in actor.get("shape",[]):
				top = minf(top,float(vertex[1]))
				bottom = maxf(bottom,float(vertex[1]))
			if bottom > top: target_height = clampf(bottom-top,80.0,110.0)
	for state: String in ["idle", "run", "jump", "attack", "dash", "hit"]:
		var list: Array = []
		for i: int in range(8):
			var path: String = "res://assets/runtime/hero/%s_%d.png" % [state, i]
			if ResourceLoader.exists(path):
				var texture: Texture2D = load(path)
				list.append(texture)
				var bounds: Rect2i = texture.get_image().get_used_rect()
				frame_anchors[path] = Vector2(-texture.get_width()*0.5,-bounds.end.y)
				if state == "idle" and i == 0: visual_scale = target_height/maxf(float(bounds.size.y),1.0)
		if not list.is_empty(): frames[state] = list
	idle_sprite = AnimatedSprite2D.new()
	idle_sprite.name = "IdleAnimation"
	idle_sprite.sprite_frames = IDLE_FRAMES
	idle_sprite.centered = false
	idle_sprite.offset = -IDLE_PIVOT
	idle_sprite.scale = Vector2.ONE * target_height / IDLE_ART_HEIGHT
	idle_sprite.visible = false
	add_child(idle_sprite)
	last_safe = position

func _physics_process(dt: float) -> void:
	if host.reference_visible or host.layer_solo >= 0:
		if idle_sprite != null: idle_sprite.pause()
		if host.reference_visible: update_art()
		return
	clock += dt
	if drop_timer>0.0:
		drop_timer=maxf(0.0,drop_timer-dt)
		if drop_timer<=0.0: collision_mask=1
	invulnerable = maxf(0.0, invulnerable - dt)
	hurt_timer = maxf(0.0,hurt_timer-dt)
	attack_timer = maxf(0.0, attack_timer - dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	if is_on_floor():
		coyote = 0.12
		float_left = 1.5
		if position.y < float(host.room.size[1]) - 65 and stable_floor_point(): last_safe = position
	else: coyote = maxf(0.0, coyote - dt)
	jump_buffer = maxf(0.0, jump_buffer - dt)
	if Input.is_action_just_pressed("jump"):
		var mechanism: Node = host.scenery.get_node_or_null("VisualMechanisms")
		var soft_zone: bool = host.room_index==2 and position.x>700 and position.x<970 and position.y<730 and is_on_floor()
		if Input.is_action_pressed("down") and soft_zone and mechanism!=null and float(mechanism.membrane_drop)>15.0:
			drop_timer=0.28
			collision_mask=0
			velocity.y=180.0
			jump_buffer=0.0
			coyote=0.0
			host.record_event("membrane_dive", {"position":[position.x,position.y],"drop":mechanism.membrane_drop})
			host.sfx("sweep")
		else: jump_buffer = 0.12
	if jump_buffer > 0.0 and coyote > 0.0:
		var rebound: bool = host.room_index==2 and position.x>700 and position.x<970 and position.y>730
		velocity.y = -670.0 if rebound else -570.0
		if rebound: host.record_event("membrane_rebound", {"position":[position.x,position.y]})
		host.sfx("jump")
		host.record_event("jump")
		jump_buffer = 0.0
		coyote = 0.0
	var axis: float = qa_axis if qa_mode else Input.get_axis("left", "right")
	if absf(axis) > 0.1: facing = signf(axis)
	if Input.is_action_just_pressed("dash") and not host.has_ability("dash"):
		host.notify("冲刺尚未解锁：击败负壳守卫获得；F9 可进入临时练习")
	if Input.is_action_just_pressed("float") and not host.has_ability("float"):
		host.notify("浮游属于后续回访能力；F9 练习模式可检验上层路线")
	if Input.is_action_just_pressed("grapple") and not host.has_ability("anchor"):
		host.notify("锚环属于后续回访能力；F9 练习模式可检验记忆袋支路")
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and host.has_ability("dash"):
		dash_timer = 0.20
		host.sfx("dash")
		host.record_event("dash")
		dash_cooldown = 0.7
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		attack_timer = 0.28
		attack_cooldown = 0.38
		host.attack(position, facing)
	if Input.is_action_just_pressed("grapple") and host.has_ability("anchor"):
		var distance: float = 390.0
		var chosen: Vector2 = Vector2.INF
		for point: Variant in host.room.get("rings", []):
			var target: Vector2 = Vector2(float(point[0]), float(point[1])) + Vector2(0, 55)
			if position.distance_to(target) < distance and position.distance_to(target) > 90 and (target.x-position.x)*facing > -35:
				distance = position.distance_to(target)
				chosen = target
		if chosen != Vector2.INF:
			grapple_target = chosen
			host.record_event("anchor", {"target":[chosen.x,chosen.y]})
	if grapple_target != Vector2.INF:
		velocity = position.direction_to(grapple_target) * 640.0
		if position.distance_to(grapple_target) < 24.0:
			grapple_target = Vector2.INF
			velocity.y = -340.0
			float_left = 1.5
	elif dash_timer > 0.0:
		dash_timer -= dt
		velocity = Vector2(facing * 800.0, 0.0)
	else:
		velocity.x = move_toward(velocity.x, axis * 265.0, 1800.0 * dt)
		velocity.y = minf(velocity.y + 1050.0 * dt, 850.0)
		if Input.is_action_pressed("float") and host.has_ability("float") and not is_on_floor() and float_left > 0.0 and velocity.y > -160.0:
			float_left -= dt
			velocity.y = move_toward(velocity.y, -160.0, 2200.0 * dt)
	move_and_slide()
	var right_limit: float = 1460.0 if host.room_index==6 else float(host.room.size[0])-18.0
	position.x = clampf(position.x,18.0,right_limit)
	for bed: Dictionary in host.room.get("soft_beds",[]):
		if position.x>float(bed["from"]) and position.x<float(bed.to) and position.y>float(bed.y):
			host.record_event("soft_bed_recover", {"position":[position.x,position.y],"return":[last_safe.x,last_safe.y],"bed":bed})
			hurt(1,true)
			break
	if position.y > float(host.room.size[1]) + 80.0: hurt(1, true)
	if Input.is_action_just_pressed("interact"): host.interact()
	update_art()
	queue_redraw()

func update_art() -> void:
	var state: String = "idle"
	if absf(velocity.x) > 30: state = "run"
	if not is_on_floor(): state = "jump"
	if dash_timer > 0: state = "dash"
	if attack_timer > 0: state = "attack"
	if hurt_timer > 0: state = "hit"
	visual_state = state
	# Reference reconstruction keeps the authored cutout; normal gameplay uses the baked idle.
	var reference_mode: bool = host.reference_visible or not host.capture_path.is_empty()
	var animated_idle: bool = state == "idle" and not reference_mode and idle_sprite != null
	var exact_idle: bool = reference_mode or (state == "idle" and not animated_idle)
	if idle_sprite != null:
		idle_sprite.visible = animated_idle
		idle_sprite.scale.x = absf(idle_sprite.scale.x) * facing
		idle_sprite.modulate.a = 0.45 if invulnerable > 0.0 and sin(clock * 30.0) > 0.0 else 1.0
		if animated_idle:
			if not idle_sprite.is_playing(): idle_sprite.play(&"idle")
		else:
			idle_sprite.stop()
	if art != null:
		art.scale.x = facing
		art.visible = not animated_idle and (exact_idle or not frames.has(state))
		art.modulate.a = 0.45 if invulnerable > 0.0 and sin(clock * 30.0) > 0.0 else 1.0
	if sprite == null or frames.is_empty(): return
	sprite.visible = not animated_idle and (not exact_idle or art == null)
	if not sprite.visible: return
	if not frames.has(state): state = "idle"
	var list: Array = frames.get(state, [])
	if list.is_empty(): return
	var frame_index: int = int(clock*9.0)%list.size()
	if state == "attack": frame_index = clampi(int((0.28-attack_timer)/0.28*list.size()),0,list.size()-1)
	sprite.texture = list[frame_index]
	sprite.offset = frame_anchors.get(sprite.texture.resource_path,Vector2(-192,-270))
	sprite.scale = Vector2(facing*visual_scale,visual_scale)
	sprite.modulate.a = 0.4 if invulnerable > 0.0 and sin(clock * 30.0) > 0.0 else 1.0

func hurt(amount: int, fall: bool = false) -> void:
	if invulnerable > 0.0 and not fall: return
	host.health -= amount
	host.sfx("hurt")
	host.record_event("player_hurt", {"health":host.health,"fall":fall})
	invulnerable = 1.2
	hurt_timer = 0.25
	velocity = Vector2(-facing * 160, -170)
	if host.health <= 0:
		host.health = 5
		host.respawn()
	elif fall:
		position = last_safe
		velocity = Vector2.ZERO
		grapple_target = Vector2.INF
	host.flash = 0.15

func _draw() -> void:
	if attack_timer > 0.0:
		var center: Vector2 = Vector2(facing * 15.0, -45)
		var start: float = -1.4 if facing > 0 else 1.7
		draw_arc(center, 96.0, start, start + 2.8, 20, Color(0.78, 0.96, 1, attack_timer / 0.28), 6.0, true)
	if grapple_target != Vector2.INF:
		draw_line(Vector2(0, -42), grapple_target - position - Vector2(0, 50), Color(0.5, 0.9, 0.95, 0.7), 2.0)

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
