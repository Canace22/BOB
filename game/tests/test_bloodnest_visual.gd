extends TestSuite
const Visuals = preload("res://src/campaign/enemies/kit_encounter_visual.gd")

func config() -> Dictionary:
	var rooms: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/world/rooms.json")).rooms
	return rooms.filter(func(room: Dictionary)->bool:return room.id=="R2-04")[0].enemies[0].config.duplicate(true)

func positions(body: KitSwarmVisual) -> Array:
	return body.members.map(func(member: Dictionary)->Vector2:return member.node.position)

func test_campaign_hit_feedback_preserves_the_shrimp_and_core_shaders() -> void:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.integration_external_test=true
	add(host)
	for index: int in host.rooms.size():
		if str(host.rooms[index].id)=="R2-04": host.load_room(index)
	await physics_frames(2)
	var actor: KitEncounter=host.enemies[0].actor
	check(actor.body is KitBloodnestVisual,"Main campaign retains the local shrimp presentation")
	var expected: String=CampaignStreamPresentation._shader_for(KitBloodnestVisual.Swim.code).code
	for member: Dictionary in actor.body.members:
		eq(member.node.material.shader.code,expected,"Shared feedback must not overwrite appendage animation")
	eq(actor.core.material.shader.code,expected,"The core keeps its authored swim shader")
	actor.feedback.receive(0.03,-1.0,2.0)
	check(actor.feedback.frozen(1.0/60.0),"Shared combat hitstop remains active")
	actor.on_damaged()
	eq(actor.body.impact.weights.count(0.0),38,"Only six shrimp receive the local shell flash")

func test_vortex_is_opt_in_and_all_members_use_the_original_style_bitmap() -> void:
	var settings: Dictionary = config()
	var body := Visuals.swarm_body(settings,7) as KitBloodnestVisual
	add(body)
	check(body is KitBloodnestVisual,"Blood nest selects its own presentation")
	eq(body.members.size(),44,"Pool stays at the existing configured count")
	for member: Dictionary in body.members:
		check(member.node.texture.resource_path.ends_with("bloodnest-glass-shrimp-v5.png"),"The Boss uses the newly designed compact glass shrimp")
	eq(body.wake.streams.size(),6,"Only six open current filaments surround the swarm")
	eq(body.wake.particles.size(),26,"Bubbles and glints have a fixed pool")
	settings.erase("swarm_visual")
	var plain := Visuals.swarm_body(settings,7)
	add(plain)
	check(not plain is KitBloodnestVisual,"Other swarms retain their default visual")

func test_attack_aligns_both_directions_without_a_position_pop_and_recovers() -> void:
	for direction: float in [-1.0,1.0]:
		var body := Visuals.swarm_body(config(),5) as KitBloodnestVisual
		add(body)
		body.facing=direction
		var before: Array = positions(body)
		body.update_at(0.0,"tell",0.0,1.0)
		eq(positions(body),before,"State entry alone cannot teleport members")
		for i: int in 60: body.update_at((i+1)/60.0,"tell",(i+1)/60.0,1.0)
		for i: int in 90: body.update_at(1.0+(i+1)/60.0,"act",(i+1)/60.0,1.5)
		check(body.formation>0.99,"Charge forms a directional ribbon")
		for member: Dictionary in body.members:
			var sprite: Sprite2D = member.node
			check(absf(angle_difference(sprite.rotation,0.0 if direction<0.0 else PI))<0.7,"Shrimp follow the curved current without reversing against the attack")
			check(absf(sprite.position.x)<90.0 and absf(sprite.position.y)<45.0,"Charge stays near its real damage envelope")
		for i: int in 42: body.update_at(2.5+(i+1)/60.0,"recover",(i+1)/60.0,0.7)
		check(body.formation<0.16,"Recovery opens back into a vortex")
		eq(body.members.size(),44,"Transitions never spawn extra members")

