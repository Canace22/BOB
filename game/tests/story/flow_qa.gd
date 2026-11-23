extends SceneTree
## 全阶段接口夹具：房内点位显式定位，战斗用伤害夹具；不是徒步或战斗难度验收。
class StoryHost extends WhalebellyMain:
 func save_path() -> String: return 'user://whalebelly/formal-story-flow-fixture.json'
var host: WhalebellyMain
var failures: Array[String]=[]
var passed: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
 for i: int in n: await physics_frame
func key(code: Key, pressed: bool) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 Input.parse_input_event(event)
func tap() -> void:
 key(KEY_F,true)
 await tick(2)
 key(KEY_F,false)
 await tick(12)
func locate(room: String, point: Array) -> void:
 if str(host.room.id)!=room:
  var at: int=host.rooms.find_custom(func(r: Dictionary) -> bool: return str(r.id)==room)
  host.load_room(at,point)
 host.player.position=host.point(point)-Vector2(0,3)
 host.player.last_safe=host.point(point)
 host.player.velocity=Vector2.ZERO
 await tick(15)
func run() -> void:
 host=load('res://content/whalebelly/main.tscn').instantiate()
 host.set_script(StoryHost)
 host.qa=true
 host.integration_external_test=true
 root.add_child(host)
 current_scene=host
 await tick(15)
 host.ui_interactive_in_tests=true
 host.dialogue.enabled=true
 host.story.allow_in_tests=true
 host.streaming.enabled=false
 host.story.restore({})
 host.load_room(0)
 await tick(12)
 for iteration: int in 400:
  var stage: Dictionary=host.story.stage()
  if stage.is_empty(): break
  var id: String=str(stage.id)
  print('FLOW_STAGE ',id,' kind=',stage.kind,' room=',stage.room_id)
  await locate(str(stage.room_id),stage.at)
  if str(stage.kind)=='dialogue':
   for i: int in 80:
    await tick(1)
    if not host.dialogue.active.is_empty(): break
  elif str(stage.kind)=='battle':
   for i: int in 80:
    await tick(1)
    if is_instance_valid(host.story.encounter.enemy): break
   var enemy: EnemyLabEnemy=host.story.encounter.enemy
   if is_instance_valid(enemy):
    enemy.take_hit(100000)
    await tick(3)
   else: failures.append(id+': battle did not start')
  elif str(stage.kind)=='escape':
   await tick(90)
   await locate(str(stage.room_id),stage.goal)
   await tick(15)
  elif str(stage.kind)=='explore':
   var tasks: Array[Dictionary]=host.story.active_tasks()
   if tasks.is_empty(): failures.append(id+': no available task');break
   var task: Dictionary=tasks[0]
   await locate(str(task.get('room_id',stage.room_id)),task.at)
   await tap()
  else:
   await tap()
   if str(stage.kind)=='observe': await tick(int(float(stage.get('duration',5))*60)+8)
  await tick(25)
  for step: int in 1800:
   if host.story.cinematic.active:
    await tick(1)
    continue
   if not host.story.queued_lines.is_empty():
    await tick(1)
    continue
   if host.dialogue.active.is_empty(): break
   await tap()
  await tick(20)
  if host.story.index<host.story.catalog.stages.size() and str(host.story.stage().id)==id:
   if str(stage.kind)=='explore': continue
   failures.append(id+': stage did not complete; pos='+str(host.player.position)+' onfloor='+str(host.player.is_on_floor())+' queued='+str(host.story.queued_lines.size()))
   break
  passed.append(id)
 if not host.story.stage().is_empty(): failures.append('flow stopped before final stage')
 print('FORMAL_STORY_FLOW passed=',passed.size(),' completed=',host.story.completed.size(),' total=',host.story.catalog.stages.size(),' failures=',failures)
 var file:=FileAccess.open('res://build/qa/formal-story-flow.json',FileAccess.WRITE)
 file.store_string(JSON.stringify({'method':'explicit room/anchor scenario positioning; genuine F dialogue/task input; combat damage fixture, no invincible traversal; NOT full input playthrough','passed':passed,'failures':failures,'events':host.events},'\t'))
 await host.graceful_quit(0 if failures.is_empty() and host.story.stage().is_empty() else 1)
