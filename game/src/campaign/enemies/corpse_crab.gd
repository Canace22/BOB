class_name CampaignCorpseCrab
extends CharacterBody2D
## Ordinary R1 crab: explicit animation, interruptible low sweep, shared campaign damage.

const TIMES := {"tell":.7,"active":.2,"recover":1.1,"hurt":.22}
const HIT_TIME := .06
var host: Node2D
var data: Dictionary
var target: WhalebellyCampaignPlayer
var visual: CorpseCrabVisual
var dust: Sprite2D
var state := "idle"
var timer := 0.0
var facing := -1.0
var hit_sent := false
var attack_serial := 0
var moving := false
var walk_distance := 0.0
var idle_clock := 0.0
var flash := 0.0
var dust_age := 1.0
var home_x := 0.0
var turn_wait := 0.0
var body: CollisionShape2D

func _ready() -> void:
	name = "CorpseCrab" + str(data.key).replace(":","_")
	position = data.pos
	home_x = position.x
	z_index = 3
	collision_layer = 4
	collision_mask = 1
	add_to_group("tide_targets")
	target = host.player
	body = CollisionShape2D.new()
	body.name = "Body"
	var shape := CapsuleShape2D.new()
	shape.radius = 22
	shape.height = 56
	body.shape = shape
	body.position.y = -28
	add_child(body)
	data.actor = self
	data.visual = self
	visual = CorpseCrabVisual.new()
	visual.name = "Visual"
	add_child(visual)
	dust = Sprite2D.new()
	dust.texture = preload("res://art/enemies/crab_video/impact_dust.png")
	dust.hframes = 4
	dust.top_level = true
	dust.z_as_relative = false
	dust.z_index = 4
	dust.hide()
	add_child(dust)
	_sync()

func _physics_process(dt: float) -> void:
	var paused_view: bool = host.reference_visible or host.layer_solo >= 0 or not host.capture_path.is_empty()
	visual.visible = not paused_view
	if paused_view or not target.controls_enabled:
		dust.hide()
		return
	flash = maxf(0,flash-dt)
	idle_clock += dt
	dust_age += dt
	dust.visible = dust_age < .28
	dust.frame = mini(3,int(dust_age/.07))
	dust.modulate.a = clampf((.28-dust_age)/.2,0,.5)
	var start := position
	velocity.x = 0
	if state == "dead":
		timer += dt
		moving = false
	else:
		velocity.y = minf(velocity.y + 1000*dt,700)
		if target.health > 0:
			if state == "idle": _decide(dt)
			else: advance_action(dt)
		if state != "dead": move_and_slide()
		moving = state == "idle" and absf(position.x-start.x) > .01
		if moving: walk_distance += absf(position.x-start.x)
	_sync()
	visual.present(self)

func _decide(dt: float) -> void:
	timer += dt
	turn_wait = maxf(0,turn_wait-dt)
	var offset := target.position-position
	var same_level := absf(offset.y) < 78
	if same_level and absf(offset.x) < 110:
		facing = 1 if offset.x >= 0 else -1
		attack_serial += 1
		change("tell")
		return
	if turn_wait > 0: return
	if same_level and absf(offset.x) < 500: facing = signf(offset.x)
	var next_x := position.x+facing*18
	if absf(next_x-home_x)>110 or not floor_ahead(next_x):
		facing *= -1
		turn_wait = .45
		return
	velocity.x = facing*(45.0 if same_level and absf(offset.x)<500 else 28.0)

func floor_ahead(x: float) -> bool:
	var probe := PhysicsRayQueryParameters2D.create(Vector2(x,position.y-30),Vector2(x,position.y+38),1)
	return not get_world_2d().direct_space_state.intersect_ray(probe).is_empty()

func advance_action(dt: float) -> void:
	# Consume every crossed point even when one tick skips an entire short active window.
	var remaining := dt
	for guard in 5:
		if not TIMES.has(state) or remaining <= 0: break
		var duration: float = TIMES[state]
		var step := minf(remaining,maxf(0,duration-timer))
		var before := timer
		timer += step
		remaining -= step
		if state == "active" and not hit_sent and before < HIT_TIME and timer >= HIT_TIME:
			_sweep()
		if timer + .000001 < duration: break
		match state:
			"tell":
				change("active")
				host.record_event("enemy_attack_active",{"id":data.key,"kind":"corpse_sweep","instance":attack_serial})
			"active": change("recover")
			_: change("idle")

func _sweep() -> void:
	hit_sent = true
	host.sfx("sweep")
	dust_age = 0
	dust.global_position = global_position+Vector2(facing*82,-12)
	dust.scale = Vector2(facing*.24,.24)
	var player_rect := Rect2(target.global_position-Vector2(14,65),Vector2(28,65))
	var query := PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-20),target.global_position+Vector2(0,-20),1)
	if attack_rect().intersects(player_rect) and get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		target.take_damage(1,global_position)

func attack_rect() -> Rect2:
	return Rect2(global_position+Vector2(14 if facing>0 else -110,-34),Vector2(96,32))

func change(next: String) -> void:
	state = next
	timer = 0
	if next == "tell": hit_sent = false
	if next in ["hurt","dead"]:
		hit_sent = true
		dust_age = 1
		if is_instance_valid(dust): dust.hide()

func can_receive_hit() -> bool: return data.alive
func is_campaign_enemy() -> bool: return true
func hurt_rect() -> Rect2:
	return Rect2(global_position-Vector2(32,68),Vector2(72,68)) if data.alive else Rect2()

func take_hit(amount: int) -> void:
	if data.alive and amount > 0: host.damage_enemy(data,amount)

func on_damaged() -> void:
	if not data.alive: return
	flash = .18
	change("hurt")
	velocity.x = 0
	_sync()

func apply_knockback(impulse: float) -> void:
	if not data.alive: return
	var movement := Vector2(clampf(impulse*.12,-24,24),0)
	if floor_ahead(position.x+movement.x): move_and_collide(movement)
	_sync()

func on_defeated() -> void:
	change("dead")
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	body.set_deferred("disabled",true)
	remove_from_group("tide_targets")
	_sync()

func _sync() -> void:
	data.merge({"pos":position,"state":state,"timer":timer,"facing":facing,"hit_sent":hit_sent},true)

func snapshot() -> Dictionary:
	return {"type":"corpse-crab","state":state,"timer":timer,"facing":facing,"hp":data.hp,
		"animation":visual.action_id,"frame":visual.frame_index,"attack_instance":attack_serial,
		"hit_sent":hit_sent,"moving":moving,"walk_distance":walk_distance,"collidable":collision_layer!=0}