func test_one_clock_pauses_path_and_local_motion_and_recovers_without_catchup() -> void:
	var body := Visuals.swarm_body(config(),11) as KitBloodnestVisual
	add(body)
	body.update_at(0.1,"rest",0.1,1.9)
	var before: Array = positions(body)
	var material_: ShaderMaterial = body.members[0].node.material
	var held: float = material_.get_shader_parameter("clock")
	tree.paused=true
	for i: int in 3: await tree.process_frame
	eq(positions(body),before,"No independent process advances the paused pool")
	eq(material_.get_shader_parameter("clock"),held,"Local appendages freeze with the path")
	tree.paused=false
	body.update_at(0.1+1.0/60.0,"rest",0.1+1.0/60.0,1.9)
	check(positions(body)!=before,"The encounter clock resumes movement")
	check(body.members[0].node.position.distance_to(before[0])<5.0,"Resume does not accumulate wall clock time")

func test_local_hit_opens_only_six_members_and_returns_without_touching_combat() -> void:
	var body:=Visuals.swarm_body(config(),12) as KitBloodnestVisual
	var control:=Visuals.swarm_body(config(),12) as KitBloodnestVisual
	add(body)
	add(control)
	for i: int in 60:
		body.update_at((i+1)/60.0,"act",0.5,1.5)
		control.update_at((i+1)/60.0,"act",0.5,1.5)
	body.receive_hit(Vector2(-110,15))
	eq(body.impact.weights.count(0.0),38,"Only six out of forty-four shrimp receive the hit")
	check(body.impact.direction.x>0.0,"Left-side hit pushes the local group away from the source")
	for i: int in 6:
		body.update_at(1.0+(i+1)/60.0,"act",0.5,1.5)
		control.update_at(1.0+(i+1)/60.0,"act",0.5,1.5)
	var moved: int=0
	for i: int in body.members.size():
		if body.members[i].node.position.distance_to(control.members[i].node.position)>0.5:moved+=1
	eq(moved,6,"Local recoil leaves the other thirty-eight shrimp following their current")
	check(body.formation>0.99,"Receiving a hit does not cancel the charge formation")
	for i: int in 48:
		body.update_at(1.1+(i+1)/60.0,"act",0.5,1.5)
		control.update_at(1.1+(i+1)/60.0,"act",0.5,1.5)
	for i: int in body.members.size():
		check(body.members[i].node.position.distance_to(control.members[i].node.position)<0.2,"Recoil blends back into the same current")
		check((body.members[i].node.material as ShaderMaterial).get_shader_parameter("hit_strength")==0.0,"Shell highlights expire")
	check(body.impact.arcs.all(func(arc: Line2D)->bool:return arc.modulate.a==0.0),"Contact arcs expire without a persistent damage circle")

func test_repeat_hits_keep_fixed_pools_and_pause_holds_the_reaction() -> void:
	var body:=Visuals.swarm_body(config(),4) as KitBloodnestVisual
	add(body)
	for i: int in 20:body.receive_hit(Vector2(-100 if i%2==0 else 100,12))
	eq(body.impact.sparks.size(),8,"Repeated hits reuse eight bitmap glints")
	eq(body.impact.arcs.size(),2,"Repeated hits reuse two short textured arcs")
	eq(body.members.size(),44,"Damage never spawns another swarm")
	check(body.impact.direction.x<0.0,"Latest right-side impact updates its local force direction")
	body.update_at(0.05,"rest",0.05,1.9)
	var before: Array=positions(body)
	var sparks: Array=body.impact.sparks.map(func(sprite: Sprite2D)->Vector2:return sprite.position)
	tree.paused=true
	for i: int in 3:await tree.process_frame
	eq(positions(body),before,"Pause holds the local displacement")
	eq(body.impact.sparks.map(func(sprite: Sprite2D)->Vector2:return sprite.position),sparks,"Pause holds the contact particles too")
	tree.paused=false
