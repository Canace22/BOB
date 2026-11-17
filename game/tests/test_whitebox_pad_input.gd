extends TestSuite
## 从真实键盘事件进入InputMap，验证组合优先、连招、蓄力和清理。

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func fixture() -> Node2D:
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func after_each() -> void:
	for code: int in [KEY_Q,KEY_E,KEY_J,KEY_K,KEY_I,KEY_L,KEY_W,KEY_A,KEY_S,KEY_D,KEY_ESCAPE,KEY_SPACE,KEY_SHIFT]: key(code,false)
	await physics_frames(1)
	await super.after_each()

func test_shoulders_alone_are_modifiers_and_base_faces_still_work() -> void:
	var arena := await fixture()
	key(KEY_Q,true)
	key(KEY_E,true)
	await physics_frames(3)
	check(not arena.player.skill_controller.active and arena.player.state_duration <= 0,"shoulders alone neither attack nor interact")
	key(KEY_Q,false)
	key(KEY_E,false)
	key(KEY_ESCAPE,true)
	await physics_frames(2)
	key(KEY_ESCAPE,false)
	key(KEY_I,true)
	await physics_frames(3)
	eq(arena.player.skill_controller.visual_key,"parry","I is guard, not heavy")
	arena.reset_arena()
	await physics_frames(3)
	key(KEY_SPACE,true)
	await physics_frames(4)
	check(arena.player.position.y < 540,"Space jumps")

func test_q_layer_all_four_skills_without_base_actions() -> void:
	var arena := await fixture()
	var keys: Array[int] = [KEY_J,KEY_K,KEY_I,KEY_L]
	for i: int in 4:
		arena.reset_arena()
		await physics_frames(3)
		key(KEY_Q,true)
		key(keys[i],true)
		await physics_frames(3)
		eq(arena.player.skill_controller.visual_key,CombatWhiteboxPadInput.LT[i],"Q chord routes exactly one selected skill")
		check(arena.player.is_on_floor(),"Q+K does not also jump")
		key(keys[i],false)
		key(KEY_Q,false)
		await physics_frames(2)

func test_e_layer_attack_spell_and_directional_variants() -> void:
	var arena := await fixture()
	key(KEY_E,true)
	key(KEY_J,true)
	await physics_frames(3)
	eq(arena.player.skill_controller.visual_key,"wb_flurry","E+J routes flurry, no basic attack")
	key(KEY_J,false)
	arena.reset_arena()
	await physics_frames(3)
	key(KEY_W,true)
	key(KEY_L,true)
	await physics_frames(3)
	eq(arena.player.skill_controller.visual_key,"up_spell","W+E+L routes upward spell instead of dash")
	key(KEY_L,false)
	key(KEY_W,false)
	arena.reset_arena()
	key(KEY_E,false)
	await physics_frames(3)
	key(KEY_SPACE,true)
	await physics_frames(9)
	key(KEY_SPACE,false)
	key(KEY_S,true)
	key(KEY_E,true)
	key(KEY_L,true)
	await physics_frames(3)
	eq(arena.player.skill_controller.visual_key,"dive","air S+E+L dives instead of backstep")

func test_triple_chord_repeats_and_can_change_direction() -> void:
	var arena := await fixture()
	key(KEY_Q,true)
	for step: int in 3:
		if step == 2: key(KEY_A,true)
		key(KEY_K,true)
		await physics_frames(3)
		eq(arena.player.skill_controller.drive_step,step+1,"each face press starts one triple segment")
		key(KEY_K,false)
		await physics_frames(20)
	check(arena.player.skill_controller.locked_facing < 0,"last segment turns with A")

