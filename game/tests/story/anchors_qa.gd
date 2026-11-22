extends SceneTree
## 只读真实房间碰撞射线，逐个审计章节锚点；不作为可走路线或通关证据。
var host: WhalebellyMain
var records: Array[Dictionary]=[]
var failures: Array[Dictionary]=[]
func _initialize() -> void: run.call_deferred()
func ticks(count: int) -> void:
 for i: int in count: await physics_frame
func run() -> void:
 host=load('res://content/whalebelly/main.tscn').instantiate()
 host.qa=true
 host.integration_external_test=true
 root.add_child(host)
 current_scene=host
 await ticks(12)
 host.story.allow_in_tests=true
 host.story.set_process(false)
 host.streaming.enabled=false
 var points: Dictionary={}
 for stage: Dictionary in host.story.catalog.stages:
  var list: Array=points.get(stage.room_id,[])
  list.append({'id':stage.id,'at':stage.at,'kind':'stage'})
  for task: Dictionary in stage.get('tasks',[]):
   var task_room: String=str(task.get('room_id',stage.room_id))
   if task_room==str(stage.room_id): list.append({'id':task.id,'at':task.at,'kind':'task'})
   else:
    var remote: Array=points.get(task_room,[])
    remote.append({'id':task.id,'at':task.at,'kind':'task'})
    points[task_room]=remote
  for actor: Dictionary in stage.get('actors',[]): list.append({'id':str(stage.id)+'/'+str(actor.id),'at':actor.at,'kind':'actor'})
  if stage.has('enemy'): list.append({'id':str(stage.id)+'/enemy','at':stage.enemy.at,'kind':'enemy'})
  points[stage.room_id]=list
 for id: String in points:
  var index: int=host.rooms.find_custom(func(r: Dictionary) -> bool: return str(r.id)==id)
  host.load_room(index,[],false)
  host.player.set_physics_process(false)
  await ticks(8)
  for point: Dictionary in points[id]:
   var local: Vector2=host.point(point.at)
   var start: Vector2=host.scenery.to_global(local-Vector2(0,12))
   var stop: Vector2=host.scenery.to_global(local+Vector2(0,220))
   var hit: Dictionary=host.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(start,stop,1))
   var actual: float=host.scenery.to_local(hit.position).y if not hit.is_empty() else INF
   var record: Dictionary={'room':id,'id':point.id,'kind':point.kind,'at':point.at,'ground_y':actual,'delta_y':actual-local.y,'supported':absf(actual-local.y)<16}
   records.append(record)
   if not record.supported: failures.append(record)
 print('STORY_ANCHORS samples=',records.size(),' unsupported=',failures.size())
 for failure: Dictionary in failures: print('ANCHOR ',failure)
 var file:=FileAccess.open('res://build/qa/formal-story-anchors.json',FileAccess.WRITE)
 file.store_string(JSON.stringify({'method':'actual active room physics rays; no traversal claim','records':records,'failures':failures},'\t'))
 await host.graceful_quit(0 if failures.is_empty() else 1)
