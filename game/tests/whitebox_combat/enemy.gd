class_name CombatWhiteboxEnemy
extends Node2D
## 明示判定的测试靶：低扫、长刺、可打断起手与霸体起手。

signal resolved(result: String)
var player: CombatWhiteboxPlayer
var state: String = "idle"
var elapsed: float = 0.0
var mode: int = 0
var facing: float = -1.0
var health: int = 12
var hit_sent: bool = false
var attack_count: int = 0
var hit_count: int = 0
var parry_count: int = 0
var auto_attack: bool = false
var armored: bool = false
var vertical_speed: float = 0.0
var air_lifts: int = 0
var stagger_duration: float = 0.65
var show_debug: bool = false
var action_visual: CombatWhiteboxEnemyVisual
var feedback_stop: float = 0.0
var feedback_age: float = 1.0
var feedback_power: float = 0.0
var feedback_direction: float = 1.0
var feedback_stamp: int = -1
const FLOOR_Y: float = 540.0
const MODES: Array[String] = ["LOW SWEEP", "LONG THRUST"]

func _ready() -> void:
	add_to_group("tide_targets")
	player.skill_effect.connect(_on_effect)
	action_visual = CombatWhiteboxEnemyVisual.new()
	add_child(action_visual)

func begin_attack() -> void:
	if state != "idle" or health <= 0 or position.y < FLOOR_Y: return
	facing = 1.0 if player.position.x > position.x else -1.0
	state = "tell"
	elapsed = 0.0
	hit_sent = false
	attack_count += 1

func _physics_process(dt: float) -> void:
	if feedback_stop > 0.0:
		if Engine.get_physics_frames() != feedback_stamp: feedback_stop = maxf(0.0,feedback_stop-dt)
		return
	feedback_age += dt
	if health <= 0:
		state = "dead"
		queue_redraw()
		return
	elapsed += dt
	if position.y < FLOOR_Y or vertical_speed < 0.0:
		vertical_speed += 1500.0*dt
		position.y += vertical_speed*dt
		if position.y >= FLOOR_Y:
			position.y = FLOOR_Y
			vertical_speed = 0.0
			air_lifts = 0
			state = "down"
			elapsed = 0.0
	match state:
		"idle":
			if auto_attack and player.health > 0 and elapsed >= 0.8 and absf(player.position.x-position.x) < 340:
				begin_attack()
		"tell":
			if elapsed >= 0.7:
				state = "active"
				elapsed = 0.0
		"active":
			if not hit_sent and elapsed >= 0.06:
				hit_sent = true
				if attack_rect().intersects(player_rect()):
					var before: int = parry_count
					if player.take_damage(1,global_position):
						hit_count += 1
						resolved.emit("HIT: player damaged")
					elif before == parry_count:
						resolved.emit("EVADE: invulnerability")
				else: resolved.emit("MISS: spacing / jump / backstep")
			if state == "active" and elapsed >= 0.2:
				state = "recover"
				elapsed = 0.0
		"recover", "stagger", "down":
			if elapsed >= (1.1 if state=="recover" else (0.45 if state=="down" else stagger_duration)):
				state = "idle"
				elapsed = 0.0
	queue_redraw()

func receive_feedback(stop: float, direction: float, power: float) -> void:
	feedback_stop = maxf(feedback_stop,stop)
	feedback_stamp = Engine.get_physics_frames()
	feedback_age = 0.0
	feedback_power = power*0.35 if armored and state in ["tell","active"] else power
	feedback_direction = direction

func clear_feedback() -> void:
	feedback_stop = 0.0
	feedback_age = 1.0
	feedback_power = 0.0

func player_rect() -> Rect2:
	return Rect2(player.global_position-Vector2(14,65),Vector2(28,65))

func attack_rect() -> Rect2:
	var size := Vector2(125,32) if mode==0 else Vector2(300,85)
	return Rect2(global_position+Vector2(0 if facing>0 else -size.x,-size.y),size)

func hurt_rect() -> Rect2:
	return Rect2(global_position-Vector2(23,70),Vector2(46,70))

func can_receive_hit() -> bool:
	return health > 0

func take_hit(amount: int) -> void:
	health = maxi(0,health-amount)
	if state == "tell" and not armored:
		state = "stagger"
		stagger_duration = 0.24
		elapsed = 0.0
		resolved.emit("INTERRUPT: vulnerable windup")
	else:
		resolved.emit("COUNTER HIT" if state in ["recover","stagger","airborne","down"] else "HIT")
		if state == "idle" or (state == "active" and not armored):
			state = "stagger"
			stagger_duration = 0.24
			elapsed = 0.0
	queue_redraw()

func launch(strength: float) -> void:
	if health <= 0 or (armored and state in ["tell","active"]): return
	# 同一轮浮空最多补挑三次，重复挑起递减；落地清零，避免永久浮空。
	if air_lifts >= 3: return
	vertical_speed = -strength/(1.0+float(air_lifts)*0.5)
	air_lifts += 1
	state = "airborne"
	elapsed = 0.0
	resolved.emit("LAUNCH: follow-up window")

func knock_down(_strength: float=0.0) -> void:
	if health <= 0 or (armored and state in ["tell","active"]): return
	if position.y < FLOOR_Y:
		vertical_speed = 600.0
	else:
		state = "down"
		elapsed = 0.0
	resolved.emit("FINISH: knockdown")

func apply_knockback(_force: float) -> void:
	pass

func push_away(source_x: float) -> void:
	if health <= 0 or (armored and state in ["tell","active"]): return
	position.x = clampf(position.x+150.0*(1.0 if global_position.x>=source_x else -1.0),30.0,1250.0)

func pin(seconds: float) -> void:
	if health <= 0 or state == "airborne" or (armored and state in ["tell","active"]): return
	state = "stagger"
	stagger_duration = seconds
	elapsed = 0.0

func _on_effect(key: String,event: String,_origin: Vector2,_direction: float) -> void:
	if key != "parry" or event != "success" or state != "active": return
	parry_count += 1
	state = "stagger"
	stagger_duration = 0.65
	elapsed = 0.0
	resolved.emit("PARRY: counter window 0.65s")

func _draw() -> void:
	if not show_debug: return
	var color := Color("9da6b8")
	if state == "tell": color = Color("ffd270")
	elif state == "active": color = Color("ff6378")
	elif state in ["recover","stagger"]: color = Color("85e0aa")
	elif state == "dead": color = Color("454956")
	draw_rect(Rect2(-23,-70,46,70),color)
	draw_line(Vector2(0,-55),Vector2(facing*35,-55),Color.WHITE,3.0)
	if state in ["tell","active"]:
		var rect: Rect2 = attack_rect()
		rect.position -= global_position
		draw_rect(rect,Color(color,0.15 if state=="tell" else 0.5))
		draw_rect(rect,color,false,2.0)
