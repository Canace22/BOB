extends TestSuite

func player() -> TidePlayer:
	var p: TidePlayer=load("res://content/whalebelly/Player.tscn").instantiate()
	p.preload_actions=false
	add(p)
	p.set_physics_process(false)
	return p

func effects(p: TidePlayer) -> TideWorldEffects:
	var fx:=TideWorldEffects.new()
	p.add_child(fx)
	fx.setup(p,94.0)
	fx.set_process(false)
	return fx

func test_ghost_keeps_historical_world_transform_and_expires() -> void:
	var p: TidePlayer=player()
	var fx: TideWorldEffects=effects(p)
	p.z_index=20
	p.position=Vector2(120,200)
	fx._spawn_ghost()
	eq(fx.particles.size(),1,"one bitmap snapshot produced")
	var ghost: Sprite2D=fx.particles[0].node
	eq(ghost.z_index,19,"historical ghost retains campaign layer above room art")
	check(not ghost.z_as_relative,"top-level ghost uses explicit world ordering")
	var initial: Transform2D=ghost.global_transform
	p.position+=Vector2(100,0)
	p.facing=-1.0
	p.get_node("Visual").scale.x*=-1
	eq(ghost.global_transform,initial,"moving and flipping caster does not move historical ghost")
	fx._process(.19)
	eq(fx.particles.size(),0,"ghost has bounded lifetime")

func test_damage_and_interaction_clear_world_effects() -> void:
	var p: TidePlayer=player()
	var fx: TideWorldEffects=effects(p)
	fx._spawn_ghost()
	p.take_damage(1,Vector2(30,0),true)
	eq(fx.particles.size(),0,"actual damage clears residual world effects")
	fx._spawn_ghost()
	p.animation_tag.emit("interact:start")
	eq(fx.particles.size(),0,"interaction transition clears residual world effects")
	for i: int in range(25): fx._spawn_ghost()
	eq(fx.particles.size(),20,"effect load is bounded")

func test_dive_effect_is_world_anchored_and_cancel_removes_it() -> void:
	var p: TidePlayer=player()
	var fx: TideWorldEffects=effects(p)
	# Use the real candidate atlas. Missing FX is a meaningful integration failure.
	p.skill_effect.emit("dive","land",Vector2(300,450),-1.0)
	check(fx.particles.size()==1,"dive land has a real bitmap atlas")
	if fx.particles.is_empty(): return
	var ring: Sprite2D=fx.particles[0].node
	eq(ring.global_position,Vector2(300,450),"land event supplies true ground position")
	p.position=Vector2(800,500)
	eq(ring.global_position,Vector2(300,450),"land ring stays behind after movement")
	check(ring.scale.x<0,"left direction is applied exactly once")
	p.skill_effect.emit("dive","cancel",p.global_position,1.0)
	eq(fx.particles.size(),0,"skill interruption cleans world ring")

func test_scan_release_is_once_world_anchored_and_cancellable() -> void:
	var p: TidePlayer=player()
	var fx: TideWorldEffects=effects(p)
	p.position=Vector2(270,310)
	p.facing=-1.0
	check(p.request_action("scan"),"scan enters real skill timeline")
	eq(fx.particles.size(),0,"scan startup does not spawn release ring")
	p.state_time=.25
	p._update_action_events()
	p._update_action_events()
	eq(fx.particles.size(),1,"crossed scan release creates one real atlas ring")
	if fx.particles.is_empty(): return
	var ring: Sprite2D=fx.particles[0].node
	var original: Transform2D=ring.global_transform
	eq(ring.global_position,Vector2(270,310),"scan ring starts at actual feet")
	p.position+=Vector2(150,-50)
	p.facing=1.0
	eq(ring.global_transform,original,"scan ring is unaffected by later movement or facing")
	p.skill_controller.cancel()
	eq(fx.particles.size(),0,"scan interruption removes its world ring")

func test_legacy_heavy_release_is_once_world_anchored_and_finite() -> void:
	var p: TidePlayer=player()
	var fx: TideWorldEffects=effects(p)
	p.position=Vector2(220,430)
	p.facing=-1.0
	check(p.request_action("heavy"),"legacy heavy request accepted")
	eq(fx.particles.size(),0,"heavy startup has no world ring")
	var clip: Animation=p.anim.get_animation("game/heavy")
	p.state_time=(clip.get_marker_time("release")*12.0/p.animation_fps if clip.has_marker("release") else 2.0/p.animation_fps)+.01
	p._update_action_events()
	p._update_action_events()
	eq(fx.particles.size(),1,"legacy release marker creates one atlas ring")
	if fx.particles.is_empty(): return
	var ring: Sprite2D=fx.particles[0].node
	var original: Transform2D=ring.global_transform
	eq(ring.global_position,Vector2(220,430),"heavy ring begins at actual feet")
	p.position+=Vector2(90,50)
	p.facing=1.0
	eq(ring.global_transform,original,"heavy ring does not follow caster or later facing")
	fx._process(1.0)
	eq(fx.particles.size(),0,"heavy ring expires without relying on another state change")

func test_fx_event_frame_is_independent_of_eight_pose_body() -> void:
	var p: TidePlayer=player()
	p.z_index=20
	var fx: TideWorldEffects=effects(p)
	var spec: Dictionary=fx.manifest.dive.duplicate(true)
	var atlas: Dictionary=spec.fx
	var source_rect: Array=atlas.frames[0]
	atlas.frames=[]
	for i: int in range(16):
		var rect: Array=source_rect.duplicate()
		rect[2]=maxf(1.0,float(source_rect[2])-i)
		atlas.frames.append(rect)
	spec.frame_count=8;spec.event_phase=0.5
	atlas.frame_count=16;atlas.event_frame=3
	fx.manifest.dive=spec
	for direction: float in [-1.0,1.0]:
		fx._spawn_atlas("dive",Vector2(200,450),direction,0.24)
		var item: Dictionary=fx.particles[0]
		eq(item.frames.size(),13,"16 FX frames begin at own event frame 3, independent of 8 body poses")
		var first: AtlasTexture=item.frames[0]
		eq(first.region.size.x,float(atlas.frames[3][2]),"event_frame selects the exact FX region")
		eq(item.node.z_index,19,"ground ring stays above room art and one layer behind the body")
		check(not item.node.z_as_relative,"world ring uses explicit world ordering")
		check(item.node.scale.x*direction>0,"world ring mirrors once for event direction")
		fx._process(0.23)
		var last: AtlasTexture=item.node.texture
		eq(last.region.size.x,float(atlas.frames[15][2]),"world effect reaches its own final frame")
		fx._process(0.02)
		eq(fx.particles.size(),0,"independent longer sequence still obeys finite effect lifetime")
