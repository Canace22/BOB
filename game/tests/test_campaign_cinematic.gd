extends TestSuite
## 在真实主场景验证演出暂停所有权与原剧情提交边界，所有存档隔离。
class FilmHost extends WhalebellyMain:
	func save_path() -> String: return "user://whalebelly/cinematic-unit.json"
var hosts: Array[WhalebellyMain]=[]
var old_size: Vector2i
func before_each() -> void:
	await super.before_each()
	old_size=tree.root.size
	tree.root.size=Vector2i(1280,720)
func fixture(id: String) -> WhalebellyMain:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(FilmHost)
	host.qa=true
	host.integration_external_test=true
	add(host)
	hosts.append(host)
	await physics_frames(12)
	host.ui_interactive_in_tests=true
	host.dialogue.enabled=true
	host.story.allow_in_tests=true
	host.story.set_process(false)
	var prefix: Array[String]=[]
	for stage: Dictionary in host.story.catalog.stages:
		if str(stage.id)==id: break
		prefix.append(str(stage.id))
	host.story.restore({"version":1,"completed":prefix,"facts":{}})
	var stage: Dictionary=host.story.stage()
	var room: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(stage.room_id))
	host.load_room(room,stage.at)
	host.player_ui.close_all()
	host.player_ui.pending_resume=false
	host.player.controls_enabled=true
	tree.paused=false
	await physics_frames(25)
	return host

func after_each() -> void:
	for host: WhalebellyMain in hosts:
		if is_instance_valid(host): host.story.cinematic.cancel()
	hosts.clear()
	for key: int in [KEY_F,KEY_D,KEY_TAB,KEY_ESCAPE,KEY_ENTER]: key_event(key,false)
	tree.paused=false
	tree.root.size=old_size
	await super.after_each()

func key_event(code: int, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)

func test_observation_plays_and_returns_to_original_commit_once() -> void:
	var host: WhalebellyMain=await fixture("ch03_flood")
	host.story.interaction_armed=true
	check(host.story.interact(),"actual observation interaction accepted")
	check(host.story.cinematic.active and tree.paused,"world freezes under cinematic owner")
	check(not host.story.facts.get("ch03_flood_settled",false),"no premature story commit")
	var p: Vector2=host.player.global_position
	await physics_frames(18)
	eq(host.player.global_position,p,"real player remains physically stable")
	var film: CampaignCinematic=host.story.cinematic
	check(film.view.camera.is_current(),"shot camera owns actual viewport")
	film.skip()
	await physics_frames(55)
	check(not film.active and not tree.paused and host.player.controls_enabled,"camera pause and controls restored")
	check(host.camera.is_current(),"normal camera restored")
	eq(str(host.story.stage().id),"ch03_after","only current observation completed")
	check(host.story.facts.get("ch03_flood_settled",false),"same original fact granted")
	eq(host.story.completed.count("ch03_flood"),1,"completion occurs once")

func test_escape_requires_confirmation_and_waits_for_held_input() -> void:
	var host: WhalebellyMain=await fixture("ch02_rescue")
	host.story.interact()
	key_event(KEY_D,true)
	key_event(KEY_ESCAPE,true)
	await physics_frames(2)
	key_event(KEY_ESCAPE,false)
	check(host.story.cinematic.skip_armed,"first escape arms confirmation")
	check(host.story.cinematic.returning<0,"first escape does not skip")
	key_event(KEY_ENTER,true)
	await physics_frames(2)
	key_event(KEY_ENTER,false)
	await physics_frames(50)
	check(host.story.cinematic.active and host.story.cinematic.waiting_release,"held movement cannot leak into restored play")
	key_event(KEY_D,false)
	await physics_frames(5)
	check(not host.story.cinematic.active and host.player.controls_enabled,"release resumes gameplay")
	eq(host.player_ui.page_id,"","escape did not open pause behind the movie")

