extends SceneTree
## 原生真实键盘验证；技能/站位夹具用于确定接口结果，混编追击另用连续实际输入。
var lab: EnemyLab
var failures: int=0
const OUT: String="res://build/qa/enemy-lab"
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(2)
func check(title: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",title)
	if not ok: failures+=1
func shot(title: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+title+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	check("lab starts normally without god mode",lab.player.is_on_floor() and not lab.player.invincible)
	await shot("overview")
	for i: int in 2:
		await tap(KEY_F1)
		await tick(10)
		check("F1 selects next enemy",lab.profile_index==i+1 and lab.enemies[0].profile.id==EnemyLabCatalog.PROFILES[i+1].id)
	lab.auto_attack=false
	lab.reset_round()
	await tick(10)
	var e: EnemyLabEnemy=lab.enemies[0]
	lab.player.position=e.position-Vector2(95,0)
	lab.player.facing=1.0
	key(KEY_J,true)
	await tick(13)
	key(KEY_J,false)
	check("actual J reaches front shell",e.reactions.received==1 and is_equal_approx(e.reactions.damage_remainder,0.5))
	await shot("front-shell")
	await tick(30)
	lab.player.position=e.position+Vector2(95,0)
	lab.player.facing=-1.0
	key(KEY_J,true)
	await tick(13)
	key(KEY_J,false)
	check("rear hit deals full damage",e.health==e.maximum-1 and is_equal_approx(e.reactions.damage_remainder,0.5))
	await shot("rear-opening")
	lab.profile_index=0
	lab.fixed_move=3
	lab.hud.sync()
	lab.reset_round()
	await tick(10)
	e=lab.enemies[0]
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	await tap(KEY_ENTER)
	await tick(18)
	key(KEY_I,true)
	await tick(14)
	key(KEY_I,false)
	check("real I blocks and cancels double followup",e.parry_count==1 and e.state=="recover")
	key(KEY_J,true)
	await tick(28)
	key(KEY_J,false)
	check("real J after guard earns counter pressure",e.health==1 and lab.player.health==5)
	await shot("guard-counter")
	await tap(KEY_P)
	var count: int=lab.simulation_ticks
	await tick(4)
	check("P pauses world",paused and lab.simulation_ticks==count)
	await tap(KEY_PERIOD)
	await tick(4)
	check("period grants one physics tick",paused and lab.simulation_ticks==count+1)
	await shot("paused")
	await tap(KEY_P)
	await tap(KEY_F6)
	check("god mode is explicit and controllable",lab.invincible and lab.player.invincible)
	await tap(KEY_F6)
	lab.profile_index=1
	lab.formation=1
	lab.fixed_move=0
	lab.terrain=1
	lab.auto_attack=true
	lab.hud.sync()
	lab.reset_round()
	await tick(10)
	check("mixed scene uses real heavy and light targets",lab.enemies.size()==2 and lab.enemies[0].profile.id=="mudback" and lab.enemies[1].profile.id=="forager")
	key(KEY_D,true)
	await tick(28)
	key(KEY_D,false)
	key(KEY_A,true)
	var seen: bool=false
	for i: int in 100:
		if lab.enemies[0].attack_serial>0: seen=true
		await tick(1)
	key(KEY_A,false)
	check("natural AI starts attacks while player moves",seen)
	check("heavy can move from narrow side into wide side",lab.enemies[0].position.x<720.0)
	await shot("mixed-narrow-wide")
	var old_id: int=lab.enemies[0].get_instance_id()
	await tap(KEY_R)
	await tick(10)
	check("R replaces prior round and keeps scenario",not is_instance_id_valid(old_id) and lab.enemies.size()==2)
	print("ENEMY_LAB_NATIVE failures=",failures)
	paused=false
	lab.queue_free()
	await tick(4)
	quit(0 if failures==0 else 1)
