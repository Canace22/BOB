extends 'res://tests/whalebelly/world_skeleton.gd'
## 每腿只初始化起点，随后步行/跳跃/锚环与出门都用输入；不是一次连续新档通关。
var route_results: Array[Dictionary]=[]
var selected: String=''
func run() -> void:
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with('--route='): selected=arg.trim_prefix('--route=')
 output='res://build/qa/formal-story-routes'
 DirAccess.make_dir_recursive_absolute(output)
 host=load('res://content/whalebelly/main.tscn').instantiate()
 host.qa=true
 host.integration_external_test=true
 root.add_child(host)
 current_scene=host
 await tick(15)
 host.story.allow_in_tests=true
 host.story.index=host.story.catalog.stages.size()
 host.story.set_process(false)
 host.dialogue.enabled=false
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://tests/fixtures/story_routes.json'))
 for route: Dictionary in data.routes:
  if not selected.is_empty() and not str(route.id).contains(selected): continue
  host.abilities={'anchor':true}
  for ability: String in route.get('required_abilities',[]): host.abilities[ability]=true
  var index: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(route.room_id))
  host.load_room(index,route.get('start_at',host.rooms[index].spawn))
  await tick(25)
  var record: Dictionary={'id':route.id,'steps':[],'pass':true,'initial':host.player.position,'abilities':host.abilities.duplicate()}
  print('ROUTE_START ',route.id,' pos=',host.player.position)
  for step: Dictionary in route.steps:
   var success: bool=false
   var mode: String=str(step.mode)
   if mode=='door':
    var dest: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(step.to))
    var door: Dictionary={}
    for candidate: Dictionary in host.room.get('doors',[]):
     if int(candidate.to)==dest: door=candidate;break
    if not door.is_empty():
     await go_step(host.point(door.pos),{},1200)
     for link: Dictionary in host.streaming.layout.links:
      if not ((int(link.a)==index and int(link.b)==dest) or (int(link.b)==index and int(link.a)==dest)): continue
      var path: PackedVector2Array=link.path.duplicate()
      if int(link.b)==index: path.reverse()
      for world: Vector2 in path:
       if host.room_index==dest: break
       await go_step(host.actor_frame.to_local(world),{},600)
     success=host.room_index==dest
   elif mode=='grapple':
    Input.action_press('right')
    await tick(2)
    Input.action_release('right')
    Input.action_press('grapple')
    await tick(1)
    Input.action_release('grapple')
    await tick(100)
    success=host.player.grapple_hanging and host.player.position.distance_to(host.point(step.at))<45
   elif mode=='jump_release_from_grapple':
    Input.action_press('tp_jump')
    await tick(int(step.get('hold_frames',2)))
    Input.action_release('tp_jump')
    await tick(int(step.get('wait_frames',90)))
    success=not host.player.grapple_hanging
   else:
    success=await go_step(host.point(step.at),step,int(step.get('budget',900)))
   record.steps.append({'mode':mode,'at':step.get('at',[]),'pass':success,'position':host.player.position,'room':host.room.id})
   print('ROUTE_STEP ',route.id,' ',mode,' target=',step.get('at',step.get('to')),' pass=',success,' end=',host.player.position)
   if not success:
    record.pass=false
    break
  route_results.append(record)
  if DisplayServer.get_name()!='headless':
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(output.path_join(str(route.id)+'.png'))
 var failed: int=route_results.filter(func(r: Dictionary) -> bool:return not r.pass).size()
 var file:=FileAccess.open(output.path_join('report-'+('all' if selected.is_empty() else selected)+'.json'),FileAccess.WRITE)
 file.store_string(JSON.stringify({'method':'per-room starts, source available abilities, actual Input actions thereafter; no enemy/hazard injection; NOT one continuous story playthrough','routes':route_results,'failures':failed},'\t'))
 print('STORY_ROUTES tested=',route_results.size(),' failed=',failed)
 await host.graceful_quit(1 if failed>0 else 0)
func go_step(target: Vector2, spec: Dictionary, budget: int) -> bool:
 var start_room: int=host.room_index
 var hold: int=0
 var wait: int=0
 var jump_age: int=-1
 var double_sent: bool=false
 var launch_y: float=host.player.position.y

 if spec.has('launch_x'):
  for frame: int in 90:
   var distance: float=float(spec.launch_x)-host.player.position.x
   if absf(distance)<7: break
   Input.action_release('left');Input.action_release('right')
   Input.action_press('right' if distance>0 else 'left')
   await physics_frame
  host.release_controls()
 var drop_edge: float=INF
 var drop_from: float=0
 var reached: bool=false
 for frame: int in budget:
  var p: WhalebellyCampaignPlayer=host.player
  if host.room_index!=start_room: break
  var delta: Vector2=target-p.position
  if absf(delta.x)<32 and absf(delta.y)<45 and (p.is_on_floor() or spec.get('allow_pass_through',false)):
   reached=true
   break
  Input.action_release('left');Input.action_release('right')
  if p.is_on_floor() and delta.y>70 and absf(delta.x)<90 and drop_edge==INF:
   for surface: Array in host.room.surfaces:
    var a: Vector2=host.point(surface[0])
    var b: Vector2=host.point(surface[-1])
    if p.position.x>=a.x-8 and p.position.x<=b.x+8 and absf(p.position.y-a.y)<35:
     drop_from=p.position.y
     drop_edge=a.x-45 if absf(p.position.x-a.x)<absf(p.position.x-b.x) else b.x+45
     break
  if drop_edge!=INF and p.position.y<drop_from+25: delta.x=drop_edge-p.position.x
  else: drop_edge=INF
  if absf(delta.x)>12: Input.action_press('right' if delta.x>0 else 'left')
  hold-=1
  wait-=1
  if hold==0: Input.action_release('tp_jump')
  if jump_age>=0: jump_age+=1
  if p.is_on_floor() and (jump_age<0 or jump_age>10):
   double_sent=false
   jump_age=-1
   launch_y=p.position.y
  var leap: bool=str(spec.get('mode','tp_jump'))!='drop'
  if p.is_on_floor() and wait<=0 and ((delta.y< -40 and (absf(delta.x)<190 or footing_ends(signf(delta.x)))) or (leap and absf(delta.x)>90 and footing_ends(signf(delta.x)))):
   Input.action_press('tp_jump')
   hold=int(spec.get('jump_hold',26))
   wait=44
   jump_age=0
  if str(spec.get('mode',''))=='double' and not p.is_on_floor() and jump_age>16 and not double_sent:
   Input.action_release('tp_jump')
   await tick(1)
   Input.action_press('tp_jump')
   double_sent=true
   hold=25
  if str(spec.get('mode',''))=='jump-dash' and jump_age==int(spec.get('dash_frame',8)):
   Input.action_press('tp_dash')
  else: Input.action_release('tp_dash')
  if str(spec.get('mode',''))=='jump_release_from_grapple' and p.grapple_hanging:
   Input.action_press('tp_jump')
   hold=26
  if not p.is_on_floor() and delta.y<20 and hold<4 and target.y<launch_y-170 and host.has_ability('float'): Input.action_press('float')
  else: Input.action_release('float')
  await physics_frame
 host.release_controls()
 Input.action_release('tp_jump')
 Input.action_release('tp_dash')
 await tick(8)
 return (reached and bool(spec.get('allow_pass_through',false))) or (host.room_index==start_room and absf(host.player.position.x-target.x)<60 and absf(host.player.position.y-target.y)<60)
