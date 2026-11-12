extends "res://tests/chapter_branches.gd"
## QA save only; one initial room fixture, then real input through both directions.

class IsolatedCampaign extends WhalebellyMain:
	func save_path() -> String:
		var workspace: String = ProjectSettings.globalize_path("res://").sha256_text().left(12)
		return "user://whalebelly/memory-branch-" + workspace + ".json"

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa/r1-chapter-scenes"))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(IsolatedCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(35)
	if "--reload-memory" in OS.get_cmdline_user_args():
		host.load_progress()
		host.load_room(host.room_index,host.checkpoint.pos)
		await tick(40)
		check("independent_reload",host.has_ability("float") and host.has_ability("anchor") and host.collected.get("R1-07",false))
		var art: Node2D = host.scenery.get_node_or_null("World/RewardArt")
		check("collected_art_hidden",art != null and not art.visible)
	else:
		await host.flow_setup(1,[1000,640])
		check("normal_base_anchor",host.has_ability("anchor") and not host.has_ability("float") and not host.practice)
		for i in 3:
			await host.input_tap("grapple")
			check("ring_attached_"+str(i),host.player.grapple_target != Vector2.INF)
			for frame in 90:
				await tick(1)
				if host.player.grapple_hanging: break
			check("ring_hangs_"+str(i),host.player.grapple_hanging)
			var held: Vector2=host.player.position
			await tick(40)
			check("ring_wait_is_stable_"+str(i),host.player.position.distance_to(held)<1)
			print("RING_END ",i," ",host.player.position)
		# Leaving the last ring needs a held jump; a tap is only a short hop.
		Input.action_press("jump")
		await tick(20)
		Input.action_release("jump")
		# Rings are done; re-grappling from above the deck would only pull into its floor.
		check("top_landing_and_door",await drive(Vector2(1610,275),false,6,1100,false),{"room":host.room.id,"position":host.player.position})
		if host.room_index == 1:
			await interact()
			await tick(100)
		check("actual_memory_entry",host.room_index==6 and host.visited.get("R1-07",false))
		if host.room_index==6:
			await point("cross_memory_gaps",Vector2(1300,569),true)
			await interact()
			check("float_and_supplies",host.collected.get("R1-07",false) and host.abilities.float and host.player.health==5 and host.player.soul==99)
			check("memory_readable_in_map",host.player_ui.data.room_description(6).contains("记忆："))
			await capture("memory-reward")
			# A second E cannot trigger a second reward.
			var previous: int=host.events.filter(func(e: Dictionary)->bool:return e.event=="reward").size()
			await interact()
			check("reward_only_once",host.events.filter(func(e: Dictionary)->bool:return e.event=="reward").size()==previous)
			host.checkpoint={"room":6,"pos":[1300,569]}
			host.save_progress(false)
			check("return_over_gaps",await drive(Vector2(95,568),true,1,1100,false))
			if host.room_index==6:
				await interact("left")
				await tick(100)
			check("actual_return_to_upper_platform",host.room_index==1 and host.player.position.y<350)
	var failed: int=checks.filter(func(row: Dictionary)->bool:return not row.pass).size()
	var label: String="reload" if "--reload-memory" in OS.get_cmdline_user_args() else "route"
	FileAccess.open("res://build/qa/r1-chapter-scenes/memory-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	await host.graceful_quit(1 if failed else 0)
