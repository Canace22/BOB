extends 'res://tests/story/flow_qa.gd'
## 原生正式场景的对白/人物截图夹具，起点和历史进度为显式设置。
func run() -> void:
 host=load('res://content/whalebelly/main.tscn').instantiate()
 host.qa=true
 host.integration_external_test=true
 root.add_child(host)
 current_scene=host
 await tick(12)
 host.story.allow_in_tests=true
 host.ui_interactive_in_tests=true
 host.dialogue.enabled=true
 host.streaming.enabled=false
 var targets: Array[String]=['loop.warning','ch02_refusal','ch12_return_name']
 for target: String in targets:
  host.story.restore({})
  host.story.set_process(false)
  for stage: Dictionary in host.story.catalog.stages:
   if str(stage.id)==target: break
   host.story.completed.append(str(stage.id))
   host.story.index+=1
  var s: Dictionary=host.story.stage()
  host.dialogue.cancel()
  host.player_ui.close_all()
  var index: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(s.room_id))
  host.load_room(index,s.at)
  host.player.position=host.point(s.at)-Vector2(0,3)
  await tick(25)
  host.story.set_process(true)
  for frame: int in 120:
   await tick(1)
   if not host.dialogue.active.is_empty(): break
  if host.dialogue.active.is_empty():
   push_error('Formal visual dialogue did not trigger '+target)
   continue
  for line: int in 3:
   if host.dialogue.active.is_empty(): break
   host.player_ui.dialogue_view.reveal=10000
   await tick(2)
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png('res://build/qa/formal-story-'+target+'-'+str(line)+'.png')
   host.dialogue.advance()
  host.story.set_process(false)
  host.dialogue.cancel()
  await tick(20)
 print('FORMAL_STORY_VISUAL captured formal dialogue and NPCs')
 await host.graceful_quit()
