extends TestSuite
## 验证真实释放边界、独立FX索引、完整交互和持盾呈现，不移动战斗时钟。

func test_phase_mapping_never_shows_cutting_arc_before_release() -> void:
	var phases := TideVisualPhaseMap.new()
	phases.load_manifest("res://art/tide-picker-action36/")
	var profile: Dictionary = phases.profiles.strike1
	for fraction: float in [0.0,0.1,0.2,0.3953488372-0.00001]:
		check(TideVisualPhaseMap.phase_index(profile,fraction,0.3953488372) <= int(profile.prepare.back()),"preparation has no cutting arc")
	eq(profile.prepare.size(),6,"basic slash has six actual preparation drawings")
	eq(TideVisualPhaseMap.phase_index(profile,0.3953488372,0.3953488372),6,"actual release begins the cut")
	for key: String in ["great_slash","cyclone","dash_slash","up_spell"]:
		var p: Dictionary = phases.profiles[key]
		check(TideVisualPhaseMap.phase_index(p,0.49999,0.5) == int(p.prepare.back()),"last preparation remains before release "+key)
		eq(TideVisualPhaseMap.phase_index(p,0.5,0.5),int(p.release[0]),"cut/cast begins at release "+key)

func test_override_keeps_old_fx_and_new_body_independent() -> void:
	var phases := TideVisualPhaseMap.new()
	var manifest: Dictionary = phases.load_manifest("res://art/tide-picker-action36/")
	eq(int(manifest.abyss_scream.frame_count),16,"new body has sixteen authored frames")
	eq(int(manifest.abyss_scream.fx_frame_count),20,"old FX keeps twenty source slots")
	eq(manifest.abyss_scream.fx.frames.size(),20,"FX survives body overlay merge")
	for key: String in ["strike2","abyss_scream","interact","parry"]:
		check(ResourceLoader.exists(str(manifest[key].body.texture)),"new bitmap imported "+key)
	for key: String in ["strike1","upper","heavy","orb","up_spell","great_slash","cyclone","dive"]:
		eq(int(manifest[key].frame_count),16,"core family has sixteen authored body frames "+key)
		eq(phases.profiles[key].prepare.size(),6,"core family has six actual preparation drawings "+key)

func test_dive_never_shows_ground_recovery_until_actual_landing() -> void:
	var phases := TideVisualPhaseMap.new()
	var manifest: Dictionary = phases.load_manifest("res://art/tide-picker-action36/")
	var player := TidePlayer.new()
	var controller := TideSkillController.new()
	player.skill_controller = controller
	controller.active = true
	controller.visual_key = "dive"
	controller.data = {"release":0.14}
	controller.duration = 2.0
	controller.elapsed = 0.10
	check(phases.body_index("dive",manifest.dive,0.2,player,0.01) < 6,"airborne startup only uses preparation")
	controller.elapsed = 0.30
	for i: int in 40:
		var index: int = phases.body_index("dive",manifest.dive,0.4375,player,1.0/60.0)
		check(index >= 6 and index <= 9,"airborne loop never contains a ground impact pose")
	controller.landed = true
	controller.landed_at = 0.30
	controller.duration = 0.54
	eq(phases.body_index("dive",manifest.dive,0.5,player,0.0),10,"actual landing selects first grounded recovery frame")
	controller.elapsed = 0.539
	eq(phases.body_index("dive",manifest.dive,0.99,player,0.0),15,"landing recovery reaches its final frame")
	check(is_equal_approx(controller.elapsed,0.539),"presentation never moves landing clock")
	player.free()

func test_interaction_reaches_final_new_body_frame() -> void:
	var player := TidePlayer.new()
	var controller := TideSkillController.new()
	player.skill_controller = controller
	player.state_duration = 0.5
	player.state_time = 0.499
	var phases := TideVisualPhaseMap.new()
	var manifest: Dictionary = phases.load_manifest("res://art/tide-picker-action36/")
	eq(phases.body_index("interact",manifest.interact,0.46,player,0.0),15,"end mapping does not truncate recovery")
	check(is_equal_approx(player.state_time,0.499),"presentation never writes state clock")
	player.free()

