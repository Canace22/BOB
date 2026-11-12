class_name KitEncounter
extends WhalebellyCampaignEnemyProxy
## Pattern-driven enemy built from library bitmaps: lane swarms, pearl clams and
## echo membranes. Damage, health bar, defeat and saves stay with the campaign host.
const DEFAULTS: Dictionary = {"rest":2.0, "tell":0.9, "act":1.3, "recover":0.6, "radius":80.0, "engage":900.0, "speed":360.0, "shots":1, "count":16}
var config: Dictionary
var kind: String = "swarm"
var state: String = "rest"
var timer: float = 0.0
var flash: float = 0.0
var body: Node2D
var marks: Array[Sprite2D] = []
var shots: Array[Dictionary] = []
var start: Vector2
var goal: Vector2
var target_point: Vector2
var hit_sent: bool = false
var repeats_left: int = 0
var fading: bool = false

func _ready() -> void:
	config = data.config
	kind = str(config.kind)
	data.max_hp = int(config.hits)
	data.hp = int(config.hits)
	data.actor = self
	super._ready()
	name = "KitEncounter_" + str(data.key).replace(":", "_")
	z_index = 3
	if kind == "swarm":
		var swarm := KitSwarmVisual.new()
		swarm.texture = load(str(config.sprites.body.path))
		swarm.member_scale = float(config.sprites.body.scale)
		swarm.count = int(value("count"))
		swarm.spread = Vector2(float(value("radius")), float(value("radius")) * 0.55)
		swarm.build(int(str(data.key).hash() % 997))
		swarm.position.y = -float(value("radius")) * 0.55
		body = swarm
	else:
		var sprite := Sprite2D.new()
		sprite.texture = load(str(config.sprites.body.path))
		sprite.scale = Vector2.ONE * float(config.sprites.body.scale)
		var offset: Array = config.get("offset", [0, 0])
		sprite.position = Vector2(float(offset[0]), float(offset[1]) - sprite.texture.get_height() * sprite.scale.y * 0.5)
		body = sprite
	body.modulate = Color(str(config.get("tint", "ffffff")))
	add_child(body)
	start = data.pos
	goal = data.pos

func value(key: String) -> Variant:
	var enraged: Variant = config.get("enraged", {}).get(key)
	return enraged if enraged != null and int(data.hp) * 2 <= int(data.max_hp) else config.get(key, DEFAULTS.get(key))

func hurt_rect() -> Rect2:
	if not data.alive: return Rect2()
	var size: Array = config.get("hurt", [120, 100] if data.boss else [70, 70])
	var offset: Array = config.get("offset", [0, 0])
	return Rect2(global_position + Vector2(float(offset[0]) - float(size[0]) * 0.5, -float(size[1])), Vector2(float(size[0]), float(size[1])))

func apply_knockback(_impulse: float) -> void:
	pass # swarms keep their lane; shells and membranes are anchored

func on_damaged() -> void:
	flash = 0.16

func on_defeated() -> void:
	fading = true
	clear_marks()
	for shot: Dictionary in shots: shot.node.queue_free()
	shots.clear()
	var tween := create_tween()
	tween.tween_property(body, "modulate:a", 0.0, 0.7)
	tween.tween_callback(body.hide)

func player_center() -> Vector2:
	return host.player.position - Vector2(0, 45)

func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	if kind == "swarm": collision_layer = 0 # a drifting cluster is never a wall
	if fading or not data.alive or not is_instance_valid(host.player) or host.player.health <= 0: return
	if host.reference_visible or host.layer_solo >= 0 or not host.capture_path.is_empty(): return
	flash = maxf(0.0, flash - dt)
	var base := Color(str(config.get("tint", "ffffff")))
	body.modulate = base.lerp(Color(2.2, 2.0, 1.9), clampf(flash / 0.16, 0.0, 1.0)) if state != "tell" else base.lerp(Color(1.5, 1.05, 0.9), 0.5 + 0.5 * sin(timer * 16.0))
	move_shots(dt)
	timer += dt
	match state:
		"rest":
			if timer >= float(value("rest")) and absf(host.player.position.x - data.pos.x) < float(value("engage")): begin_tell()
		"tell":
			update_tell()
			if timer >= float(value("tell")): begin_act()
		"act": update_act()
		"recover":
			if kind == "swarm": data.pos = start.lerp(goal, smoothstep(0.0, 1.0, timer / float(value("recover"))))
			if timer >= float(value("recover")): finish_cycle()

func enter(next: String) -> void:
	state = next
	timer = 0.0

