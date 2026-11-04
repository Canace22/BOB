extends SceneTree
## Real shared campaign actor, real G InputEvents, and isolated temporary ring data.
var host: Node2D
var p: WhalebellyCampaignPlayer
var checks: Array[Dictionary]=[]
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func key(pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_G;event.keycode=KEY_G;event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func check(label: String,pass_value: bool) -> void:
	checks.append({"name":label,"pass":pass_value})
	print("ANCHOR ","PASS " if pass_value else "FAIL ",label)
func enter_anchor(direction: float, grounded: bool=false) -> void:
	key(false)
	p.skill_controller.cancel();p.grapple_target=Vector2.INF
	p.state="idle";p.state_duration=0.0;p.velocity=Vector2.ZERO;p.facing=direction
	p.run_visual.detach_left=0.0;p.run_visual.anchor_active=false
	p.position=Vector2(220,600) if grounded else Vector2(650,320)
	await tick(20 if grounded else 3)
	var target: Vector2=p.position+Vector2(direction*250,0 if grounded else -40)
	host.room.rings=[[target.x,target.y-55]]
	key(true);await tick(3);key(false);await tick(2)
	check("G_enters_anchor_"+str(direction),p.grapple_target!=Vector2.INF and p.run_visual.current_key=="anchor")
	p.world_effects._update_rope()
	var ring_world: Vector2=host.to_global(host.point(host.room.rings[0]))
	check("physics_feet_target_keeps_55_offset_"+str(direction),p.grapple_target.is_equal_approx(target))
	check("world_rope_ends_at_actual_ring_"+str(direction),p.world_effects.rope.visible and p.world_effects.rope.points.size()==2 and p.world_effects.rope.points[1].is_equal_approx(ring_world))
	var original_host_position: Vector2=host.position
	host.position+=Vector2(31,47)
	p.world_effects._update_rope()
	check("world_rope_accounts_for_parent_transform_"+str(direction),p.world_effects.rope.points[1].is_equal_approx(host.to_global(host.point(host.room.rings[0]))))
	host.position=original_host_position
	p.world_effects._update_rope()
func release_anchor() -> void:
	key(true)
	for frame: int in 5:
		await tick(1)
		if p.grapple_target==Vector2.INF: break
	key(false)
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_full_abilities=true;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await tick(35)
	p=host.player;p.automatic_doors=false;p.invulnerable=99.0
	var original: Array=host.room.get("rings",[]).duplicate(true)
	for direction: float in [1.0,-1.0]:
		await enter_anchor(direction)
		var before: Vector2=p.position
		await release_anchor()
		var view: TideActionVisual=p.run_visual
		check("G_releases_actual_target_"+str(direction),p.grapple_target==Vector2.INF)
		check("detach_body_visible_"+str(direction),view.current_key=="anchor" and view.detach_left>0.0 and view.sprite.visible)
		var sequence: Array[Texture2D]=view.load_clip("anchor").body
		var fraction: float=float(sequence.find(view.sprite.texture))/sequence.size()
		check("detach_uses_end_segment_"+str(direction),fraction>=0.75)
		check("detach_keeps_direction_"+str(direction),signf(p.get_node("Visual").scale.x)==direction)
		check("detach_does_not_lock_physics_"+str(direction),(p.position.x-before.x)*direction>3.0)
		await tick(10)
		check("detach_finishes_into_air_pose_"+str(direction),view.detach_left<=0.0 and view.current_key=="jump")
	await enter_anchor(1.0)
	await release_anchor()
	check("parry_interrupt_request",p.request_action("parry"))
	await tick(2)
	check("skill_cancels_detach_pose",p.run_visual.detach_left==0.0 and p.run_visual.current_key=="parry")
	await tick(30)
	await enter_anchor(-1.0)
	await release_anchor()
	p.take_damage(1,p.position+Vector2(50,0),true)
	await tick(2)
	check("damage_cancels_detach_pose",p.run_visual.detach_left==0.0 and p.run_visual.current_key=="hurt")
	await tick(30)
	await enter_anchor(1.0,true)
	await release_anchor()
	check("grounded_moving_release_uses_locomotion",p.is_on_floor() and p.run_visual.detach_left==0.0 and p.run_visual.current_key in ["run","turn"])
	host.room.rings=original
	# Authored R1-02 rings, without replacing room data or marker coordinates.
	host.load_room(1)
	await tick(8)
	p=host.player;p.automatic_doors=false;p.set_physics_process(false)
	for direction: float in [1.0,-1.0]:
		var ring_index: int=0 if direction>0 else host.room.rings.size()-1
		var marker: Marker2D=host.scenery.get_node("VisualMechanisms/AnchorRings/Ring"+str(ring_index+1))
		var authored_ring: Vector2=host.point(host.room.rings[ring_index])
		p.grapple_target=Vector2.INF;p.state_duration=0.0;p.facing=direction
		p.position=authored_ring+Vector2(-direction*160,55)
		p._find_ring();p.world_effects._update_rope()
		check("authored_ring_keeps_original_physics_target_"+str(direction),p.grapple_target.is_equal_approx(authored_ring+Vector2(0,55)))
		check("authored_world_endpoint_matches_marker_"+str(direction),p.world_effects.rope.visible and p.world_effects.rope.points[1].is_equal_approx(marker.global_position))
		p._find_ring();p.world_effects._update_rope()
		check("detach_hides_authored_rope_"+str(direction),not p.world_effects.rope.visible)
	var failed: int=checks.filter(func(row: Dictionary) -> bool:return not row.pass).size()
	FileAccess.open("res://build/qa/action36/anchor.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Real G key events on formal campaign player; temporary QA ring targets; no save progression or art approval", "checks":checks,"failed":failed},"\t"))
	await host.graceful_quit(1 if failed else 0)
