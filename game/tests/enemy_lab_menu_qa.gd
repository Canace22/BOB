extends SceneTree
## 通过真实弹出菜单和键盘选择复现换敌，不以F1替代菜单生命周期。
var lab: EnemyLab
var failures: int=0
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i: int in count: await physics_frame
func tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await frames(2)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await frames(2)
func verify(title: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",title)
	if not ok: failures+=1
func run() -> void:
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	root.add_child(lab)
	current_scene=lab
	await frames(12)
	lab.hud.enemy_menu.show_popup()
	await frames(4)
	print("MENU opened paused=",paused)
	lab.hud.enemy_menu.show_popup()
	await frames(2)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await frames(10)
	print("MENU selected index=",lab.profile_index," paused=",paused," popup=",lab.hud.enemy_menu.get_popup().visible)
	verify("menu selects mudback",lab.profile_index==1 and lab.enemies[0].profile.id=="mudback")
	verify("menu restores running state",not paused)
	var ticks: int=lab.simulation_ticks
	await frames(12)
	verify("simulation advances after menu selection",lab.simulation_ticks>ticks)
	for menu: OptionButton in [lab.hud.enemy_menu,lab.hud.formation_menu,lab.hud.terrain_menu,lab.hud.move_menu]:
		for initially_paused: bool in [false,true]:
			paused=initially_paused
			var before: int=lab.round_serial
			menu.show_popup()
			menu.show_popup()
			await frames(2)
			verify("open menu freezes world",paused)
			await tap(KEY_ESCAPE)
			verify("cancel restores previous pause state",paused==initially_paused and lab.round_serial==before)
			menu.show_popup()
			menu.show_popup()
			await frames(2)
			await tap(KEY_DOWN)
			await tap(KEY_ENTER)
			await frames(4)
			verify("selection restores previous pause state",paused==initially_paused and not menu.get_popup().visible)
	paused=false
	lab.hud.enemy_menu.show_popup()
	lab.hud.move_menu.show_popup()
	lab.hud.enemy_menu.get_popup().hide()
	verify("overlapping menus keep world frozen",paused)
	lab.hud.move_menu.get_popup().hide()
	verify("last menu restores running state",not paused)
	print("ENEMY_LAB_MENU failures=",failures)
	quit(1 if failures else 0)
