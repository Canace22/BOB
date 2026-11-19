extends TestSuite

func campaign() -> WhalebellyMain:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	await physics_frames(45)
	return host

func count(host: WhalebellyMain, cue: String) -> int:
	return host.events.filter(func(item: Dictionary) -> bool:
		return item.event == "player_music" and item.data.cue == cue).size()

func test_movement_cues_follow_successful_actions() -> void:
	var host := await campaign()
	var actor: WhalebellyCampaignPlayer = host.player
	var area_playback := host.music.get_stream_playback()
	check(not actor.request_action("A1_dash"), "Locked dash does not play")
	eq(count(host, "dash"), 0, "Rejected input stays quiet")
	Input.action_press("tp_jump")
	await physics_frames(3)
	Input.action_release("tp_jump")
	await physics_frames(6)
	Input.action_press("tp_jump")
	await physics_frames(3)
	Input.action_release("tp_jump")
	eq(count(host,"jump"),1,"First jump accent")
	eq(count(host,"air_jump"),1,"Air jump has a different interval")
	await physics_frames(60)
	host.abilities.dash = true
	check(actor.request_action("A1_dash"), "Unlocked dash starts")
	eq(count(host, "dash"), 1, "One dash accent")
	eq(host.music.get_stream_playback(), area_playback, "Action cues preserve the area music playback")

func test_health_phrases_require_actual_changes() -> void:
	var host := await campaign()
	var actor: WhalebellyCampaignPlayer = host.player
	actor.take_damage(4,Vector2.ZERO,true)
	eq(count(host,"low"),1,"Crossing down to one health sounds once")
	actor.stats_changed.emit(actor.health,actor.soul)
	eq(count(host,"low"),1,"Resource refresh at one health stays quiet")
	await physics_frames(50)
	check(actor.request_action("recover"),"Start focus")
	actor._cancel_focus()
	eq(count(host,"recover"),0,"Cancelled focus stays quiet")
	check(actor.request_action("recover"),"Restart focus")
	await physics_frames(90)
	eq(count(host,"recover"),1,"Completed focus replenishes health and sounds once")
	actor.take_damage(actor.health, Vector2.ZERO,true)
	eq(count(host,"defeat"),1,"Lethal damage sounds once")
	eq(count(host,"low"),1,"Lethal damage does not retrigger low health")
