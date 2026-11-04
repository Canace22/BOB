extends TestSuite
## Presentation logic tests reuse an existing atlas as a fixture, not as new artwork.

func visual() -> TideActionVisual:
	var p: TidePlayer = load("res://content/whalebelly/Player.tscn").instantiate()
	p.preload_actions=false
	add(p)
	p.set_physics_process(false)
	var view: TideActionVisual = TideActionVisual.new()
	p.add_child(view)
	view.setup(p,94.0)
	return view

func test_event_alignment_handles_start_middle_and_end() -> void:
	eq(TideActionVisual.align_event(0.3,0.3,0.6),0.6,"source hit frame aligns to gameplay hit time")
	eq(TideActionVisual.align_event(0.0,0.0,0.4),0.4,"immediate skills skip an unusable windup")
	eq(TideActionVisual.align_event(1.0,1.0,0.8),0.8,"end-triggered heal aligns to completion")
	check(TideActionVisual.align_event(0.2,0.3,0.6)<0.6,"windup stays before hit frame")
	check(TideActionVisual.align_event(0.7,0.3,0.6)>0.6,"recovery follows hit frame")

func test_disabled_controls_do_not_freeze_death_body() -> void:
	var view: TideActionVisual = visual()
	var p: TidePlayer = view.actor
	view.manifest["defeat"]=view.manifest.idle.duplicate(true)
	view.available["defeat"]=true
	p.state="defeat";p.state_duration=3.0;p.state_time=0.0;p.controls_enabled=false
	view.update(0.4,0.0)
	var first: Texture2D=view.sprite.texture
	view.update(0.4,0.0)
	check(view.sprite.visible and not p.body.visible,"one death body remains visible during input lock")
	check(first!=view.sprite.texture,"death continues to advance with controls disabled")
	eq(p.state_time,0.0,"presentation does not advance gameplay state")
	p.hitstop=0.1
	first=view.sprite.texture
	view.update(0.4,0.0)
	eq(view.sprite.texture,first,"hitstop freezes presentation")

func test_status_precedence_and_custom_interaction() -> void:
	var view: TideActionVisual=visual()
	var p: TidePlayer=view.actor
	p.skill_controller.visual_key="swim"
	p.state="hit";p.state_duration=0.2
	eq(view.choose_key(0.016),"hurt","hit overrides environmental swim pose")
	p.state="interact";p.state_duration=0.6
	p.skill_controller.active=true;p.skill_controller.visual_key="scan"
	eq(view.choose_key(0.016),"scan","scan proxy interaction keeps its distinct animation")
	p.skill_controller.active=false;p.skill_controller.visual_key="great_slash"
	p.state="recover";p.state_duration=1.5
	eq(view.choose_key(0.016),"heal","held charge cannot cover healing")

func test_swim_loops_and_dive_waits_for_real_landing() -> void:
	var view: TideActionVisual=visual()
	var p: TidePlayer=view.actor
	var spec: Dictionary={"frame_count":20,"fps":10.0,"loop":true,"event_phase":0.6}
	view.elapsed=1.9
	check(view.frame_fraction("swim",spec,0.2,0.0)<0.1,"swim wraps instead of holding last frame")
	var controller: TideSkillController=p.skill_controller
	controller.active=true;controller.visual_key="dive";controller.duration=2.0
	controller.data={"release":0.14};controller.elapsed=1.0;controller.landed=false
	check(view.frame_fraction("dive",spec,0.016,0.0)<0.6,"airborne dive cannot show impact")
	controller.landed=true;controller.landed_at=1.0;controller.duration=1.24
	eq(view.frame_fraction("dive",spec,0.016,0.0),0.6,"actual landing selects impact immediately")
	controller.elapsed=1.12
	check(is_equal_approx(view.frame_fraction("dive",spec,0.016,0.0),0.8),"landing recovery advances through the remaining frames")

func test_missing_asset_restores_legacy_body() -> void:
	var view: TideActionVisual=visual()
	view.actor.state="hit";view.actor.state_duration=0.2
	view.available["hurt"]=false
	view.update(0.016,0.0)
	check(view.actor.body.visible and not view.sprite.visible and not view.effect.visible,"missing atlas does not hide both bodies")
	check(not view.actor.get_node("Visual/Legs").visible,"hurt fallback does not retain running legs")

