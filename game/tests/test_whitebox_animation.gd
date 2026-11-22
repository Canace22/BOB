extends TestSuite
## 使用真实位图与状态，检查动画选择、发力帧、取消覆盖与物理独立。

func fixture() -> Node2D:
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func after_each() -> void:
	for action: String in ["tp_right","tp_left"]: Input.action_release(action)
	await super.after_each()

func test_real_character_atlas_loads_and_gait_responds_to_travel() -> void:
	var arena := await fixture()
	var view: CombatWhiteboxActionVisual = arena.player.action_visual
	check(view.active and view.sprite.texture != null,"real character texture loaded")
	check(not arena.player.body.visible,"legacy body hidden to avoid double rendering")
	var bottom: float = float(view.sprite.texture.get_image().get_used_rect().end.y)
	check(absf(view.sprite.offset.y+bottom) < 0.01,"visible standing foot aligns with physical origin")
	Input.action_press("tp_right")
	await physics_frames(5)
	var first: int = view.frame_index
	await physics_frames(5)
	check(view.current_key == "run","movement selects run atlas")
	check(view.frame_index != first,"run actually advances frames")
	Input.action_release("tp_right")

func test_rise_and_charge_align_authored_event_to_actual_hit_time() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	var view: CombatWhiteboxActionVisual = p.action_visual
	for key: String in ["wb_rise","wb_charge"]:
		arena.reset_arena()
		await physics_frames(3)
		check(p.request_action(key),"skill starts "+key)
		var spec: Dictionary = view.manifest.upper
		var actual_time: float = float(p.skill_controller.data.release)
		# 只取动画采样值，不运行命中；边界必须与真实skill release保持一致。
		p.state_time = actual_time
		var fraction: float = view.frame_fraction("upper",spec,0.0,0.0)
		check(absf(fraction-float(spec.event_phase)) < 0.001,"event frame aligned for "+key)

func test_flurry_replays_five_authored_strokes_at_five_hit_markers() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	var view: CombatWhiteboxActionVisual = p.action_visual
	check(p.request_action("wb_flurry"),"flurry starts")
	for i: int in 5:
		p.state_time = CombatWhiteboxActionVisual.FLURRY_HITS[i]
		var key: String = view.choose_key(0.0)
		eq(key,CombatWhiteboxActionVisual.FLURRY_KEYS[i],"correct authored stroke at hit %d" % i)
		var spec: Dictionary = view.manifest[key]
		check(absf(view.frame_fraction(key,spec,0.0,0.0)-float(spec.event_phase)) < 0.001,"all five contacts aligned")

func test_defense_and_backstep_cancel_replace_attack_visual() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	var view: CombatWhiteboxActionVisual = p.action_visual
	check(p.request_action("wb_draw"),"sweep starts")
	await physics_frames(2)
	eq(view.current_key,"great_slash","sweep uses real heavy slash")
	check(p.try_backstep(),"backstep cancels")
	await physics_frames(2)
	eq(view.current_key,"jump","cancel stops slash body and FX")
	check(not view.effect.visible,"cancelled effect hidden")
	arena.reset_arena()
	await physics_frames(4)
	check(p.request_action("parry"),"guard starts")
	await physics_frames(3)
	eq(view.current_key,"parry","guard pose appears")

func test_enemy_uses_real_animated_crab_and_debug_is_optional() -> void:
	var arena := await fixture()
	var enemy: CombatWhiteboxEnemy = arena.enemy
	check(enemy.action_visual.texture != null,"crab atlas loaded")
	check(not enemy.show_debug and not arena.player.show_debug,"geometry overlay off by default")
	enemy.begin_attack()
	await physics_frames(7)
	enemy.action_visual.present(enemy)
	eq(enemy.action_visual.action_id,"tell","windup uses authored tell")
	var first: int = enemy.action_visual.frame_index
	await physics_frames(15)
	enemy.action_visual.present(enemy)
	check(enemy.action_visual.frame_index != first,"windup frame advances")
	enemy.state = "airborne"
	enemy.action_visual.present(enemy)
	eq(enemy.action_visual.action_id,"hurt","airborne explicitly reuses hurt pose")

func test_guard_contact_pose_covers_entire_real_defense_window() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("parry"),"guard starts")
	var c: TideSkillController = p.skill_controller
	var view: CombatWhiteboxActionVisual = p.action_visual
	var spec: Dictionary = view.manifest.parry
	for time: float in [float(c.data.release),0.12,float(c.data.parry_end)]:
		c.elapsed = time
		var fraction: float = view.frame_fraction("parry",spec,0.0,0.0)
		eq(int(fraction*float(spec.frame_count)),2,"raised fork stays in contact pose throughout defense window")
	c.elapsed = 0.32
	check(view.frame_fraction("parry",spec,0.0,0.0) > 0.5,"fork retracts during actual recovery")

