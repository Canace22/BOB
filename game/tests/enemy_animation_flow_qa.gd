extends SceneTree
## 通过真实begin_attack与物理状态推进检查覆盖；输入、敌人站位和复制记忆是隔离夹具。
var lab: EnemyLab
var records: Array[Dictionary]=[]
var failures: Array[String]=[]
var delegated: Dictionary={}
const OUT: String="res://build/qa/enemy-animation-flow"
func _initialize() -> void: run.call_deferred()
func ticks(count: int) -> void:
 for i: int in count: await physics_frame
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 lab=preload('res://content/prototypes/enemy_lab/main.tscn').instantiate()
 lab.auto_attack=false;lab.ranges=false;lab.invincible=true;lab.all_skill_practice=true
 root.add_child(lab);current_scene=lab
 await ticks(15)
 for idx: int in EnemyLabCatalog.PROFILES.size():
  lab.profile_index=idx
  var moves: Array=EnemyLabCatalog.PROFILES[idx].moves.duplicate()
  if idx==3: moves.append('escape-trigger')
  if idx==6: moves.append('defense-trigger')
  for action: String in moves:
   lab.reset_round();await ticks(10)
   var e: EnemyLabEnemy=lab.enemies[0]
   lab.player.invincible=true
   lab.player.position=Vector2(500,520)
   if e is EnemyLabElder and action=='elder_mimic':
    lab.player.request_action('strike_01')
    await ticks(20)
   lab.player.set_physics_process(false)
   var okay: bool=false
   if action=='escape-trigger':
    e.begin_attack('hunter_pounce')
    (e as EnemyLabPredator)._prepare_escape()
    okay=true
   else: okay=e.begin_attack('beam_guard' if action=='defense-trigger' else action)
   if not okay: failures.append('begin failed '+str(e.profile.id)+'/'+action);continue
   var observed: Dictionary={}
   for tick: int in 600:
    await physics_frame
    var state: String=e.state
    if state=='guarding' and action=='defense-trigger': e.take_hit(1)
    if state=='idle' and tick>5: break
    var progress: float=clampf(e.timer/maxf(e.phase_duration(),0.001),0,.999)
    var bucket: int=int(progress*3)
    var group: String='%s:%d:%d'%[state,e.pulse,bucket]
    if observed.has(group): continue
    observed[group]=true
    var sample: Dictionary=e.visual.animation_override.sample(str(e.profile.id),e.move_key,state,e.pulse,progress,"clips",e.phase_duration())
    if sample.is_empty():
     var owned_elsewhere: bool=(e.move_key=='eel_burrow' and state in ['dive','tunnel']) or (e.move_key=='warden_waterstep' and state=='wash') or (e.move_key=='elder_mimic' and state in ['active','recover'])
     var key: String='%s/%s/%s'%[e.profile.id,e.move_key,state]
     if owned_elsewhere: delegated[key]=true
     elif state!='idle' and not failures.has(key): failures.append('unexpected legacy body '+key)
    var data: Dictionary={'profile':e.profile.id,'request':action,'action':e.move_key,'state':state,'pulse':e.pulse,'timer':e.timer,'progress':progress,'override':not sample.is_empty(),'texture':e.visual.texture.resource_path,'frame':e.visual.region_rect,'fx':e.visual.windup_view.visible}
    records.append(data)
    if DisplayServer.get_name()!='headless':
     await process_frame;await RenderingServer.frame_post_draw
     var filename: String='%s-%s-%s-p%d-%d.png'%[e.profile.id,action,state,e.pulse,bucket]
     root.get_texture().get_image().save_png(OUT.path_join(filename))
  print('FLOW_PROFILE_DONE ',EnemyLabCatalog.PROFILES[idx].id)
 var file:=FileAccess.open(OUT.path_join('coverage.json'),FileAccess.WRITE)
 file.store_string(JSON.stringify({'method':'actual begin_attack and physics transitions; explicit spawn, source skill, escape stimulus and guarded hit fixtures','records':records,'failures':failures,'delegated_existing_transitions':delegated.keys()},'\t'))
 print('ENEMY_FLOW records=',records.size(),' failures=',failures)
 lab.queue_free();await process_frame;quit(1 if not failures.is_empty() else 0)