func begin_tell() -> void:
	hit_sent = false
	enter("tell")
	if kind == "swarm":
		var lane: Array = config.lane
		var lanes: Array = config.get("lanes", [data.pos.y])
		var lane_y: float = float(lanes[0])
		for candidate: Variant in lanes:
			if absf(float(candidate) - host.player.position.y) < absf(lane_y - host.player.position.y): lane_y = float(candidate)
		var from_left: bool = absf(data.pos.x - float(lane[0])) < absf(data.pos.x - float(lane[1]))
		start = Vector2(float(lane[0]) if from_left else float(lane[1]), lane_y)
		goal = Vector2(float(lane[1]) if from_left else float(lane[0]), lane_y)
		body.facing = signf(goal.x - start.x)
		var band: Dictionary = config.sprites.tell
		var texture: Texture2D = load(str(band.path))
		var width: float = texture.get_width() * float(band.scale)
		for i: int in ceili(absf(goal.x - start.x) / width):
			add_mark(texture, float(band.scale), Vector2(minf(start.x, goal.x) + width * (i + 0.5), lane_y - 45.0))
	elif kind == "clam":
		var ring: Dictionary = config.sprites.tell
		add_mark(load(str(ring.path)), float(ring.scale), position + mouth())
	else:
		target_point = player_center()
		var echo: Dictionary = config.sprites.tell
		add_mark(load(str(echo.path)), float(echo.scale), target_point)

func mouth() -> Vector2:
	var offset: Array = config.get("mouth", [0, -60])
	return Vector2(float(offset[0]), float(offset[1]))

func add_mark(texture: Texture2D, mark_scale: float, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * mark_scale
	sprite.top_level = true
	sprite.z_as_relative = false
	sprite.z_index = 2
	sprite.global_position = get_parent().to_global(at)
	add_child(sprite)
	marks.append(sprite)

func clear_marks() -> void:
	for sprite: Sprite2D in marks: sprite.queue_free()
	marks.clear()

func update_tell() -> void:
	var progress: float = clampf(timer / float(value("tell")), 0.0, 1.0)
	for sprite: Sprite2D in marks: sprite.modulate.a = 0.45 + 0.55 * absf(sin(timer * 9.0))
	if kind == "swarm": data.pos = Vector2(data.pos).lerp(start, clampf(progress * 1.6, 0.0, 1.0))
	elif kind == "membrane" and not marks.is_empty():
		marks[0].scale = Vector2.ONE * float(config.sprites.tell.scale) * lerpf(1.7, 1.0, progress)

func begin_act() -> void:
	clear_marks()
	enter("act")
	host.sfx("sweep")
	if kind == "clam":
		var total: int = int(value("shots"))
		var texture: Texture2D = load(str(config.sprites.shot.path))
		var origin: Vector2 = position + mouth()
		var aim: float = origin.angle_to_point(player_center())
		for i: int in total:
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.scale = Vector2.ONE * float(config.sprites.shot.scale)
			sprite.position = origin
			sprite.z_index = 4
			get_parent().add_child(sprite)
			shots.append({"node":sprite, "velocity":Vector2.from_angle(aim + deg_to_rad(float(config.get("spread_deg", 14.0))) * (i - (total - 1) * 0.5)) * float(value("speed")), "life":4.0})
	elif kind == "membrane":
		var pulse: Dictionary = config.sprites.pulse
		add_mark(load(str(pulse.path)), float(pulse.scale), target_point)

func update_act() -> void:
	var duration: float = float(value("act"))
	if kind == "swarm":
		var progress: float = clampf(timer / duration, 0.0, 1.0)
		data.pos = start.lerp(goal, progress)
		body.stretch = 1.0 + 1.2 * sin(progress * PI)
		touch(Vector2(data.pos) - Vector2(0, 45), float(value("radius")) * 1.1)
		if progress >= 1.0: end_act()
	elif kind == "clam":
		if timer >= 0.25: end_act()
	else:
		touch(target_point, float(value("radius")))
		for sprite: Sprite2D in marks: sprite.modulate.a = 1.0 - clampf(timer / 0.3, 0.0, 1.0)
		if timer >= 0.3: end_act()

func touch(center: Vector2, reach: float) -> void:
	if hit_sent: return
	var delta: Vector2 = player_center() - center
	if absf(delta.x) < reach and absf(delta.y) < maxf(70.0, reach * 0.8):
		hit_sent = true
		host.player.take_damage(1, center)

func end_act() -> void:
	clear_marks()
	if kind == "swarm":
		body.stretch = 1.0
		start = data.pos
		goal = Vector2(data.pos.x, float(config.get("floor", data.pos.y)))
		# A Boss swarm gathers beside the player, so its exposed pause is a real opening.
		if config.has("floor"):
			var lane: Array = config.lane
			var side: float = signf(data.pos.x - host.player.position.x) if not is_equal_approx(data.pos.x, host.player.position.x) else 1.0
			goal.x = clampf(host.player.position.x + side * 150.0, float(lane[0]), float(lane[1]))
	enter("recover")

func finish_cycle() -> void:
	if repeats_left > 0:
		repeats_left -= 1
		begin_tell()
		return
	repeats_left = int(value("repeat")) if value("repeat") != null else 0
	enter("rest")

func move_shots(dt: float) -> void:
	for i: int in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var sprite: Sprite2D = shot.node
		sprite.position += Vector2(shot.velocity) * dt
		sprite.rotation += dt * 5.0
		shot.life = float(shot.life) - dt
		var struck: bool = sprite.position.distance_to(player_center()) < 38.0
		if struck: host.player.take_damage(1, sprite.position)
		if struck or float(shot.life) <= 0.0:
			sprite.queue_free()
			shots.remove_at(i)
