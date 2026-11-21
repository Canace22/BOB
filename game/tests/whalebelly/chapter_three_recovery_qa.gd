extends "res://tests/whalebelly/chapter_three_qa.gd"
## 显式已完成进度夹具只测跨章/恢复；完整交锋另由主链实际按键证明。
func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapter-three")
	host=load("res://content/prototypes/chapter_two/main.tscn").instantiate() as ChapterTwoWhitebox
	host.restore_progress=false
	host.qa_save_suffix="bridge-test"
	host.facts={"arrival":true,"refusal":true,"guard_defeated":true,"rescue_done":true,"permit":true,"completed":true}
	root.add_child(host)
	current_scene=host
	host.save_progress()
	var second_path: String=host.save_path()
	var second_data: String=FileAccess.get_file_as_string(second_path)
	await tick(40)
	await walk(2685)
	await tap(KEY_F)
	await tick(45)
	host=current_scene as ChapterThreeWhitebox
	check("F at chapter-two endpoint loads chapter-three scene",host!=null)
	if host==null:
		quit(1)
		return
	check("handoff preserves save suffix but changes namespace",host.qa_save_suffix=="bridge-test" and host.save_path()!=second_path)
	await clear_dialogue()
	# 仅作为中断恢复夹具，不声称通过本次战斗。
	host.facts={"arrival":true,"met":true,"clue":true,"enemy_cleared":true}
	host.save_progress()
	await tap(KEY_R)
	await tick(40)
	host=current_scene as ChapterThreeWhitebox
	check("victory reload leaves valve closed and no combat",host.flow.stage=="valve" and not host.facts.get("valve_opened",false) and not host.guard.can_receive_hit())
	await walk(2110)
	await tap(KEY_F)
	await clear_dialogue()
	await tap(KEY_F)
	check("explicit open starts flood",host.flow.stage=="rescue")
	await tap(KEY_F)
	await tick(30)
	check("skip settles flood but still requires actual return",host.flow.stage=="aftermath" and host.player.position.x>1900 and not host.hud.dialogue.visible)
	await tap(KEY_R)
	await tick(50)
	host=current_scene as ChapterThreeWhitebox
	check("interrupted flood restores safe resident-side aftermath",host.player.position.x<1100 and host.flow.dialogue_id=="after" and not host.facts.get("settled",false))
	await clear_dialogue()
	await tap(KEY_F)
	check("cannot repair without recovering shell",not host.facts.get("repaired",false) and host.flow.stage=="salvage")
	await walk(480)
	await tap(KEY_F)
	await tap(KEY_R)
	await tick(40)
	host=current_scene as ChapterThreeWhitebox
	check("salvage survives reload without replaying flood",host.flow.stage=="carry" and host.facts.get("salvage",false))
	await walk(820)
	await tap(KEY_F)
	await clear_dialogue()
	await tap(KEY_R)
	await tick(40)
	host=current_scene as ChapterThreeWhitebox
	check("completed repair survives reload and opens collision",host.flow.stage=="repaired" and host.blockade.disabled)
	await tap(KEY_F6)
	await tick(40)
	host=current_scene as ChapterThreeWhitebox
	check("F6 resets only third chapter",not host.facts.get("valve_opened",false) and FileAccess.get_file_as_string(second_path)==second_data)
	await clear_dialogue()
	await finish()
