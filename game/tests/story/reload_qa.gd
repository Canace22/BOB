extends 'res://tests/story/flow_qa.gd'
## 第二个独立进程读取QA存档，不注入章节事实或真实存档。
func run() -> void:
 host=load('res://content/whalebelly/main.tscn').instantiate()
 host.set_script(StoryHost)
 host.qa=true
 host.integration_external_test=true
 root.add_child(host)
 current_scene=host
 await tick(12)
 host.story.allow_in_tests=true
 host.load_progress()
 host.load_room(host.room_index,host.checkpoint.pos)
 await tick(20)
 var elder: EnemyLabEnemy=host.story.encounter.body_for('elder_guardian')
 var success: bool=host.story.completed.size()==85 and host.story.stage().is_empty() and bool(host.abilities.get('ending',false)) and bool(host.story.facts.get('ch12_whale_resting',false)) and elder!=null and elder.outcome=='surrender' and elder.collision_layer==0
 print('FORMAL_STORY_INDEPENDENT_RELOAD pass=',success,' completed=',host.story.completed.size(),' room=',host.room.id,' actors=',host.story.view.actors.size(),' elder=',elder.outcome if elder!=null else 'missing')
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://build/qa/formal-story-ending-reload.png')
 await host.graceful_quit(0 if success else 1)
