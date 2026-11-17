extends SceneTree
## 正式主场景专项；真实键事件，独立QA存档，夹具只布置敌人与技能状态。
var host: WhalebellyMain
var failures: int = 0
const OUTPUT := "res://build/qa/combat-main"
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	press(code,true)
	await tick(2)
	press(code,false)
	await tick(2)
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))
func reset(p: TideCombatPlayer) -> void:
	for code: Key in [KEY_Q,KEY_E,KEY_J,KEY_K,KEY_I,KEY_L,KEY_S,KEY_A,KEY_D]: press(code,false)
	p.clear_combat_input()
	p.skill_controller.cancel()
	p.state = "idle"
	p.state_duration = 0.0
	p.hitstop = 0.0
	p.recoil_left = 0.0
	p.velocity = Vector2.ZERO
	for key: String in p.cooldowns: p.cooldowns[key] = 0.0
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","combat-main")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(45)
	var p: WhalebellyCampaignPlayer = host.player
	p.invulnerable = 100
	check("formal scene uses shared combat and exactly one visual",p is TideCombatPlayer and p.run_visual == p.action_visual)
	check("new run keeps dash and flurry locked",not p.ability_available("A1_dash") and not p.ability_available("wb_flurry"))
	await tap(KEY_Q)
	check("Q selects page without old attack",p.pad_input.effective_page()==1 and p.state_duration<=0)
	var rows: Array[Dictionary] = TideCombatHints.rows(p)
	check("Q HUD four columns follow real bindings",rows.size()==4 and rows[0].action=="wb_rise" and rows[3].action=="wb_charge")
	check("combo page reuses bottom skill bar",host.player_ui.hud.combo_hud.position.y>=root.size.y-80)
	await shot("01-q-page")
	await tap(KEY_J)
	check("Q then J starts uppercut",p.skill_controller.visual_key=="wb_rise")
	check("consumed skill page clears",p.pad_input.effective_page()==0)
	check("HUD reports actual uppercut cooldown",TideCombatHints.status(p,"wb_rise").begins_with("冷却"))
	await tick(38)
	await tap(KEY_E)
	rows = TideCombatHints.rows(p)
	check("E selects page and shows real progression lock",p.pad_input.effective_page()==2 and rows[0].status=="未解锁" and rows[1].status=="未解锁")
	await shot("02-e-locked")
	await tap(KEY_J)
	check("locked flurry cannot bypass normal progress",p.skill_controller.visual_key!="wb_flurry")
	reset(p)
	await tick(4)
	await tap(KEY_Q)
	await tap(KEY_E)
	check("sequential Q E selects auxiliary page",p.pad_input.effective_page()==3 and TideCombatHints.rows(p)[3].action=="crystal_dash")
	await shot("03-both-page")
	await tick(55)
	check("preview expires",p.pad_input.effective_page()==0)
	host.qa_full_abilities = true
	reset(p)
	await tick(4)
	await tap(KEY_E)
	check("earned skills available without different HUD list",TideCombatHints.rows(p)[0].status=="可用")
	p.soul = 0
	check("HUD reports resource shortage",TideCombatHints.status(p,"A4_parry")=="蓄振不足")
	p.soul = p.max_soul
	await shot("04-e-unlocked")
	await tap(KEY_J)
	check("E J uses five-hit skill",p.skill_controller.visual_key=="wb_flurry")
	press(KEY_S,true)
	await tap(KEY_L)
	press(KEY_S,false)
	print("BACKSTEP_TRACE retreat=",p.retreating," floor=",p.is_on_floor()," state=",p.state," ghosts=",p.afterimage.ghosts.size()," time=",p.retreat_time," velocity=",p.velocity)
	check("backstep cancels flurry with captured pose",p.retreating and not p.skill_controller.active and not p.afterimage.ghosts.is_empty())
	await shot("05-backstep")
	await tick(50)
	reset(p)
	await tick(4)
	press(KEY_D,true)
	await tap(KEY_J)
	var start: float = p.position.x
	await tick(6)
	check("ground basic attack remains planted",absf(p.position.x-start)<1.0)
	press(KEY_D,false)
	await tick(36)
	reset(p)
	await tick(4)
	# 真实尸蟹，生命和击败仍由主线宿主结算。
	var crab := CampaignCorpseCrab.new()
	crab.host = host
	crab.data = {"key":"qa-combat-crab","boss":false,"alive":true,"hp":8,"max_hp":8,"hurt":0.0,"pos":p.position+Vector2(70,0)}
	p.get_parent().add_child(crab)
	crab.set_physics_process(false)
	crab.position = p.position-Vector2(90,0)
	var camp_art: CanvasItem=host.scenery.get_node("World/CampArt") if host.room.has("layout") else host.scenery.get_node("ReferenceEnvironment/PORTAL")
	check("enemy shares player layer above camp artwork",crab.z_index==p.z_index and crab.z_index>camp_art.z_index)
	await shot("00-camp-enemy-layer")
	crab.position = p.position+Vector2(70,0)
	crab.data.pos = crab.position
	crab.set_physics_process(true)
	p.facing = 1.0
	var count: int = p.hit_feedback.event_count
	p.request_action("strike_01")
	await tick(9)
	check("formal enemy receives real damage and contact feedback",int(crab.data.hp)<8 and p.hit_feedback.event_count>count)
	check("Combo counts actual formal enemy hits",(p.skill_controller as TideCombatSkills).combo_hits>0)
	check("ordinary hit does not freeze entire world",is_equal_approx(Engine.time_scale,1.0))
	await shot("06-contact")
	await tick(30)
	reset(p)
	await tick(4)
	p.facing = 1.0
	crab.position = p.position+Vector2(60,0)
	crab.data.pos = crab.position
	p.request_action("wb_rise")
	await tick(14)
	check("uppercut physically launches normal enemy",crab.launch_left>0 and crab.velocity.y<0)
	await tick(90)
	check("launched enemy falls onto real terrain",crab.is_on_floor())
	reset(p)
	await tick(4)
	crab.position = p.position+Vector2(60,0)
	crab.data.pos = crab.position
	crab.data.hp = 1
	crab.change("idle")
	p.facing = 1.0
	count = p.hit_feedback.event_count
	p.request_action("strike_01")
	await tick(12)
	check("kill still has feedback after target leaves group",not crab.data.alive and p.hit_feedback.event_count>count and p.hit_feedback.last_point.length()>1)
	reset(p)
	await tick(4)
	press(KEY_Q,true)
	await tick(2)
	host.player_ui.open("pause")
	check("pause clears selected input and ghosts",p.pad_input.selected_page==0 and p.afterimage.ghosts.is_empty())
	press(KEY_Q,false)
	host.player_ui.back()
	# process_frame continues while pause waits for released game keys.
	for i: int in 25: await process_frame
	check("resume does not replay selected skill",p.pad_input.selected_page==0)
	if paused: paused=false
	await tick(5)
	check("F is the actual interaction binding",WhaleUIStyle.key("tp_interact")=="F")
	reset(p)
	await tick(5)
	await tap(KEY_F)
	check("F starts real campaign interaction",p.state=="interact")
	await tick(45)
	# 显式重建到Boss房只用于合同回归，不当作自然通关证据。
	crab.queue_free()
	await tick(2)
	host.load_room(3)
	await tick(60)
	p = host.player
	p.invulnerable = 100
	var boss: CampaignCrabBoss = host.enemies[0].actor
	boss.change("tell")
	boss.kind = "sweep"
	boss.running = true
	boss.timer = 0.0
	p.position = boss.position-Vector2(180,0)
	p.facing = 1
	reset(p)
	await tick(4)
	var hp: int = int(boss.data.hp)
	var boss_y: float = boss.position.y
	p.request_action("wb_rise")
	await tick(12)
	check("Boss damage still follows original shell reduction",int(boss.data.hp)==hp-5)
	check("Boss armor keeps tell pose and cannot be launched",boss.state=="tell" and is_equal_approx(boss.position.y,boss_y) and boss.feedback.power<6.0)
	await shot("07-boss-feedback")
	print("COMBAT_MAIN failures=",failures)
	host.queue_free()
	await tick(5)
	quit(0 if failures==0 else 1)
