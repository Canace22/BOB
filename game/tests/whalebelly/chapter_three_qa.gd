extends "res://tests/whalebelly/chapter_two_qa.gd"
## 全程实际按键；只读敌人阶段决定防守，不注入生命、无敌或位置。
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/chapter-three/"+label+".png")

func walk(x: float, limit: int = 650) -> void:
	release()
	for frame: int in limit:
		if absf(host.player.position.x-x)<12 or host.hud.dialogue.visible: break
		var right: bool=host.player.position.x<x
		key(KEY_D,right)
		key(KEY_A,not right)
		var px: float=host.player.position.x
		var stairs: bool=(px>1010 and px<1250 and not right) or (px>2240 and px<2510 and right)
		key(KEY_SPACE,stairs and frame%60<30)
		await tick(1)
	release()
	await tick(30)

func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapter-three")
	host=load("res://content/prototypes/chapter_three/main.tscn").instantiate() as ChapterThreeWhitebox
	host.restore_progress=false
	host.qa_save_suffix="native-test"
	root.add_child(host)
	current_scene=host
	await tick(40)
	check("arrival appears automatically",host.flow.dialogue_id=="arrival")
	await clear_dialogue()
	await walk(650)
	check("approach automatically introduces resident problem",host.flow.dialogue_id=="meet")
	await shot("01-meet")
	await clear_dialogue()
	await walk(1010)
	await tap(KEY_F)
	check("player inspects actual basin before searching",host.flow.dialogue_id=="basin")
	await clear_dialogue()
	await walk(1640)
	await tick(60)
	check("mudback attacks only after readable ambush cue",host.flow.stage=="combat" and host.guard.profile.id=="mudback")
	for frame: int in 7200:
		await tick(1)
		if host.facts.get("enemy_cleared",false) or host.player.health<=0: break
		var gap: float=host.guard.position.x-host.player.position.x
		var dangerous: bool=host.guard.state in ["tell","active"]
		var heavy: bool=bool(host.guard.spec.get("unblockable",false))
		var approach: bool=absf(gap)>100 and host.guard.state in ["idle","recover"]
		key(KEY_D,approach and gap>0)
		key(KEY_A,approach and gap<0)
		key(KEY_I,dangerous and not heavy and (host.guard.state=="active" or host.guard.timer>host.guard.phase_duration()-0.25))
		key(KEY_SPACE,dangerous and heavy and host.guard.state=="tell" and host.guard.timer>host.guard.phase_duration()-0.28)
		key(KEY_J,host.guard.state=="recover" and absf(gap)<150 and frame%16<2)
		if frame%600==0: print("MUD_TRACE hp=",host.player.health," enemy=",host.guard.health," move=",host.guard.move_key," x=",host.player.position.x)
	release()
	check("natural combat clears mudback alive",host.facts.get("enemy_cleared",false) and host.guard.outcome=="retreat" and host.player.health>0)
	check("winning does not open valve or unblock final exit",not host.facts.get("valve_opened",false) and not host.blockade.disabled)
	if not host.facts.get("enemy_cleared",false):
		await finish()
		return
	await walk(2110)
	await tap(KEY_F)
	check("valve inspection is separate from opening",host.flow.dialogue_id=="valve" and not host.facts.get("valve_opened",false))
	await clear_dialogue()
	await tick(90)
	check("waiting after inspection never auto opens valve",host.flow.stage=="ready" and not host.facts.get("valve_opened",false))
	await shot("02-before-opening")
	await tap(KEY_F)
	check("second deliberate F changes water route",host.flow.stage=="rescue" and host.facts.get("valve_opened",false))
	await tick(210)
	await shot("03-return-flow")
	await tick(290)
	check("flood settles without moving player or replaying combat",host.flow.stage=="aftermath" and not host.guard.awake and host.player.position.x>1900)
	await walk(900)
	check("actual return to high platform triggers aftermath",host.flow.dialogue_id=="after")
	await shot("04-aftermath")
	await clear_dialogue()
	await walk(480)
	await tap(KEY_F)
	check("real return stairs allow salvage retrieval",host.flow.stage=="carry" and host.facts.get("salvage",false))
	await walk(820)
	await tap(KEY_F)
	check("repair is a separate resident-side action",host.flow.dialogue_id=="fixed")
	await clear_dialogue()
	check("repair opens actual exit without restoring lost crops",host.facts.get("repaired",false) and host.blockade.disabled and host.facts.get("valve_opened",false))
	await shot("05-repaired")
	await walk(3420,1100)
	check("real steps and exit reach fat-store entrance",host.flow.dialogue_id=="complete")
	await clear_dialogue()
	check("chapter ends without granting new combat skills",host.facts.get("completed",false) and not host.player.skill_unlocked("dash"))
	await finish()

func finish() -> void:
	release()
	paused=false
	host.record("qa_finished",{"checks":checks,"failures":failures})
	root.remove_child(host)
	host.free()
	await tick(4)
	print("CHAPTER_THREE_QA checks=",checks," failures=",failures)
	quit(1 if failures else 0)
