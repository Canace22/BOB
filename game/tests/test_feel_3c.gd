extends TestSuite
## 3C feel regressions: real collision floor, real Input actions, campaign tuning.

const Camera = preload("res://src/campaign/campaign_camera.gd")
const TUNING: Array[String] = [
	"max_speed", "acceleration", "friction", "gravity", "terminal_speed", "fall_multiplier", "air_control",
	"jump_height", "short_jump_height", "double_jump_speed", "apex_hold", "coyote_time", "jump_buffer_time",
	"collision_size", "capsule_collision", "max_health", "heal_amount", "heal_time", "heal_cooldown",
	"hurt_soul_loss", "melee_damage", "melee_reach", "melee_height", "melee_startup", "melee_cancel_after",
	"hit_recoil_speed", "hit_recoil_time", "hitstop_duration"]
const ACTIONS: Array[String] = ["tp_left", "tp_right", "tp_up", "tp_down", "tp_jump", "tp_attack", "tp_heal"]

class Target extends Node2D:
	var hits: Array[int] = []
	func _ready() -> void: add_to_group("tide_targets")
	func hurt_rect() -> Rect2: return Rect2(global_position - Vector2(10,10), Vector2(20,20))
	func can_receive_hit() -> bool: return true
	func take_hit(amount: int) -> void: hits.append(amount)

class CameraHost extends Node2D:
	var player: Node2D
	var zoomed: bool = true
	var reference_visible: bool = false
	var capture_path: String = ""
	var layer_solo: int = -1
	var camera_feedback: float = 0.0
	var room: Dictionary = {"id":"feel-fixture", "size":[4096,2400]}
	func point(value: Array) -> Vector2: return Vector2(float(value[0]), float(value[1]))
	func reference_camera_active() -> bool: return false

class SavedCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/feel-test-%s.json" % str(ProjectSettings.globalize_path("res://").hash())

func after_each() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action): Input.action_release(action)
	Engine.time_scale = 1.0
	await super.after_each()

## Base actor on a flat floor, carrying the campaign scene's tuning.
func tuned_player(origin: Vector2 = Vector2.ZERO) -> TidePlayer:
	var floor_body := StaticBody2D.new()
	floor_body.position = origin + Vector2(0,200)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8000,20)
	collision.shape = shape
	floor_body.add_child(collision)
	add(floor_body)
	var source: Node = load("res://content/whalebelly/CampaignPlayer.tscn").instantiate()
	var p: TidePlayer = load("res://content/whalebelly/Player.tscn").instantiate()
	for key: String in TUNING: p.set(key, source.get(key))
	source.free()
	p.preload_actions = false
	p.world_collision_mask = 5
	p.world_bounds = Rect2(-9000,-9000,18000,18000)
	p.position = origin + Vector2(0,185)
	add(p)
	await physics_frames(24)
	check(p.is_on_floor(), "fixture settled on real collision floor")
	return p

func jump_profile(p: TidePlayer, hold_frames: int) -> Dictionary:
	var start: Vector2 = p.position
	var rise: float = 0.0
	var frames: int = 0
	Input.action_press("tp_jump")
	for i: int in 120:
		if i == hold_frames: Input.action_release("tp_jump")
		await physics_frames(1)
		rise = maxf(rise, start.y - p.position.y)
		if i > 2 and p.is_on_floor():
			frames = i + 1
			break
	Input.action_release("tp_jump")
	return {"rise":rise, "frames":frames, "span":absf(p.position.x - start.x)}

func test_run_starts_and_stops_at_once() -> void:
	var p: TidePlayer = await tuned_player()
	Input.action_press("tp_right")
	await physics_frames(4)
	check(p.velocity.x >= p.max_speed * 0.9, "full speed within four frames, got %s" % p.velocity.x)
	Input.action_release("tp_right")
	await physics_frames(4)
	eq(p.velocity.x, 0.0, "stops within four frames")

func test_jump_keeps_height_and_span_with_shorter_airtime() -> void:
	var p: TidePlayer = await tuned_player()
	var full: Dictionary = await jump_profile(p, 119)
	# The first frame moves before gravity applies, so the old and new arcs both peak near 160px.
	check(full.rise > 154.0 and full.rise < 163.0, "full jump keeps the authored height, got %s" % full.rise)
	check(full.frames > 0 and full.frames <= 50, "full jump lands within 50 frames, got %s" % full.frames)
	await physics_frames(6)
	var tap: Dictionary = await jump_profile(p, 2)
	check(tap.rise > 20.0 and tap.rise < 60.0, "releasing jump cuts the rise to a hop, got %s" % tap.rise)
	await physics_frames(6)
	Input.action_press("tp_right")
	await physics_frames(10)
	var running: Dictionary = await jump_profile(p, 119)
	Input.action_release("tp_right")
	check(running.span >= 285.0, "running jump still clears the original 289px gap budget, got %s" % running.span)

