class_name EnemyLab
extends Node2D
## 独立无存档试验场。重置由此唯一收口，销毁整轮角色、弹体与敌人。
var player: EnemyLabPlayer
var enemies: Array[EnemyLabEnemy]=[]
var world: Node2D
var hud: EnemyLabHUD
var all_skill_practice: bool=false
var profile_index: int=0
var formation: int=0
var terrain: int=0
var fixed_move: int=0
var auto_attack: bool=true
var ranges: bool=true
var invincible: bool=false
var kill_comparison: bool=false
var step_requested: bool=false
var rebuilding: bool=false
var route_passed: bool=false
var pump_court: EnemyLabPumpCourt
var round_serial: int=0
var simulation_ticks: int=0
var events: Array[String]=[]
const FLOOR: float=520.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_title("鲸落 · 统一敌人试验场")
	RenderingServer.set_default_clear_color(Color("101823"))
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud=EnemyLabHUD.new()
	hud.lab=self
	canvas.add_child(hud)
	reset_round()

func record(message: String) -> void:
	events.push_front(message)
	if events.size()>4: events.pop_back()

func reset_round() -> void:
	if rebuilding: return
	rebuilding=true
	_rebuild.call_deferred()

func _rebuild() -> void:
	if is_instance_valid(world):
		player.clear_combat_input()
		player.clear_projectiles()
		remove_child(world)
		world.free()
	enemies.clear()
	route_passed=false
	world=Node2D.new()
	world.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	_make_body(Rect2(0,FLOOR,1280,220))
	_make_body(Rect2(-30,0,30,740))
	_make_body(Rect2(1280,0,30,740))
	if terrain==1: _make_body(Rect2(720,150,560,220))
	elif terrain==2: _make_body(Rect2(0,330,260,30))
	elif terrain in [3,4]: _make_body(Rect2(1060,0,220,385))
	var actor: Node=preload("res://content/whalebelly/Player.tscn").instantiate()
	actor.set_script(preload("res://src/prototypes/enemy_lab/player.gd"))
	player=actor as EnemyLabPlayer
	player.all_skill_practice=all_skill_practice
	player.position=Vector2(420,FLOOR)
	world.add_child(player)
	player.collision_mask=5
	player.show_debug=ranges
	player.invincible=invincible
	var guard_view := EnemyLabGuardFeedback.new()
	guard_view.player=player
	guard_view.z_index=9
	player.add_child(guard_view)
	player.damaged.connect(func() -> void: record("玩家受击"))
	player.backstep_started.connect(func() -> void: record("后跳：取消当前动作"))
	_spawn(profile_index,855.0)
	if formation==1: _spawn(0,1080.0)
	elif formation==2:
		# 双轻体场景不改变已选敌人的数据，明确切换成两个食腐甲。
		var old: EnemyLabEnemy=enemies.pop_back()
		world.remove_child(old)
		old.free()
		_spawn(0,800.0)
		_spawn(0,1050.0)
	pump_court=null
	if str(EnemyLabCatalog.profile(profile_index).id)=="pump_warden" and formation!=2 and terrain==4:
		pump_court=EnemyLabPumpCourt.new()
		pump_court.lab=self
		pump_court.warden=enemies[0] as EnemyLabWarden
		world.add_child(pump_court)
		world.move_child(pump_court,0)
		(enemies[0] as EnemyLabWarden).court=pump_court
	round_serial+=1
	step_requested=false
	rebuilding=false
	events.clear()
	record("新一轮 %d · 旧攻击、控制与弹体已清理" % round_serial)
	queue_redraw()

func _spawn(index: int, x: float) -> void:
	var config: Dictionary=EnemyLabCatalog.profile(index)
	var enemy: EnemyLabEnemy
	match str(config.id):
		"membrane_hunter": enemy=EnemyLabPredator.new()
		"nest_eel": enemy=EnemyLabEel.new()
		"pump_warden": enemy=EnemyLabWarden.new()
		"beam_guard": enemy=EnemyLabBeamGuard.new()
		"elder_guardian": enemy=EnemyLabElder.new()
		_: enemy=EnemyLabEnemy.new()
	enemy.profile=config
	enemy.player=player
	enemy.position=Vector2(x,FLOOR)
	if enemy is EnemyLabWarden: enemy.exit_enabled=terrain in [3,4]
	enemy.auto_attack=auto_attack
	enemy.show_ranges=ranges
	enemy.kill_comparison=kill_comparison
	if enemy is EnemyLabPredator: enemy.shelter_enabled=terrain==2
	world.add_child(enemy)
	if enemy is EnemyLabWarden: enemy.reached_exit.connect(_complete_route)
	enemy.changed.connect(record)
	if not enemies.is_empty(): enemy.timer=-0.35
	enemies.append(enemy)
	apply_settings()

