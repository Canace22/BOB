extends SceneTree
## 实际按键走下降、战斗、救援和离场；存活/重读检查使用显式重建夹具。
var host: ChapterTwoWhitebox
var failures: int = 0
var checks: int = 0
const OUTPUT := "res://build/qa/chapter-two"

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for frame: int in count: await physics_frame
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(3)
func check(label: String, passed: bool) -> void:
	checks += 1
	print("PASS " if passed else "FAIL ",label)
	if not passed: failures += 1
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))
func release() -> void:
	for code: Key in [KEY_D,KEY_A,KEY_I,KEY_J,KEY_K,KEY_W,KEY_Q,KEY_L,KEY_SPACE]: key(code,false)
func clear_dialogue() -> void:
	release()
	await tick(12)
	for count: int in 65:
		if not host.hud.dialogue.visible: break
		await tap(KEY_F)
		await tick(10)
	await tick(20)

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/prototypes/chapter_two/main.tscn").instantiate() as ChapterTwoWhitebox
	host.restore_progress = false
	host.qa_save_suffix = "native-test"
	root.add_child(host)
	current_scene = host
	await tick(40)
	check("opening actively appears",host.hud.dialogue.visible and host.flow.dialogue_id=="arrival")
	await shot("01-arrival")
	await clear_dialogue()
	key(KEY_D,true)
	for frame: int in 500:
		await tick(1)
		if host.hud.dialogue.visible: break
	key(KEY_D,false)
	check("real descent reaches refusal without finding a tiny lamp",host.flow.dialogue_id=="refusal" and host.player.position.y>=470)
	check("guard cannot be attacked before warning",not host.guard.can_receive_hit() and host.guard.hit_count==0)
	await shot("02-refusal")
	await clear_dialogue()
	key(KEY_D,true)
	for frame: int in 150:
		await tick(1)
		if host.flow.stage=="shell_warning": break
	key(KEY_D,false)
	check("crossing line first produces a readable shell warning",host.flow.stage=="shell_warning" and not host.guard.awake)
	await tick(55)
	check("warning transitions into natural guard combat",host.flow.stage=="combat" and host.guard.awake)
	await shot("03-combat")
	var guard_before: int = host.guard.parry_count
	# 只读敌人阶段选择实际按键，不改敌人生命、玩家无敌或站位。
	for frame: int in 7200:
		await tick(1)
		if not host.guard.outcome.is_empty() or host.player.health<=0: break
		var gap: float = host.guard.position.x-host.player.position.x
		var approach: bool = absf(gap)>110 and host.guard.state=="idle"
		key(KEY_D,approach and gap>0)
		key(KEY_A,approach and gap<0)
		var defending: bool = host.guard.state in ["tell","active"] and host.guard.timer>=host.guard.phase_duration()-0.2 if host.guard.state=="tell" else host.guard.state=="active"
		key(KEY_I,defending)
		key(KEY_J,host.guard.state=="recover" and frame%16<2)
		if frame%300==0: print("COMBAT_TRACE hp=",host.player.health," guard=",host.guard.health," state=",host.guard.state," x=",host.player.position.x," facing=",host.player.facing)
	release()
	check("guard fight completes using real basic inputs",host.facts.get("guard_defeated",false) and host.player.health>0)
	check("guard survived, removed blocking and stops accepting hits",host.guard.outcome=="surrender" and host.guard.data.alive and not host.guard.can_receive_hit() and host.blockade.disabled)
	check("actual defense creates openings",host.guard.parry_count>guard_before)
	await shot("04-surrender")
	if not host.facts.get("guard_defeated",false):
		await finish()
		return
	key(KEY_D,true)
	for frame: int in 300:
		await tick(1)
		if host.flow.dialogue_id=="aftermath": break
	key(KEY_D,false)
	check("victory does not grant passage before residents are safe",host.flow.dialogue_id=="aftermath" and not host.facts.get("permit",false))
	await clear_dialogue()
	check("leaving combat naturally triggers rescue",host.flow.stage=="rescue" and not host.player.controls_enabled)
	await tick(270)
	await shot("05-rescue-support")
	check("rescue has no additional hostile fight",not host.guard.can_receive_hit() and not host.hud.dialogue.visible)
	await tick(240)
	check("residents reach safety before permission dialogue",host.facts.get("rescue_done",false) and host.flow.dialogue_id=="permit")
	await shot("06-permit")
	await clear_dialogue()
	check("permission follows rescue and dialogue",host.facts.get("permit",false) and host.flow.stage=="permitted")
	key(KEY_D,true)
	for frame: int in 500:
		await tick(1)
		if host.flow.dialogue_id=="complete": break
	key(KEY_D,false)
	check("real exit route reaches stomach entrance",host.flow.dialogue_id=="complete" and host.player.position.x>=2680)
	await clear_dialogue()
	check("chapter closes without granting new abilities",host.facts.get("completed",false) and not host.player.skill_unlocked("dash") and not host.player.skill_unlocked("chapter"))
	await shot("07-complete")
	await finish()

func finish() -> void:
	release()
	paused = false
	host.record("qa_finished",{"checks":checks,"failures":failures})
	root.remove_child(host)
	host.free()
	await tick(4)
	print("CHAPTER_TWO_QA checks=",checks," failures=",failures)
	quit(1 if failures else 0)