func test_guard_loop_has_four_real_frames_and_preserves_defense_clock() -> void:
	var phases := TideVisualPhaseMap.new()
	var manifest: Dictionary = phases.load_manifest("res://art/tide-picker-action36/")
	var player := TidePlayer.new()
	var controller := TideSkillController.new()
	player.skill_controller = controller
	controller.active = true
	controller.visual_key = "parry"
	controller.elapsed = 0.48
	controller.duration = 0.70
	controller.data = {"release":0.02,"parry_end":0.55}
	var seen: Dictionary = {}
	for i: int in 40:
		var frame: int = phases.body_index("parry",manifest.parry,0.25,player,1.0/60.0)
		seen[frame] = true
		check(frame >= 3 and frame <= 6,"held guard never lowers fork")
	eq(seen.size(),4,"four unique held guard frames play")
	check(is_equal_approx(controller.elapsed,0.48),"held defense clock stays unchanged")
	player.free()

func test_startup_effects_read_every_combat_family_without_changing_release() -> void:
	var phases := TideVisualPhaseMap.new()
	phases.load_manifest("res://art/tide-picker-action36/")
	for key: String in TideSkillCatalog.ACTIONS:
		check(phases.skill_families.has(key),"catalog skill has startup family "+key)
	for key: String in TideCombatSkills.DEFINITIONS:
		check(phases.skill_families.has(key),"common combat skill has startup family "+key)
	check(TideStartupEffects.startup_strength(0.049,0.05,[]) > 0.0,"real short startup has a cue")
	eq(TideStartupEffects.startup_strength(0.2,0.05,[]),0.0,"release tail is bounded")
	check(TideStartupEffects.startup_strength(0.23,0.1,[0.1,0.24,0.38]) > 0.0,"later pulse receives its own gathering cue")

func test_melee_startup_matches_campaign_profile_fixture_and_live_timeline() -> void:
	var scene: Node = load("res://content/whalebelly/CampaignPlayer.tscn").instantiate()
	check(is_equal_approx(float(scene.melee_startup),0.10),"campaign default is 100ms")
	var profile := TidePlayer.new()
	WhalebellyCampaignProfile.apply(profile)
	check(is_equal_approx(profile.melee_startup,float(scene.melee_startup)),"parameter fixture matches campaign scene")
	profile.free()
	scene.free()
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	arena.enemy.auto_attack = false
	await physics_frames(8)
	var player: CombatWhiteboxPlayer = arena.player
	check(is_equal_approx(player.melee_startup,0.10),"whitebox shares 100ms startup")
	var hits: Array[float] = []
	player.hit_resolved.connect(func(_target: Node,_area: Rect2,_key: String,_direction: float) -> void: hits.append(player.state_time))
	check(player.request_action("strike_01"),"real basic attack begins")
	var timeline: Dictionary = CombatWhiteboxTimelineData.sample(player,arena.enemy)
	check(is_equal_approx(float(timeline.release),0.10),"UI reads actual startup instead of old 50ms")
	check(is_equal_approx(player.state_duration,0.35),"total action duration stays unchanged")
	for i: int in 16:
		await physics_frames(1)
		if player.state_time < 0.10-0.00001: eq(arena.enemy.health,12,"target cannot take early startup damage")
		if not hits.is_empty(): break
	check(not hits.is_empty(),"real attack reaches target")
	if not hits.is_empty(): check(hits[0] >= 0.10-0.00001,"first damage waits for 100ms")
	for i: int in 20:
		if player._offense_released(): break
		await physics_frames(1)
	check(player.request_action("A1_dash"),"existing recovery defense cancel remains available")
	arena.reset_arena()
	await physics_frames(8)
	check(player.request_action("strike_01"),"next startup begins")
	await physics_frames(3)
	check(player.try_backstep(),"backstep still cancels before new startup release")
	await physics_frames(35)
	eq(arena.enemy.health,12,"cancelled startup never creates delayed damage")
