extends TestSuite
## 正式叙事的进度/跳过/跨房任务合同，不以定位夹具冒充徒步通关。
class StoryHost extends WhalebellyMain:
 func save_path() -> String: return 'user://whalebelly/story-unit-tests.json'
func test_pre_tree_v6_restore_waits_for_actual_room_catalog() -> void:
 var host: WhalebellyMain=load('res://content/whalebelly/main.tscn').instantiate()
 host.set_script(StoryHost)
 host.qa=true
 host.integration_external_test=true
 host.rooms=[{'id':'R1-01'}]
 host.ensure_dialogue()
 host.ensure_story()
 host.story.restore({'version':1,'completed':['loop.arrival'],'facts':{'arrival_seen':true}})
 check(not host.story.configured,'pre-tree restore does not validate an incomplete room table')
 add(host)
 await physics_frames(12)
 check(host.story.configured and host.story.catalog.errors.is_empty(),'real startup validates all formal rooms')
 eq(str(host.story.stage().id),'loop.warning','deferred story state is restored after real catalog exists')
func fixture(stage_id: String) -> WhalebellyMain:
 var host: WhalebellyMain=load('res://content/whalebelly/main.tscn').instantiate()
 host.set_script(StoryHost)
 host.qa=true
 host.integration_external_test=true
 add(host)
 await physics_frames(12)
 host.story.allow_in_tests=true
 host.ui_interactive_in_tests=true
 host.dialogue.enabled=true
 var prefix: Array[String]=[]
 var facts: Dictionary={}
 for s: Dictionary in host.story.catalog.stages:
  if str(s.id)==stage_id: break
  prefix.append(str(s.id))
  for flag: String in s.get('grant',[]): facts[flag]=true
  for task: Dictionary in s.get('tasks',[]): facts[str(task.id)]=true
 host.story.restore({'version':1,'completed':prefix,'facts':facts})
 var stage: Dictionary=host.story.stage()
 var room: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(stage.room_id))
 host.load_room(room,stage.at)
 host.story.set_process(false)
 host.player.position=host.point(stage.at)-Vector2(0,3)
 await physics_frames(15)
 return host
func test_skipping_inspection_never_opens_dangerous_valve() -> void:
 var host: WhalebellyMain=await fixture('ch03_valve')
 check(host.dialogue.play_script('formal_story/ch03_valve',host.story.stage().lines),'formal dialogue uses original UI pause owner')
 host.story.dialogue_token='formal_story/ch03_valve'
 host.dialogue.finish(true)
 eq(str(host.story.stage().id),'ch03_open_valve','skip completes inspection only')
 check(not host.story.facts.get('ch03_valve_opened',false),'skip does not perform opening')
 host.story.interaction_armed=false
 check(host.story.interact(),'same held input is consumed')
 check(not host.story.facts.get('ch03_valve_opened',false),'held F cannot execute fresh dangerous action')
 await physics_frames(16)
 host.story.interaction_armed=true
 host.player.position=host.point(host.story.active_tasks()[0].at)-Vector2(0,1)
 await physics_frames(6)
 check(host.story.interact(),'new deliberate interaction is accepted')
 check(host.story.facts.get('ch03_valve_opened',false),'opening happens only after the separate F')
func test_three_contact_rooms_persist_partial_tasks_and_route_to_next_real_door() -> void:
 var host: WhalebellyMain=await fixture('ch11_check_contacts')
 var stage: Dictionary=host.story.stage()
 var first: Dictionary=stage.tasks[0]
 host.story.pending_task=first
 host.story.finish_task()
 var saved: Dictionary=host.story.to_save()
 var checkpoint: Vector2=host.player.global_position
 host.story.restore(saved)
 check(host.story.facts.get(str(first.id),false),'completed first touch survives restore')
 var target: Dictionary=host.story.target()
 eq(str(target.room_id),'R5-02','remaining contact is in its own formal room')
 eq(CampaignStoryRoutes.next_room(host.story),'R5-02','guide uses the actual adjacent door')
 eq(host.player.global_position,checkpoint,'restore never teleports to next contact')
 var room: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)=='R5-02')
 host.load_room(room,target.at)
 await physics_frames(12)
 check(host.story.current_room() and host.story.task_near(target),'remote task becomes interactable only in its actual room')
func test_story_completion_prefix_rejects_future_stage_skip_and_keeps_legacy_save_shape() -> void:
 var host: WhalebellyMain=await fixture('loop.arrival')
 host.story.restore({'version':1,'completed':['ch12_exit'],'facts':{}})
 eq(str(host.story.stage().id),'loop.arrival','future completion cannot bypass unresolved beginning')
 host.save_progress(false)
 var payload: Dictionary=WhaleUISaveAccess.read(host.save_path(),host.rooms)
 eq(int(payload.version),6,'existing room/checkpoint save version remains compatible')
 eq(int(payload.chapter_story.version),1,'story schema lives in explicit extension')
 check(payload.chapter_story.completed.is_empty(),'invalid future prefix is not persisted')
func test_battle_stage_cannot_complete_by_walking_to_its_exit_or_legacy_ending_pickup() -> void:
 var host: WhalebellyMain=await fixture('ch12_elder_duel')
 var before: int=host.story.index
 host.interact()
 eq(host.story.index,before,'interaction cannot stand in for combat result')
 check(not host.abilities.get('ending',false),'legacy ending reward does not bypass finale')
 check(host.enemies.is_empty(),'old room bosses are not spawned alongside chapter executor')

func test_practice_cancels_story_combat_without_committing_the_result() -> void:
 var host: WhalebellyMain=await fixture('ch03_mudback')
 host.story._spawn(host.story.stage())
 check(is_instance_valid(host.story.encounter.enemy),'actual story battle owns an executor')
 var index: int=host.story.index
 var event:=InputEventKey.new()
 event.physical_keycode=KEY_F9
 event.pressed=true
 host._unhandled_key_input(event)
 check(host.practice and not is_instance_valid(host.story.encounter.enemy),'practice removes active story damage owner')
 eq(host.story.index,index,'practice does not complete battle')
 host._unhandled_key_input(event)
 check(not host.practice and host.story.running(),'return restores story mode')
 eq(host.story.index,index,'return requires the unresolved battle again')