func test_down_dash_cancels_attack_and_j_backcuts() -> void:
	var arena := await fixture()
	key(KEY_E,true)
	key(KEY_J,true)
	await physics_frames(3)
	key(KEY_E,false)
	key(KEY_J,false)
	key(KEY_S,true)
	key(KEY_L,true)
	await physics_frames(3)
	check(arena.player.retreating,"S+L cancels skill into real backstep")
	check(arena.player.invulnerable <= 0,"backstep does not also trigger dash immunity")
	key(KEY_J,true)
	await physics_frames(2)
	eq(arena.player.skill_controller.visual_key,"wb_backcut","J follows backstep with cut")

func test_hold_heal_releases_without_guard_and_long_dash_charges() -> void:
	var arena := await fixture()
	arena.player.health = 3
	key(KEY_E,true)
	key(KEY_I,true)
	await physics_frames(10)
	eq(arena.player.state,"recover","E+I holds recovery rather than guard")
	key(KEY_I,false)
	await physics_frames(3)
	check(arena.player.state != "recover","releasing face cancels recovery")
	eq(arena.player.health,3,"cancelled heal does not grant health")
	arena.reset_arena()
	await physics_frames(3)
	key(KEY_Q,true)
	key(KEY_L,true)
	await physics_frames(45)
	check(arena.player.pad_input.long_seconds >= 0.6,"both shoulders plus L reaches full charge")
	key(KEY_L,false)
	await physics_frames(3)
	eq(arena.player.skill_controller.visual_key,"crystal_dash","release launches long dash")
	check(arena.player.skill_controller.active,"charged dash is actually active")

func test_modifier_changes_do_not_release_phantom_charged_attack() -> void:
	var arena := await fixture()
	key(KEY_J,true)
	await physics_frames(42)
	key(KEY_Q,true)
	await physics_frames(3)
	key(KEY_J,false)
	key(KEY_Q,false)
	await physics_frames(6)
	check(not arena.player.skill_controller.active,"changing page discards old J charge without heavy release")

func test_inputmap_is_restored_when_whitebox_leaves_tree() -> void:
	var before: Array[InputEvent] = InputMap.action_get_events("tp_attack")
	var arena := await fixture()
	arena.queue_free()
	await physics_frames(3)
	var after: Array[InputEvent] = InputMap.action_get_events("tp_attack")
	eq(after.size(),before.size(),"original action event count restored")
	for i: int in before.size():
		eq(after[i].as_text(),before[i].as_text(),"original action binding restored")

func test_physical_chord_and_utility_page_do_not_trigger_old_shortcuts() -> void:
	var arena := await fixture()
	for code: int in [KEY_Q,KEY_K]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = true
		Input.parse_input_event(event)
	await physics_frames(3)
	eq(arena.player.skill_controller.visual_key,"wb_drive","hardware scan codes reach the same chord route")
	for code: int in [KEY_Q,KEY_K]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = false
		Input.parse_input_event(event)
	await physics_frames(3)
	for pair: Array in [[KEY_J,"scan"],[KEY_K,"A5_slit"],[KEY_I,"heavy"]]:
		arena.reset_arena()
		await physics_frames(3)
		key(KEY_Q,true)
		key(KEY_E,true)
		key(pair[0],true)
		await physics_frames(3)
		eq(arena.player.skill_controller.visual_key if pair[1]=="scan" else arena.player.state,pair[1],"both modifiers select utility page")
		key(pair[0],false)
		await physics_frames(2)
	key(KEY_Q,false)
	key(KEY_E,false)
	arena.reset_arena()
	await physics_frames(3)
	key(KEY_3,true)
	await physics_frames(3)
	check(not arena.player.skill_controller.active,"old numeric combat key removed")
	key(KEY_3,false)

func test_chord_buffer_reaches_recovery_and_held_face_does_not_repeat() -> void:
	var arena := await fixture()
	check(arena.player.request_action("wb_rise"),"first skill starts")
	await physics_frames(2)
	key(KEY_Q,true)
	key(KEY_I,true)
	await physics_frames(9)
	eq(arena.player.skill_controller.visual_key,"wb_draw","short input buffer chains when previous skill releases")
	await physics_frames(50)
	check(not arena.player.skill_controller.active,"held face never repeats skill")