func test_guard_bitmap_faces_attack_and_clears_on_backstep() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	p.facing = -1.0
	check(p.request_action("parry"),"left guard starts")
	await physics_frames(6)
	var ring: Sprite2D = p.action_visual.guard_ring
	check(ring.visible and ring.texture != null,"authored guard bitmap visible")
	check(ring.position.x < 0.0,"guard is on facing side")
	check(p.skill_controller.parry_damage(p.position+Vector2(-100,0)),"real left attack blocked")
	await physics_frames(2)
	check(ring.modulate.r > 0.9 and ring.scale.x > 0.30,"successful block turns gold and expands")
	check(p.try_backstep(),"backstep cancels guard")
	await physics_frames(2)
	check(not ring.visible,"cancel leaves no false defense visual")

func test_combat_uses_atlas_only_without_render_texture_readback() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.atlas_visual_enabled,"atlas mode prevents hidden legacy library loads")
	check(p.request_action("wb_flurry"),"attack starts")
	await physics_frames(20)
	check(p.textures.heavy[0] == p.textures.idle[0],"hidden body reuses idle rather than decoding 36 legacy frames")
	eq(p.action_visual.foot_reads,0,"combat frame does not read GPU texture pixels")

func test_precomputed_feet_match_current_source_atlases() -> void:
	var arena := await fixture()
	var view: CombatWhiteboxActionVisual = arena.player.action_visual
	for key: String in view.WARM_KEYS:
		var spec: Dictionary=view.manifest[key]
		var body: Dictionary = spec.body
		if bool(spec.get("authored_pivot",false)):
			eq(body.pivot,[128.0,224.0],"authored atlas keeps common root pivot: "+key)
			eq(str(body.get("sha256","")),FileAccess.get_sha256(str(body.texture)),"authored atlas hash matches its own exported metadata: "+key)
			eq(body.frames.size(),int(spec.frame_count),"authored atlas has complete frame rectangles: "+key)
		else:
			var item: Dictionary = view.foot_metadata[key]
			eq(item.frames,body.frames,"legacy foot registration layout remains current: "+key)
			eq(item.sha256,FileAccess.get_sha256(str(body.texture)),"legacy foot registration hash remains current: "+key)
			eq(item.bottom.size(),body.frames.size(),"all legacy frames keep foot data: "+key)
		check(view.pinned_clips.has(key),"combat atlas warmed before input: "+key)

func test_real_combat_renderer_retains_authored_pivot_through_late_frames() -> void:
	var arena := await fixture()
	arena.enemy.auto_attack=false
	var p: CombatWhiteboxPlayer=arena.player
	check(p.request_action("strike_01"),"real sixteen-frame swing begins")
	var seen_late: bool=false
	for i: int in 32:
		await physics_frames(1)
		var view: CombatWhiteboxActionVisual=p.action_visual
		if view.current_key!="strike1": continue
		eq(view.sprite.offset,Vector2(-128,-224),"production apply_layer bypasses obsolete twelve-slot feet")
		if view.frame_index>=12: seen_late=true
	check(seen_late,"production actually draws frames beyond the old twelve-slot table")

func test_backstep_white_afterimage_stays_at_cancel_point_and_expires() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	var source: Sprite2D = p.action_visual.sprite
	var texture: Texture2D = source.texture
	var origin: Transform2D = source.global_transform
	check(p.try_backstep(),"backstep starts")
	eq(p.afterimage.ghosts.size(),1,"one afterimage per successful backstep")
	var ghost: Sprite2D = p.afterimage.ghosts[0].node
	eq(ghost.texture,texture,"same frame reused without pixel readback")
	eq(ghost.global_transform,origin,"starts at exact original pose transform")
	var alpha: float = ghost.modulate.a
	await physics_frames(5)
	eq(ghost.global_transform,origin,"ghost stays fixed while actor retreats")
	check(p.position.x < 550,"actor moved away")
	check(ghost.modulate.a < alpha,"ghost fades")
	await physics_frames(15)
	eq(p.afterimage.ghosts.size(),0,"ghost expires and is released")

func test_failed_backstep_does_not_emit_white_afterimage() -> void:
	var arena := await fixture()
	arena.player.backstep_enabled = false
	check(not arena.player.try_backstep(),"disabled backstep rejected")
	eq(arena.player.afterimage.ghosts.size(),0,"no ghost for rejected input")

func test_afterimage_freezes_interrupted_attack_frame_not_backstep_pose() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_draw"),"attack starts")
	await physics_frames(9)
	eq(p.action_visual.current_key,"great_slash","attack pose is actually displayed")
	var source: Sprite2D = p.action_visual.sprite
	var frozen_texture: Texture2D = source.texture
	var frozen_offset: Vector2 = source.offset
	var frozen_transform: Transform2D = source.global_transform
	check(p.try_backstep(),"cancel attack")
	var ghost: Sprite2D = p.afterimage.ghosts[0].node
	eq(ghost.texture,frozen_texture,"ghost uses exact interrupted attack frame")
	eq(ghost.offset,frozen_offset,"frame root registration retained")
	eq(ghost.global_transform,frozen_transform,"interrupted pose facing and position retained")
	await physics_frames(3)
	eq(p.action_visual.current_key,"jump","actor already switched to retreat pose")
	eq(ghost.texture,frozen_texture,"ghost remains frozen while actor changes pose")