func _make_body(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size=rect.size
	collision.shape=shape
	body.position=rect.get_center()
	body.add_child(collision)
	world.add_child(body)

func apply_settings() -> void:
	if is_instance_valid(player):
		player.invincible=invincible
		player.show_debug=ranges
	for index: int in enemies.size():
		var e: EnemyLabEnemy=enemies[index]
		e.auto_attack=auto_attack
		e.show_ranges=ranges
		e.kill_comparison=kill_comparison
		e.forced_move=str(e.profile.moves[clampi(fixed_move-1,0,e.profile.moves.size()-1)]) if index==0 and fixed_move>0 else ""

func select_profile(index: int) -> void:
	profile_index=index
	formation=0
	fixed_move=0
	if str(EnemyLabCatalog.profile(index).id)=="membrane_hunter": terrain=2
	elif str(EnemyLabCatalog.profile(index).id)=="pump_warden": terrain=0
	elif terrain in [2,3,4]: terrain=0
	hud.sync()
	reset_round()

func select_terrain(index: int) -> void:
	var airborne: bool=str(EnemyLabCatalog.profile(profile_index).id)=="membrane_hunter" and formation!=2
	terrain=2 if airborne and index==1 else index
	hud.sync()
	reset_round()

func _complete_route() -> void:
	if route_passed: return
	route_passed=true
	if is_instance_valid(pump_court): pump_court.stop()
	for enemy: EnemyLabEnemy in enemies:
		if enemy.outcome.is_empty(): enemy.finish()
	record("已抵达安全线 · 执卫停手 · 无需击杀")

func force_attack() -> void:
	if enemies.is_empty() or rebuilding: return
	if not enemies[0].begin_attack(): record("不能起手：等待敌人回到待机状态")

func toggle_pause() -> void:
	get_tree().paused=not get_tree().paused
	step_requested=false

func _physics_process(_dt: float) -> void:
	if not is_instance_valid(world): return
	var grant: bool=get_tree().paused and step_requested
	world.process_mode=Node.PROCESS_MODE_ALWAYS if grant else Node.PROCESS_MODE_PAUSABLE
	if not get_tree().paused or grant: simulation_ticks+=1
	step_requested=false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int=event.keycode if event.keycode!=0 else event.physical_keycode
	match key:
		KEY_R: reset_round()
		KEY_P: toggle_pause()
		KEY_PERIOD:
			if get_tree().paused: step_requested=true
		KEY_ENTER: force_attack()
		KEY_F7:
			all_skill_practice=not all_skill_practice
			player.all_skill_practice=all_skill_practice
			record("全技能练习："+str(all_skill_practice)+" · 不写存档")
		KEY_F1: select_profile((profile_index+1)%EnemyLabCatalog.PROFILES.size())
		KEY_F2:
			ranges=not ranges
			apply_settings()
			hud.sync()
		KEY_F6:
			invincible=not invincible
			apply_settings()
			hud.sync()

func _exit_tree() -> void:
	if get_tree()!=null: get_tree().paused=false

func _draw() -> void:
	# 这些几何体是白盒场地与碰撞调试，不是正式环境美术。
	draw_rect(Rect2(0,FLOOR,1280,58),Color("253547"))
	draw_line(Vector2(0,FLOOR),Vector2(1280,FLOOR),Color("82a7ba"),2.0)
	if str(EnemyLabCatalog.profile(profile_index).id)=="pump_warden" and formation!=2 and terrain in [3,4]:
		draw_line(Vector2(EnemyLabWarden.EXIT_X,390),Vector2(EnemyLabWarden.EXIT_X,FLOOR),Color("8de3b3"),3.0)
	if terrain in [3,4]: draw_rect(Rect2(1060,0,220,385),Color("253547"))
	if terrain==1:
		draw_rect(Rect2(720,150,560,220),Color("1c2a37"))
		draw_rect(Rect2(720,150,560,220),Color("82a7ba"),false,2.0)
	elif terrain==2:
		draw_rect(Rect2(0,330,260,30),Color("253547"))
		draw_line(Vector2(650,175),Vector2(1150,175),Color("82a7ba"),2.0)
		for anchor: Vector2 in EnemyLabPredator.PERCHES:
			draw_line(Vector2(anchor.x,170),Vector2(anchor.x,183),Color("82a7ba"),3.0)
