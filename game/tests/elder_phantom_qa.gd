extends "res://tests/elder_complete_skills_qa.gd"
## 真实组合键生成观招，单招站位夹具采集动画帧，伤害仍由原敌人协议驱动。
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	await tap(KEY_F7)
	var cases: Array[Dictionary]=[
		{"name":"upper","keys":[KEY_W,KEY_J]},
		{"name":"heavy","keys":[KEY_S,KEY_J]},
		{"name":"flurry","keys":[KEY_E,KEY_J]},
		{"name":"guard","keys":[KEY_I]},
		{"name":"dash","keys":[KEY_L]},
		{"name":"orb","keys":[KEY_E,KEY_L]},
		{"name":"scream","keys":[KEY_W,KEY_E,KEY_L]}]
	for item: Dictionary in cases:
		var e: EnemyLabElder=await setup_elder(300)
		var keys: Array[Key]=[]
		for code: Key in item.keys: keys.append(code)
		await release_source(e,keys)
		await tick(75)
		check("actual source observed for phantom "+str(item.name),e.mimic.ready_to_cast())
		e.begin_attack("elder_mimic")
		for frame: int in 90:
			await tick(1)
			if e.mimic.view.action_echo.visible: break
		check("full body phantom appears "+str(item.name),e.mimic.view.action_echo.visible and e.mimic.view.action_echo.texture!=null)
		check("caster stays distinct with aligned attack origin "+str(item.name),e.visual.modulate.a<0.5 and e.mimic.view.action_echo.global_position.is_equal_approx(e.global_position))
		var texture: Texture2D=e.mimic.view.action_echo.texture
		await tick(4)
		await shot("elder-phantom-"+str(item.name))
		if str(item.name) not in ["guard"]:
			await tick(3)
			check("body advances through source frames "+str(item.name),texture!=e.mimic.view.action_echo.texture)
		if str(item.name)=="flurry":
			await tick(18)
			await shot("elder-phantom-flurry-second")
			e.take_hit(100)
			await tick(3)
			check("surrender removes moving phantom",not e.mimic.view.action_echo.visible and e.visual.modulate.a==1.0)
		else:
			await tap(KEY_R)
			await tick(14)
			check("R deletes phantom owner "+str(item.name),not is_instance_valid(e))
	print("ELDER_PHANTOM failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
