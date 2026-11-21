extends "res://tests/whalebelly/combat_main_qa.gd"
## 正式入口真实输入验收；房间/目标敌人为显式夹具，不等同自然通关。
class Target extends Node2D:
	var hits: int = 0
	var data: Dictionary = {"boss":false}
	func is_campaign_enemy() -> bool: return true
	func _ready() -> void: add_to_group("tide_targets")
	func can_receive_hit() -> bool: return true
	func hurt_rect() -> Rect2: return Rect2(global_position-Vector2(20,85),Vector2(40,85))
	func take_hit(_amount: int) -> void: hits+=1

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","action-hud")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(60)
	var ui: WhaleCampaignUI = host.player_ui
	var hud: WhaleCampaignHUD = ui.hud
	var p: TideCombatPlayer = host.player
	p.invulnerable = 100
	check("vitals and objective occupy upper corners",hud.vitals.position.y<40 and hud.objective_hud.position.x>800)
	check("minimap uses small square-room topology",hud.minimap.size.x<=140 and hud.minimap.positions.has(host.room_index))
	check("skill dock stays compact and clear of player",hud.combo_hud.size.x<=root.size.x*0.30 and hud.combo_hud.position.y>550)
	check("zero combo is hidden",not hud.counter_hud.visible)
	check("ordinary page has four dim direction entries",hud.combo_hud.page==0 and hud.combo_hud.derived.size()==4 and not hud.combo_hud.derived.any(func(row: Dictionary) -> bool: return row.active))
	await shot("action-hud-idle")
	press(KEY_D,true)
	await tick(5)
	check("D activates only horizontal derivations",hud.combo_hud.derived[2].active and hud.combo_hud.derived[3].active and not hud.combo_hud.derived[0].active)
	await shot("action-hud-direction")
	press(KEY_D,false)
	press(KEY_W,true)
	await tick(4)
	check("W activates uppercut icon",hud.combo_hud.derived[0].active and not hud.combo_hud.derived[2].active)
	press(KEY_W,false)
	await tap(KEY_Q)
	check("Q changes icon page using actual action table",hud.combo_hud.page==1 and hud.combo_hud.rows.size()==4 and hud.combo_hud.rows[0].action=="wb_rise")
	await shot("action-hud-q")
	await tap(KEY_J)
	check("Q J still performs uppercut",p.skill_controller.visual_key=="wb_rise")
	await tick(45)
	reset(p)
	await tap(KEY_E)
	check("E page shows true progression lock",hud.combo_hud.rows[0].status=="未解锁")
	await shot("action-hud-e-locked")
	reset(p)
	var target := Target.new()
	host.add_child(target)
	for expected: int in [1,2,3]:
		reset(p)
		p.facing = 1
		target.global_position = p.global_position+Vector2(85,0)
		await tap(KEY_J)
		for frame: int in 35:
			await tick(1)
			if target.hits>=expected: break
		await process_frame
		check("real J updates animated combo %d" % expected,target.hits==expected and hud.counter_hud.visible and hud.counter_hud.display_count==expected and hud.counter_hud.hit_age<hud.counter_hud.HIT_TIME)
	await shot("action-hud-combo")
	await tick(30)
	await shot("action-hud-combo-settled")
	await tick(120)
	check("combo expires and hides",not hud.counter_hud.visible)
	target.queue_free()
	# 回到营地位置后用实际F输入验证交互，按钮不能因为视觉缩小失效。
	p.position = host.point(ui.data.camp_position())
	await tick(10)
	var prompt: WhaleInteractionPrompt = hud.interaction_prompt
	check("interaction capsule hugs dock upper edge",prompt.visible and absf(prompt.card_rect.end.y-(hud.combo_hud.position.y-8))<5 and absf(prompt.card_rect.end.x-(hud.combo_hud.position.x+hud.combo_hud.size.x))<1)
	await shot("action-hud-camp")
	await tap(KEY_F)
	await tick(55)
	check("actual F still opens camp and hides gameplay HUD",ui.page_id=="camp" and not hud.is_visible_in_tree())
	ui.close_all()
	await tick(20)
	await tap(KEY_ESCAPE)
	check("Esc pause remains available",ui.page_id=="pause")
	await tap(KEY_ESCAPE)
	await tick(20)
	await tap(KEY_C)
	check("C still opens complete map",ui.page_id=="map")
	await tap(KEY_ESCAPE)
	await tick(20)
	# 多出口用正式须筛房间夹具；不更改发现/能力去迎合指引。
	var index: int = host.rooms.find_custom(func(room: Dictionary) -> bool: return str(room.id)=="R1-02")
	host.load_room(index)
	await tick(60)
	check("all junction exits visible simultaneously",hud.route_hud.routes.size()>=3 and hud.route_hud.markers.size()==hud.route_hud.routes.size())
	check("blocked branches carry a requirement",hud.route_hud.routes.any(func(route: Dictionary) -> bool: return route.blocked and not str(route.detail).is_empty()))
	await shot("action-hud-junction")
	root.size = Vector2i(960,540)
	await tick(10)
	await shot("action-hud-small-window")
	paused = false
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for tween: Tween in get_processed_tweens(): tween.kill()
	for sound: Node in host.find_children("*","AudioStreamPlayer",true,false):
		sound.stop()
		sound.stream = null
	host.sound_bank.clear()
	host.sound_variants.clear()
	await create_timer(0.35).timeout
	root.remove_child(host)
	host.free()
	await tick(3)
	print("ACTION_HUD_QA failures=",failures)
	quit(1 if failures else 0)
