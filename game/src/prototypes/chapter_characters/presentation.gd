class_name ChapterCharacterPresentation
extends Node2D
## 只读演员层，由已有view推进；不加Tick、不生成碰撞、不接管敌人或战后身体。
var actors: Dictionary={}
var specs: Array=[]

func install(chapter: int) -> void:
	specs=ChapterCharacterBindings.actors(chapter)
	for spec: Dictionary in specs: add_actor(str(spec.key),str(spec.id),float(spec.height))

func add_actor(key: String, id: String, height: float) -> void:
	var actor:=ChapterCharacterActor.new()
	actor.name=key
	actor.configure(id,height)
	add_child(actor)
	actors[key]=actor

func put(key: String, at: Vector2, shown: bool=true) -> void:
	var actor: ChapterCharacterActor=actors.get(key) as ChapterCharacterActor
	if actor==null: return
	actor.position=at
	actor.visible=shown and actor.texture!=null

func update_run(host: ChapterRun) -> void:
	if not is_instance_valid(host.flow): return
	var stage: String=str(host.flow.stage().get("id",""))
	# 白盒结尾保留最后工作位，不能完成出口后把仍在场的居民瞬移回章节入口。
	if stage.is_empty() and host.flow.finished and not host.data.stages.is_empty():
		stage=str(host.data.stages.back().id)
	for spec: Dictionary in specs:
		var key: String=str(spec.key)
		var shown: bool=true
		# 战斗身体/停战身体一旦存在，本层同身份演员必须让位；死去封梁卫不重生。
		if key in ["beam","warden","elder"]:
			var encounter: ChapterRunEncounter=host.encounter
			var owned: bool=(is_instance_valid(encounter.enemy) and str(encounter.enemy.profile.id)==str(spec.id)) or (is_instance_valid(encounter.retired_body) and str(encounter.retired_body.profile.id)==str(spec.id))
			shown=not owned
			if host.chapter_id==8 and (stage in ["ch08_no_reply","ch08_receive_nests","ch08_exit"] or bool(host.flags.get("ch08_beam_guard_dead",false))): shown=false
		if host.chapter_id==8 and key=="guard":
			shown=stage in ["ch08_no_reply","ch08_receive_nests","ch08_exit"]
			if stage=="ch08_no_reply": shown=host.flow.observing and host.flow.observation_time>=2.5
		if host.chapter_id==12 and key=="mender": shown=stage in ["ch12_recovery_life","ch12_exit"]
		put(key,ChapterCharacterBindings.position_for(host.chapter_id,key,stage,spec.at,host.flags),shown)

func install_residents(with_mender: bool=false) -> void:
	add_actor("resident_0","resident_settled",74)
	add_actor("resident_1","resident_migrant",84)
	if with_mender:
		add_actor("mender","nest_mender",104)
		# 对白只称“守卫”，沿用守卫群体轮廓，不据此认定是第二章的同一个人。
		add_actor("valve_guard","shell_guard",84)
	else: add_actor("resident_2","resident_carrier",54)

func update_two(host: ChapterTwoWhitebox) -> void:
	var stage: String=host.flow.stage
	var time: float=host.flow.rescue_time
	var saved: bool=bool(host.facts.get("rescue_done",false))
	var drop: float=34 if saved else 0
	if stage=="rescue":
		drop=lerpf(0,78,clampf(time/2,0,1))
		if time>3: drop=lerpf(78,34,clampf((time-3)/3,0,1))
	for i: int in 3:
		var ratio: float=1 if saved else (clampf((time-3-i*0.5)/2.2,0,1) if stage=="rescue" else 0)
		var safe:=Vector2(2410+i*78,650)
		if stage in ["permitted","complete"]: safe.x+=minf(220,maxf(0,host.flow.departure_time-i*0.6)*55)
		put("resident_"+str(i),Vector2(2160+i*54,502+drop).lerp(safe,ratio))

func update_three(host: ChapterTwoWhitebox) -> void:
	var flooded: bool=bool(host.facts.get("valve_opened",false)) and (host.flow.stage!="rescue" or host.flow.rescue_time>=5)
	put("mender",Vector2(910,520))
	put("resident_0",Vector2(625,520))
	put("resident_1",Vector2(715,520))
	put("valve_guard",Vector2(2210,650),flooded)
