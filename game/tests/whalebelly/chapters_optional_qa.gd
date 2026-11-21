extends "res://tests/whalebelly/chapters_route_qa.gd"
## 完成开场交流夹具后，实际走低路/上台/撤回；不改生命、站位或无敌。
func go(value: Array, limit: int=1500) -> bool:
	target=host.point(value)
	var jump_left: int=0
	for count: int in limit:
		if host.player.health<=0: return false
		if host.player.is_on_floor() and host.player.position.distance_to(target)<55:
			release()
			await tick(15)
			return true
		var gap: Vector2=target-host.player.position
		key(KEY_A,gap.x < -12)
		key(KEY_D,gap.x > 12)
		if jump_left==0 and host.player.is_on_floor() and gap.y< -55 and not bool(held.get(KEY_SPACE,false)): jump_left=30
		key(KEY_SPACE,jump_left>0)
		jump_left=maxi(0,jump_left-1)
		await tick()
	release()
	print("OPTIONAL_DIAG chapter=",host.chapter_id," pos=",host.player.position," target=",target)
	return false

func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for chapter: int in [4,6]:
		var content: Dictionary=ChapterRunCatalog.read(chapter)
		host=load("res://content/prototypes/chapters/main.tscn").instantiate() as ChapterRun
		host.chapter_id=chapter
		host.save_enabled=false
		host.restore_progress=false
		host.completed.append(str(content.stages[0].id))
		root.add_child(host)
		current_scene=host
		await tick(40)
		check("low route reachable ch%d" % chapter,await go([730,480]))
		await tick(60)
		check("low route never requires or wakes enemy ch%d" % chapter,not host.encounter.started and not is_instance_valid(host.encounter.enemy))
		var stairs_ok: bool=true
		for step: Array in [[890,430],[1060,360],[1260,290]]:
			stairs_ok=await go(step) and stairs_ok
		check("upper optional observation reachable ch%d" % chapter,stairs_ok and await go([1470 if chapter==4 else 1510,270]))
		await tick(65)
		check("upper path actually starts complete optional enemy ch%d" % chapter,is_instance_valid(host.encounter.enemy))
		if chapter==6:
			check("optional hunter uses full predator and shelter rules",host.encounter.enemy is EnemyLabPredator and (host.encounter.enemy as EnemyLabPredator).shelter_enabled)
		check("retreat to low observation survives ch%d" % chapter,await go([730,480]))
		await tick(30)
		var health: int=host.player.health
		await tick(180)
		check("low observation remains safe after retreat ch%d" % chapter,host.player.health==health and health>0)
		release()
		root.remove_child(host)
		host.free()
		await tick(4)
	print("CHAPTERS_OPTIONAL_QA checks=",checks," failures=",failures)
	quit(1 if failures else 0)
