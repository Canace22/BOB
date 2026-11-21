extends SceneTree
## 真正按键采样，不注入伤害/生命/无敌；站位只在每轮开始布置一次。
const BUTTONS: Array[Key]=[KEY_J,KEY_I,KEY_A,KEY_D,KEY_S,KEY_L]
var pressed: Dictionary={}
var frame_limit: int=3600
var selected: int=-1
var selected_mode: String=""
var baseline: bool=false
var samples: Array[Dictionary]=[]

func _initialize() -> void: run.call_deferred()

func button(code: Key, down: bool) -> void:
	if bool(pressed.get(code,false))==down: return
	pressed[code]=down
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)

func release() -> void:
	for code: Key in BUTTONS: button(code,false)

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="): selected=int(arg.trim_prefix("--profile="))
		elif arg.begins_with("--mode="): selected_mode=arg.trim_prefix("--mode=")
		elif arg.begins_with("--frames="): frame_limit=maxi(120,int(arg.trim_prefix("--frames=")))
		elif arg=="--baseline": baseline=true
	for index: int in [1,2,3,4,5,6,7]:
		if selected>=0 and selected!=index: continue
		for mode: String in ["stand_j","defend","escape"]:
			if mode=="escape" and index!=5: continue
			if not selected_mode.is_empty() and mode!=selected_mode: continue
			await sample(index,mode)
	var out: String="res://build/qa/chapter-pressure/"+("baseline" if baseline else "challenge")+"-"+str(selected)+"-"+selected_mode+".json"
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var file:=FileAccess.open(out,FileAccess.WRITE)
	if file==null:
		push_error("Cannot write chapter pressure sample: "+out)
		quit(1)
		return
	file.store_string(JSON.stringify({"scope":"Actual keyboard in isolated flat arena. State-reading defensive driver is not human difficulty acceptance. Escape sample uses normalized chapter-seven goal; native flow is tested separately.","baseline":baseline,"samples":samples},"\t"))
	print("CHAPTER_PRESSURE_SAMPLE ",out," rounds=",samples.size())
	quit(0)

func sample(index: int, mode: String) -> void:
	release()
	var arena:=ChapterPressureArena.new(index,not baseline)
	root.add_child(arena)
	for i: int in 10: await physics_frame
	var e: EnemyLabEnemy=arena.enemy
	var p: ChapterTwoPlayer=arena.player
	p.position=e.position-Vector2(95,0)
	p.facing=1.0
	if mode=="escape": p.position=Vector2(615,520)
	e.auto_attack=true
	var history: Array[Dictionary]=[]
	var steps: int=0
	var escaped: bool=false
	for frame: int in frame_limit:
		steps=frame+1
		policy(arena,mode,frame)
		await physics_frame
		if frame%30==0:
			history.append({"frame":frame,"hp":e.health,"player_hp":p.health,"state":e.state,"move":e.move_key,"attacks":e.attack_serial,"links":e.pressure.chains,"hits":e.hit_count,"guards":e.parry_count})
		# 第七章坐标按原试验场原点平移：1660-(2310-855)=205，最少压迫3秒。
		escaped=mode=="escape" and frame>=180 and p.position.x<=205 and p.is_on_floor()
		if p.health<=0 or not e.outcome.is_empty() or escaped: break
	release()
	var result: Dictionary={"profile":e.profile.id,"mode":mode,"frames":steps,"simulated_seconds":float(steps)/60.0,"enemy_hp":e.health,"enemy_max":e.maximum,"player_hp":p.health,"outcome":e.outcome,"goal_reached":escaped,"attacks":e.attack_serial,"links":e.pressure.chains,"links_cancelled":e.pressure.cancelled,"received_hits":e.reactions.received,"enemy_hits":e.hit_count,"blocks":e.parry_count,"pressure":e.pressure.snapshot(),"history":history}
	samples.append(result)
	print("PRESSURE_ROUND ",JSON.stringify({"enemy":e.profile.id,"mode":mode,"enemy_hp":e.health,"player_hp":p.health,"attacks":e.attack_serial,"links":e.pressure.chains,"seconds":result.simulated_seconds,"goal":escaped}))
	arena.shutdown()
	root.remove_child(arena)
	arena.free()
	for i: int in 3: await physics_frame

func policy(arena: ChapterPressureArena, mode: String, frame: int) -> void:
	for code: Key in [KEY_A,KEY_D,KEY_S,KEY_L]: button(code,false)
	var e: EnemyLabEnemy=arena.enemy
	var p: ChapterTwoPlayer=arena.player
	if mode=="stand_j":
		button(KEY_I,false)
		button(KEY_J,frame%18<2)
		return
	if mode=="escape" and frame>=180:
		button(KEY_J,false)
		button(KEY_I,false)
		button(KEY_A,true)
		return
	var buttons: Dictionary=ChapterPressureInputPolicy.decide(e,p,frame)
	for code: Key in [KEY_A,KEY_D,KEY_I,KEY_J]: button(code,bool(buttons.get(code,false)))