func test_swing_hits_fast_and_keeps_its_direction() -> void:
	var p: TidePlayer = await tuned_player()
	var victim := Target.new()
	victim.position = p.position + Vector2(60,-30)
	add(victim)
	Input.action_press("tp_attack")
	var frames: int = 0
	for i: int in 12:
		await physics_frames(1)
		frames = i + 1
		if not victim.hits.is_empty(): break
	Input.action_release("tp_attack")
	check(not victim.hits.is_empty() and frames <= 5, "swing lands within five frames, got %s" % frames)
	Input.action_press("tp_left")
	await physics_frames(4)
	eq(p.facing, 1.0, "swing keeps the direction it started with")
	check(p.velocity.x < -100.0, "movement stays free during a swing")
	Input.action_release("tp_left")
	p.start_recoil(-1.0)
	await physics_frames(1)
	eq(p.velocity.x, -p.hit_recoil_speed, "a landed hit pushes the attacker back")

func test_jump_is_free_right_after_the_hit() -> void:
	var p: TidePlayer = await tuned_player()
	Input.action_press("tp_attack")
	await physics_frames(5)
	Input.action_release("tp_attack")
	Input.action_press("tp_jump")
	await physics_frames(3)
	Input.action_release("tp_jump")
	check(p.velocity.y < -100.0 and not p.is_on_floor(), "jump is accepted during swing recovery")
	eq(p.state, "strike_01", "the swing keeps playing through the jump")

func test_focus_heals_one_mask_per_charge_and_release_is_free() -> void:
	var p: TidePlayer = await tuned_player()
	var mask_frames: int = int(ceil(p.heal_time * 60.0)) + 2
	p.health = 2
	Input.action_press("tp_heal")
	await physics_frames(3)
	eq(p.state, "recover", "holding heal starts focus")
	eq(p.soul, 99, "focus is not paid up front")
	await physics_frames(mask_frames)
	eq([p.health, p.soul], [3, 66], "one mask for one charge")
	eq(p.state, "recover", "holding continues into the next mask")
	await physics_frames(mask_frames)
	eq([p.health, p.soul], [4, 33], "second mask while still held")
	Input.action_release("tp_heal")
	await physics_frames(3)
	check(p.state != "recover", "release ends focus")
	Input.action_press("tp_heal")
	await physics_frames(20)
	Input.action_release("tp_heal")
	await physics_frames(3)
	eq([p.health, p.soul], [4, 33], "early release heals nothing and costs nothing")
	Input.action_press("tp_heal")
	await physics_frames(10)
	p.invulnerable = 0
	p.take_damage(1)
	Input.action_release("tp_heal")
	eq([p.health, p.soul], [3, 33], "a hit interrupts focus without draining soul")

func test_camera_peeks_and_leads_falls() -> void:
	var p: TidePlayer = await tuned_player(Vector2(2000,1000))
	var host := CameraHost.new()
	host.player = p
	add(host)
	var camera: WhalebellyCampaignCamera = Camera.new()
	host.add_child(camera)
	camera.host = host
	camera.update_follow(1.0/60.0)
	var rest: float = camera.position.y
	Input.action_press("tp_down")
	for i: int in 20: camera.update_follow(1.0/60.0)
	check(is_zero_approx(camera.smoothed_look), "a short press does not move the view")
	for i: int in 50: camera.update_follow(1.0/60.0)
	Input.action_release("tp_down")
	check(camera.smoothed_look > camera.look_distance * 0.5 and camera.position.y > rest + 40.0, "holding down while idle peeks below")
	for i: int in 120: camera.update_follow(1.0/60.0)
	check(absf(camera.position.y - rest) < 6.0, "the view returns after release")
	p.velocity = Vector2(0,900)
	eq(camera.fall_amount(), 1.0, "a long fall gets the full downward lead")

func test_hurt_freezes_the_world_and_keeps_soul() -> void:
	var host: WhalebellyMain = (load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.set_script(SavedCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	await physics_frames(20)
	var p: WhalebellyCampaignPlayer = host.player
	p.invulnerable = 0
	p.take_damage(1)
	eq([p.health, p.soul], [4, 99], "a hit costs one mask and no soul")
	check(Engine.time_scale < 0.5, "a hit starts a freeze frame")
	await physics_frames(p.hurt_freeze_ticks + 2)
	eq(Engine.time_scale, 1.0, "the freeze ends on its own")
	p.impact.freeze(600)
	host.load_room(0)
	eq(Engine.time_scale, 1.0, "rebuilding the room cannot leave the world frozen")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(host.save_path() + suffix): DirAccess.remove_absolute(host.save_path() + suffix)
