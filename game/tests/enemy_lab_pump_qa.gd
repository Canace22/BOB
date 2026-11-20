extends "res://tests/enemy_lab_warden_qa.gd"
## 单水路用场地夹具，完整撤离从默认位置实际D/F/空格操作。
func setup_court() -> EnemyLabPumpCourt:
	lab.auto_attack=false
	lab.terrain=4
	lab.reset_round()
	await tick(14)
	return lab.pump_court

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=5
	lab.terrain=4
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	var court: EnemyLabPumpCourt=lab.pump_court
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	check("scene has membrane pump and valve bitmaps",court.view.pump.texture!=null and court.view.valve.texture!=null)
	check("menu exposes two hydraulic commands and pole auxiliaries",lab.hud.move_menu.item_count==7)
	court.request("sluice")
	await tick(42)
	check("level pump operates independently of boss casting",court.manual and court.phase=="fill")
	await shot("pump-sluice-command")
	await tick(50)
	check("command really starts visibly foaming pressure interval",court.cycles>0 and court.manual and court.view.jet.visible)
	await shot("pump-charged-gate")
	court=await setup_court()
	lab.player.position=Vector2(980,520)
	lab.player.facing=1.0
	court.manual=true
	court.timer=1.60
	key(KEY_I,true)
	for frame: int in 100:
		await tick(1)
		if court.blocks>0 or lab.player.health<5: break
	check("real I blocks tall pump jet through stance protocol",lab.player.health==5 and court.blocks==1)
	check("jet physically pushes held guard instead of zero-cost immunity",lab.player.position.x<980 and (lab.player.skill_controller as EnemyLabSkills).guard_meter<70.0)
	await shot("pump-jet-guard")
	key(KEY_I,false)
	court=await setup_court()
	lab.player.position=Vector2(780,520)
	court.request("siphon")
	await tick(36)
	await shot("pump-reverse-warning")
	await tick(28)
	check("reverse flow pulls actual grounded character to inlet",lab.player.position.x>810 and lab.player.position.x<865)
	await shot("pump-reverse-pull")
	court=await setup_court()
	lab.player.position=Vector2(780,520)
	court.request("siphon")
	await tick(34)
	key(KEY_SPACE,true)
	await tick(30)
	key(KEY_SPACE,false)
	check("actual jump leaves ground siphon while flow remains",lab.player.position.y<450 and lab.player.position.x<810 and court.pull_left>0.0)
	await shot("pump-jump-pull")
	court=await setup_court()
	lab.player.position=Vector2(980,520)
	court.manual=true
	court.timer=1.80
	key(KEY_SPACE,true)
	await tick(45)
	key(KEY_SPACE,false)
	check("visible tall jet still reaches a jump inside water column",court.hits==1 and lab.player.health==4)
	court=await setup_court()
	lab.player.position=Vector2(600,520)
	e=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_vortex")
	court.request("siphon")
	key(KEY_F,true)
	await tick(3)
	key(KEY_F,false)
	check("real F unloads membrane without destroying it",court.vents==1 and court.vent_left>2.8 and not court.stopped)
	check("relief interrupts command and opens visible imbalance",e.state=="recover" and e.opening_left>1.0 and not court.view.jet.visible)
	await shot("pump-relief-window")
	lab.auto_attack=true
	lab.reset_round()
	await tick(14)
	court=lab.pump_court
	e=lab.enemies[0] as EnemyLabWarden
	await tick(45)
	check("sentry water cast remains independent of level pump",e.move_key=="warden_barrage" and e.state=="tell")
	key(KEY_D,true)
	await tick(25)
	key(KEY_D,false)
	key(KEY_F,true)
	await tick(3)
	key(KEY_F,false)
	check("actual approach reaches and operates relief valve",court.vents==1)
	key(KEY_D,true)
	key(KEY_SPACE,true)
	await tick(30)
	key(KEY_SPACE,false)
	for frame: int in 180:
		await tick(1)
		if lab.route_passed or lab.player.health<=0: break
	key(KEY_D,false)
	print("PUMP_ROUTE hp=",lab.player.health," vents=",court.vents," passed=",lab.route_passed," player=",lab.player.position," enemy=",e.position," move=",e.move_key," state=",e.state)
	check("real D F jump route reaches safe line with living sentry",lab.route_passed and lab.player.health>0 and e.data.alive)
	check("crossing safety line immediately clears active water",court.stopped and not court.view.jet.visible and lab.player.pump_drift==0.0)
	var time: float=court.clock
	await tick(45)
	check("pump continues harmless work after encounter",court.clock>time and e.state=="ended")
	await shot("pump-route-success")
	await tap(KEY_R)
	await tick(12)
	check("actual R recreates pressure and clears relief state",not is_instance_valid(court) and lab.pump_court.vents==0 and not lab.pump_court.stopped)
	court=await setup_court()
	lab.player.position=Vector2(900,520)
	court.manual=true
	court.phase="stroke"
	court.timer=0.15
	await tick(48)
	key(KEY_D,true)
	for frame: int in 70:
		await tick(1)
		if lab.route_passed: break
	key(KEY_D,false)
	check("timed D crossing during release works without valve",lab.route_passed and court.vents==0 and lab.player.health==5)
	print("ENEMY_LAB_PUMP failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
