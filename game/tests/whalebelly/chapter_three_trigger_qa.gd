extends "res://tests/whalebelly/chapter_three_qa.gd"
## 回归用户路线：完成居民交流后，不按F查看回水，直接走近大甲。
func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapter-three")
	host=load("res://content/prototypes/chapter_three/main.tscn").instantiate() as ChapterThreeWhitebox
	host.restore_progress=false
	host.save_enabled=false
	host.facts={"arrival":true,"met":true}
	root.add_child(host)
	current_scene=host
	await tick(40)
	await walk(1640)
	await tick(60)
	print("TRIGGER_TRACE x=",host.player.position.x," stage=",host.flow.stage," clue=",host.facts.get("clue",false)," awake=",host.guard.awake," paused=",paused)
	check("approaching mudback without optional basin inspection starts combat",host.flow.stage=="combat" and host.guard.awake and not paused)
	check("automatic encounter does not invent inspected clue or open valve",not host.facts.get("clue",false) and not host.facts.get("valve_opened",false))
	await shot("trigger-without-basin")
	await finish()
