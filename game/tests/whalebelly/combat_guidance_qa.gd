extends SceneTree
## 隔离主线房间；出生后只用物理键事件移动、跳跃和J普攻。
const OUT := "res://build/qa/combat-guidance"
var host: WhalebellyMain
var checks: Array[Dictionary] = []
var held: Dictionary = {}
var seen: Dictionary = {}

func _initialize() -> void: run.call_deferred()

func frames(count: int) -> void:
	for i: int in count: await process_frame

func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"pass":ok})
	print("PASS " if ok else "FAIL ",label)

func key(code: Key, down: bool) -> void:
	if bool(held.get(code,false)) == down: return
	held[code] = down
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code,true)
	await frames(2)
	key(code,false)
	await frames(2)

func release() -> void:
	for code: Key in held.keys(): key(code,false)

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))

func move_to(target: Vector2, jump: bool = false) -> bool:
	var jump_left: int = 35 if jump else 0
	key(KEY_SPACE,jump)
	for frame: int in 300:
		var p: WhalebellyCampaignPlayer = host.player
		var offset: Vector2 = target-p.position
		if p.health <= 0: break
		if absf(offset.x) < 8.0 and absf(offset.y) < 38.0 and p.is_on_floor():
			release()
			print("REACHED ",target," at ",p.position," hp=",p.health)
			return true
		key(KEY_D,offset.x > 4.0)
		key(KEY_A,offset.x < -4.0)
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0: key(KEY_SPACE,false)
		await physics_frame
	release()
	print("MOVE_FAILED ",target," at ",host.player.position," hp=",host.player.health)
	return false

func fight() -> bool:
	var p: WhalebellyCampaignPlayer = host.player
	var enemy: Dictionary = host.enemies[0]
	var crab: CampaignCrabBoss = enemy.actor
	var jump_left: int = 0
	for frame: int in 9000:
		if not enemy.alive: return true
		if p.health <= 0: return false
		var direction: float = signf(crab.position.x-p.position.x)
		var gap: float = absf(crab.position.x-p.position.x)
		var retreat: bool = crab.kind in ["slam","charge"] and crab.state in ["tell","active"]
		var desired: float = 440.0 if crab.kind == "charge" else 345.0
		var motion: float = 0.0
		if retreat and gap < desired and p.position.x > crab.retreat_bounds.x+7.0:
			motion = -direction
		elif not retreat and gap > 210.0: motion = direction
		elif p.facing != direction: motion = direction
		key(KEY_A,motion < 0.0)
		key(KEY_D,motion > 0.0)
		if jump_left > 0: jump_left -= 1
		if crab.kind in ["sweep","second"] and crab.state == "tell" and crab.timer > 0.38 and p.is_on_floor() and jump_left == 0:
			jump_left = 35
		key(KEY_SPACE,jump_left > 0)
		key(KEY_J,crab.state in ["recover","stagger"] and gap < 265.0 and frame % 25 < 2)
		var tag: String = crab.state+"-"+crab.kind
		if crab.state in ["tell","recover"] and not seen.has(tag):
			seen[tag] = CampaignGuidance.combat_hint(host)
			await shot(tag)
		await physics_frame
	return false

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","combat-guidance")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	host.capture_room = 3
	root.add_child(host)
	current_scene = host
	await frames(45)
	check("arrival names the ready weapon and real J key",CampaignGuidance.combat_hint(host).contains("开局即可使用") and CampaignGuidance.combat_hint(host).contains("J"))
	check("first boss starts without dash",not host.player.ability_available("A1_dash"))
	await shot("01-arrival")
	root.size = Vector2i(900,506)
	await frames(6)
	await shot("02-small-window")
	root.size = Vector2i(1280,720)
	await tap(KEY_H)
	var help: String = ""
	for node: Node in host.player_ui.body.find_children("*","Label",true,false): help += node.text+"\n"
	check("H repeats equipment and melee tactics",host.player_ui.page_id == "help" and help.contains("开局即可攻击") and help.contains("不消耗蓄振") and help.contains("负壳蟹"))
	await shot("03-help")
	await tap(KEY_ESCAPE)
	await frames(15)
	check("closing help restores gameplay",host.player.controls_enabled and not paused)
	var approached: bool = await move_to(Vector2(380,760))
	approached = approached and await move_to(Vector2(670,660),true)
	approached = approached and await move_to(Vector2(1000,800))
	check("keyboard route crosses entrance steps without dash",approached and host.player.health == 5)
	var won: bool = await fight() if approached else false
	release()
	await frames(12)
	check("physical movement jump and J defeat boss",won and host.player.health > 0)
	check("real hits reach the normal victory handler",host.events.any(func(event: Dictionary) -> bool: return str(event.get("event","")) == "enemy_defeated"))
	check("victory grants dash and clears advice",host.abilities.dash and CampaignGuidance.combat_hint(host).is_empty())
	await shot("04-result")
	var report: Dictionary = {"checks":checks,"seen":seen,"health":host.player.health,"boss_hp":host.enemies[0].hp,
		"method":"R1-04 normal spawn fixture, then physical A/D, Space and J only; no position, health or ability writes during combat"}
	var file := FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	var failed: int = checks.filter(func(entry: Dictionary) -> bool: return not entry.pass).size()
	print("COMBAT_GUIDANCE_QA ",JSON.stringify({"checks":checks.size(),"failed":failed,"health":host.player.health,"boss_hp":host.enemies[0].hp}))
	await host.graceful_quit(0 if failed == 0 else 1)