func test_anchor_stage_ranges_loop_and_detach() -> void:
	var view: TideActionVisual=visual()
	var spec: Dictionary={"frame_count":20,"fps":10.0,"loop":false,"phases":{"hang":[0.2,0.6],"detach":[0.6,1.0]}}
	view.anchor_elapsed=0.02
	check(view.frame_fraction("anchor",spec,0.016,0.0)<0.2,"entry precedes the hanging segment")
	view.anchor_elapsed=0.3
	var first: float=view.frame_fraction("anchor",spec,0.016,0.0)
	view.anchor_elapsed=1.5
	var later: float=view.frame_fraction("anchor",spec,0.016,0.0)
	check(first>=0.2 and first<0.6 and later>=0.2 and later<0.6 and first!=later,"hanging remains in the configured loop instead of freezing at the end")
	view.detach_left=0.12
	eq(view.frame_fraction("anchor",spec,0.016,0.0),0.6,"release starts at the configured detach segment")
	view.detach_left=0.06
	check(is_equal_approx(view.frame_fraction("anchor",spec,0.016,0.0),0.8),"release progresses through the final segment")

func test_wall_jump_pose_uses_physics_window() -> void:
	var view: TideActionVisual=visual()
	var spec: Dictionary={"frame_count":10,"fps":24.0,"loop":false}
	view.wall_jump_span=0.15;view.actor.wall_lock=0.15
	eq(view.frame_fraction("wall_jump",spec,1.0/60.0,0.0),0.0,"kick starts at the first pose")
	view.actor.wall_lock=0.075
	check(is_equal_approx(view.frame_fraction("wall_jump",spec,1.0/60.0,0.0),0.5),"middle pose follows the real wall-jump lock")
	view.actor.wall_lock=0.01
	eq(view.frame_fraction("wall_jump",spec,1.0/60.0,0.0),1.0,"last physics tick reaches the end pose instead of only the first third")

func test_world_socket_uses_requested_clip_and_single_direction_flip() -> void:
	var view: TideActionVisual=visual()
	view.manifest["fixture"]={"reference_height":160.0,"sockets":{"muzzle":[32.0,-80.0]}}
	view.actor.position=Vector2(100,200);view.actor.facing=-1.0;view.current_key="idle"
	check(view.world_socket("fixture","muzzle",Vector2.ZERO).is_equal_approx(Vector2(81.2,153)),"socket uses requested clip, normalized height, and facing exactly once")
	check(view.world_socket("fixture","muzzle",Vector2.ZERO,1.0).is_equal_approx(Vector2(118.8,153)),"accepted skill direction can override a later facing change")
	eq(view.world_socket("fixture","missing",Vector2(20,30)),Vector2(20,30),"missing socket preserves the legacy world-space fallback")
	view.manifest.fixture["sockets_per_frame"]={"muzzle":[[40.0,-72.0],[60.0,-64.0]]}
	view.current_key="fixture";view.active=true;view.frame_index=1
	check(view.world_socket("fixture","muzzle",Vector2.ZERO).is_equal_approx(Vector2(64.75,162.4)),"displayed frame supplies its own socket with a single direction flip")
	view.frame_index=9
	check(view.world_socket("fixture","muzzle",Vector2.ZERO).is_equal_approx(Vector2(81.2,153)),"missing per-frame entry falls back to the static socket")
	view.frame_index=1;view.current_key="idle"
	check(view.world_socket("fixture","muzzle",Vector2.ZERO).is_equal_approx(Vector2(81.2,153)),"an event before clip presentation uses the static socket")

func test_shadow_dash_reuses_body_and_resets_its_tint_on_exit() -> void:
	var view: TideActionVisual=visual()
	var p: TidePlayer=view.actor
	view.manifest.shadow_dash=view.manifest.dash.duplicate(true)
	view.available.shadow_dash=true
	for direction: float in [-1.0,1.0]:
		p.facing=direction;p.get_node("Visual").scale.x=p.visual_scale*direction
		p.cooldowns.shadow_dash=0.0;p.cooldowns.dash=0.0
		check(p.request_action("shadow_dash"),"shadow skill starts with shared temporary dash spec")
		view.update(0.016,0.0)
		eq(view.current_key,"shadow_dash","shadow action retains its stable key despite shared artwork")
		eq(view.sprite.modulate,Color(0.58,0.78,0.83,0.92),"shadow variant gets its configured cool tint")
		check(view.sprite.global_transform.x.x*direction>0,"shared body uses facing exactly once")
		p.skill_controller.cancel();p.cooldowns.dash=0.0
		check(p.request_action("A1_dash"),"base dash starts after shadow cancellation")
		view.update(0.016,0.0)
		eq(view.sprite.modulate,Color.WHITE,"base dash cannot retain shadow tint")
		p.skill_controller.cancel();p.state_duration=0.0