func test_cancel_and_restore_do_not_complete_or_replay_finished_prefix() -> void:
	var host: WhalebellyMain=await fixture("ch08_no_reply")
	host.story.interact()
	await physics_frames(10)
	host.story.cinematic.cancel()
	eq(str(host.story.stage().id),"ch08_no_reply","cancel leaves stage uncommitted")
	check(not tree.paused and host.camera.is_current(),"cancel releases all presentation ownership")
	host.story.interaction_armed=true
	check(host.story.interact() and host.story.cinematic.active,"unfinished scene can retry")
	var saved: Dictionary=host.story.to_save()
	host.story.restore(saved)
	check(not host.story.cinematic.active and not tree.paused,"read restore cancels active shot")
	eq(str(host.story.stage().id),"ch08_no_reply","restore never treats half-movie as completed")

func test_opening_defers_dialogue_and_task_skip_does_not_open_next_valve() -> void:
	var host: WhalebellyMain=await fixture("loop.arrival")
	host.story._speak(host.story.stage().lines)
	check(host.story.cinematic.active and host.story.queued_lines.is_empty(),"wake animation precedes opening dialogue")
	await physics_frames(5)
	check(not host.player.get_node("Visual").visible,"paused actor cannot re-enable the original body behind the movie proxy")
	host.story.cinematic.skip()
	await physics_frames(55)
	check(not host.story.queued_lines.is_empty(),"opening dialogue remains after movie")
	eq(str(host.story.stage().id),"loop.arrival","skipping movie never skips its dialogue")
	host.queue_free()
	await physics_frames(2)
	host=await fixture("ch12_rescue_and_brace")
	host.story.pending_task=host.story.stage().tasks[0]
	host.story._speak(host.story.pending_task.lines)
	check(host.story.cinematic.active,"rescue interaction has a movie")
	host.story.cinematic.skip()
	await physics_frames(55)
	check(not host.story.facts.get("ch12_move_elder_safe",false),"rescue fact awaits original dialogue commit")
	check(not host.story.facts.get("ch12_narrow_opening",false),"skip cannot execute subsequent cover interaction")

func test_resize_and_reading_pause_keep_caption_and_clock_stable() -> void:
	var host: WhalebellyMain=await fixture("ch06_04_tides")
	host.story.interact()
	tree.root.size=Vector2i(640,480)
	await physics_frames(5)
	var film: CampaignCinematic=host.story.cinematic
	var caption: Label=film.view.caption
	check(caption.get_minimum_size().y<=caption.size.y,"long caption fits the narrow-window reading band")
	key_event(KEY_TAB,true)
	await physics_frames(2)
	var clock: float=film.clock
	await physics_frames(10)
	eq(film.clock,clock,"holding Tab pauses shot time for reading")
	key_event(KEY_TAB,false)
	await physics_frames(3)
	check(film.clock>clock,"releasing Tab resumes shot")

func test_busy_entry_queues_movie_and_room_leave_cancels_it() -> void:
	var host: WhalebellyMain=await fixture("loop.arrival")
	host.player.hitstop=0.2
	host.story._speak(host.story.stage().lines)
	check(not host.story.cinematic.active and host.story.cinematic.pending_id=="loop.arrival","busy entry queues movie instead of silently losing it")
	await physics_frames(25)
	check(host.story.cinematic.active,"safe recovery starts the queued movie")
	host.story.leave_room()
	check(not host.story.cinematic.active and host.story.cinematic.pending_id.is_empty() and not tree.paused,"room leave clears both pending and active ownership")

func test_real_mouse_skip_button_requires_two_clicks() -> void:
	var host: WhalebellyMain=await fixture("ch02_rescue")
	host.story.interact()
	await physics_frames(4)
	var film: CampaignCinematic=host.story.cinematic
	var at: Vector2=film.view.skip_button.get_global_rect().get_center()
	for click: int in 2:
		for down: bool in [true,false]:
			var event:=InputEventMouseButton.new()
			event.position=at
			event.global_position=at
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=down
			event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
			Input.parse_input_event(event)
			await physics_frames(2)
		if click==0: check(film.skip_armed and film.returning<0,"first real click only requests confirmation")
	check(film.returning>=0,"second real click starts return transition")
