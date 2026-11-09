@warning_ignore_start("untyped_declaration")
extends Node
var host: Node2D
var results: Array = []

func chain(order: Array, label: String) -> void:
	var direction: String = "right" if int(order[0])==0 else "left"
	for index: int in order:
		Input.action_press(direction)
		await host.wait_physics(2)
		Input.action_press("grapple")
		await host.wait_physics(2)
		Input.action_release("grapple")
		var target: Vector2 = host.player.grapple_target
		var expected: Vector2 = host.point(host.room.rings[index])+Vector2(0,55)
		for frame: int in range(100):
			await get_tree().physics_frame
			if host.player.grapple_target==Vector2.INF: break
		Input.action_release(direction)
		results.append({"name":label+"_ring_"+str(index+1),"pass":target!=Vector2.INF and target.distance_to(expected)<1 and host.player.position.distance_to(expected)<80,"target":[target.x,target.y],"end":[host.player.position.x,host.player.position.y]})
		await host.evidence_frame(label+"-ring-"+str(index+1))
	host.release_controls()

func route(targets: Array, label: String) -> void:
	for target: Vector2 in targets:
		var result: Dictionary = await host.drive_to(target,750)
		result.name=label+"_"+str(int(target.x))
		results.append(result)

func run() -> void:
	var beds: Array = host.rooms[4].soft_beds
	var safe_points: Array = [[300,572],[700,577],[1000,564]]
	for i: int in range(beds.size()):
		host.release_controls()
		host.health=5
		var bed: Dictionary=beds[i]
		var start: Array=[(float(bed["from"])+float(bed.to))*0.5,float(bed.y)-25]
		host.load_room(4,start)
		host.player.last_safe=host.point(safe_points[i])
		var begin: int=host.event_sequence
		var triggered: bool=false
		for frame: int in range(100):
			await get_tree().physics_frame
			for event: Dictionary in host.events:
				if int(event.seq)>begin and event.event=="soft_bed_recover":triggered=true
			if triggered:break
		await host.wait_physics(30)
		results.append({"name":"soft_bed_fixture_"+str(i+1),"pass":triggered and host.health==4 and host.player.is_on_floor() and host.player.position.distance_to(host.point(safe_points[i]))<8,"health":host.health,"fixture_start":start,"safe_start":safe_points[i],"end":[host.player.position.x,host.player.position.y]})
		await host.evidence_frame("soft-bed-"+str(i+1))
	await host.flow_setup(5,[190,790])
	await host.key_tap(KEY_F9)
	await route([Vector2(250,520),Vector2(130,580)],"06_left_wall_platform")
	await host.wait_physics(35)
	results.append({"name":"06_left_wall_standable","pass":host.player.is_on_floor() and host.player.position.x<205 and host.player.position.y<610,"position":[host.player.position.x,host.player.position.y]})
	await host.evidence_frame("06-new-left-ledge")
	await route([Vector2(350,790)],"06_left_ledge_return")
	Input.action_press("right")
	for frame: int in range(230):
		await get_tree().physics_frame
		if host.player.position.y>880 and host.player.is_on_floor():break
	Input.action_release("right")
	await host.wait_physics(12)
	results.append({"name":"06_bottom_recovery_slope_landing","pass":host.room_index==5 and host.player.position.y>880 and host.player.is_on_floor() and host.health==5,"position":[host.player.position.x,host.player.position.y],"health":host.health})
	await host.evidence_frame("06-new-bottom-slope")
	await route([Vector2(535,755),Vector2(330,790),Vector2(100,795)],"06_bottom_recovery_return")
	Input.action_press("left")
	await host.input_tap("interact")
	Input.action_release("left")
	results.append({"name":"06_bottom_slope_returns_02","pass":host.room_index==1})
	await host.evidence_frame("06-bottom-return-02")
	host.practice=false
	await host.flow_setup(6,[350,575])
	await host.key_tap(KEY_F9)
	await chain([0,1,2,3],"07-outbound")
	await route([Vector2(1300,569)],"07_chain_land_reward")
	await host.input_tap("interact")
	Input.action_press("right")
	await host.wait_physics(100)
	Input.action_release("right")
	results.append({"name":"07_closed_right_wall","pass":host.room_index==6 and host.player.position.x<=1460.01 and host.player.position.x>1458,"x":host.player.position.x})
	await host.evidence_frame("07-right-wall")
	await host.walk_to(Vector2(1300,569),400)
	await chain([3,2,1,0],"07-return")
	await route([Vector2(250,572)],"07_chain_return_landing")
	# Explicit reverse-door fixtures validate E transition, not a full walk-through.
	for index: int in [1,2,3,4]:
		var door: Dictionary=host.rooms[index].doors[0]
		await host.flow_setup(index,[float(door.pos[0]),float(door.pos[1])-12.0])
		Input.action_press("left")
		await host.input_tap("interact")
		Input.action_release("left")
		await host.wait_physics(55)
		results.append({"name":"reverse_door_"+str(index+1)+"_to_"+str(index),"pass":host.room_index==index-1 and host.player.is_on_floor(),"room":host.room_index,"grounded":host.player.is_on_floor(),"position":[host.player.position.x,host.player.position.y]})
	for gap: Dictionary in [{"x":482.0,"safe":[350,575]},{"x":950.0,"safe":[750,572]}]:
		host.health=5
		host.release_controls()
		host.load_room(6,[gap.x,650])
		host.player.last_safe=host.point(gap.safe)
		for frame: int in range(180):
			await get_tree().physics_frame
			if host.health<5:break
		await host.wait_physics(30)
		results.append({"name":"07_gap_fall_fixture_"+str(int(gap.x)),"pass":host.health==4 and host.player.is_on_floor() and host.player.position.distance_to(host.point(gap.safe))<8 and host.player.grapple_target==Vector2.INF,"health":host.health,"position":[host.player.position.x,host.player.position.y],"grapple_inactive_after_recovery":host.player.grapple_target==Vector2.INF,"initial_grapple_inactive":true})
		await host.evidence_frame("07-gap-recover-"+str(int(gap.x)))
	var inventory: Array=[]
	for index: int in range(7):
		host.load_room(index)
		await host.wait_physics(2)
		var env: Node=host.scenery.get_node("EnvironmentMotion")
		var mech: Node=host.scenery.get_node("VisualMechanisms")
		inventory.append({"room":host.room.id,"terrain_bodies":host.scenery.get_node("World/Terrain").get_child_count(),"door_areas":mech.trigger_nodes.size(),"ring_markers":mech.rings_node.get_child_count(),"enemy_instances":host.enemies.size(),"reward_node":host.scenery.has_node("World/RewardArt"),"procedural_bubble_items":env.bubbles.size(),"procedural_dust_items":env.dust.size(),"procedural_fish_items":env.fish.size(),"mist_sprite_nodes":env.fog_node.get_child_count(),"lamp_centers":env.lamps.size()})
	var failed: int=0
	for result: Dictionary in results:
		if not result.get("pass",false):failed+=1
	var report: Dictionary={"tests":results,"failed":failed,"events":host.events,"runtime_inventory":inventory,"method":"Input-driven four-ring return and new06 surfaces. Soft-bed fixture begins below terrain but above each trigger, with a seeded safe platform once at setup; verifies actual falling/trigger/damage/recovery, not natural gap traversal. Middle gap23px < capsule28px. Reverse doors use per-door starting fixture and actual E input. Inventory counts are actual instances; bubbles/dust/fish are procedural items, not individual nodes."}
	var path: String=host.qa_output.get_base_dir().path_join("elements.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ELEMENTS_QA failed=",failed," tests=",results.size())
	await host.graceful_quit()
