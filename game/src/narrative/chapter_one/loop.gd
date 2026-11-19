class_name WhaleChapterOneLoop
extends Node2D
## 一次遭遇的阶段、通行判定与采样；对白由既有叙事控制器播放，运行仅用于隔离样板。
var host: Node2D
var enemies: Array[WhaleChapterForager] = []
var stage: String = "arrival"
var encounter: bool = false
var passed: bool = false
var safe_time: float = 0.0
var reset_pending: bool = false
var elapsed: float = 0.0
var sample_left: float = 0.0
var last_x: float = 0.0
var still_time: float = 0.0
var observed: bool = false
var strikes: int = 0
var guards: int = 0
var backsteps: int = 0
var damage_taken: int = 0
var beats: Array[Dictionary] = []

func _ready() -> void:
	beats=host.loop_beats
	elapsed=host.clock
	for child: Node in host.scenery.get_children():
		if child.name=="OpeningNarrative": child.queue_free()
	host.player.animation_tag.connect(_action)
	host.player.backstep_started.connect(func() -> void: backsteps+=1)
	host.player.damaged.connect(func() -> void: damage_taken+=1)
	host.player.died.connect(_failed)
	host.dialogue.ended.connect(_dialogue_finished)
	last_x=host.player.position.x
	for i: int in 2:
		var enemy := WhaleChapterForager.new()
		enemy.host=host
		var x: float=820.0 if i==0 else 1100.0
		enemy.data={"key":"loop.forager."+str(i),"type":"corpse-crab","boss":false,"alive":true,"hp":8,"max_hp":8,"hurt":0.0,"pos":Vector2(x,host.ground_y(x,560.0))}
		enemy.lane=Vector2(650,1160) if i==0 else Vector2(760,1280)
		enemy.opening_delay=0.35 if i==1 else 0.0
		host.scenery.get_node("World").add_child(enemy)
		enemies.append(enemy)
		host.enemies.append(enemy.data)
	if host.dialogue.seen.get("loop.warning",false): stage="approach"
	passed=bool(host.dialogue.seen.get("loop.passage",false))
	if passed:
		for enemy: WhaleChapterForager in enemies: enemy.withdraw()
		stage="aftermath"
	mark("ready",{"restored_passage":passed})

func _action(tag: String) -> void:
	if tag.ends_with(":start"):
		if tag=="parry:start": guards+=1
		elif tag in ["strike_01:start","strike_02:start","heavy:start"]: strikes+=1

func mark(id: String, values: Dictionary = {}) -> void:
	var beat: Dictionary={"id":id,"seconds":snappedf(elapsed,0.01),"wall_seconds":snappedf((Time.get_ticks_msec()-host.wall_start_ms)/1000.0,0.01),"stage":stage}
	beat.merge(values)
	beats.append(beat)
	host.record_event("chapter_loop_"+id,values)
	save_report()

func _process(dt: float) -> void:
	if not is_instance_valid(host.player) or host.quitting: return
	if host.dialogue.seen.get("loop.warning",false) and not host.dialogue.seen.get("loop.passage",false):
		if not host.player_ui.busy: host.checkpoint={"room":0,"pos":[500,host.ground_y(500,580)]}
	if get_tree().paused: return
	elapsed=host.clock
	var p: WhalebellyCampaignPlayer=host.player
	if p.health<=0: return
	var x: float=p.position.x
	if x>580 and x<790 and p.position.y<470 and p.is_on_floor() and not observed:
		observed=true
		mark("observation",{"position":[x,p.position.y]})
	if host.dialogue.seen.get("loop.warning",false) and not passed:
		if x>640 and not encounter:
			encounter=true
			stage="encounter"
			enemies[0].awake=true
			mark("encounter_started")
			host.notify("甲壳从聚食处迎上来 · 等它扑空，后跳或换位")
		if encounter and (x>860 or enemies[0].withdrawing): enemies[1].awake=true
		if encounter and x<550: reset_pending=true
		if reset_pending and x<550 and p.is_on_floor() and p.state_duration<=0.0:
			for enemy: WhaleChapterForager in enemies: enemy.reset_feeding()
			encounter=false
			reset_pending=false
			stage="approach"
			mark("withdraw_to_entry")
		# 记录跨过整段聚食区，不要求落在灯旁的窄框；跳过灯也必须接上结果。
		if encounter and x>=1290: complete_passage()
	if passed and not host.dialogue.seen.get("loop.aftermath",false):
		var aftermath: WhaleDialogueTrigger=get_node("Aftermath")
		# 玩家越过整片触发区后，也在安全落地时主动补播，避免只能回头找灯。
		if p.is_on_floor(): host.dialogue.play(aftermath)
	if passed and host.dialogue.seen.get("loop.aftermath",false) and x>=1510 and p.is_on_floor():
		host.enter_door({"to":1})
	still_time=still_time+dt if absf(x-last_x)<0.5 else 0.0
	last_x=x
	sample_left+=dt
	if sample_left>=30.0:
		sample_left=0.0
		mark("sample",{"x":x,"idle_seconds":still_time,"health":p.health})
		save_report()

func complete_passage() -> void:
	passed=true
	stage="aftermath"
	for enemy: WhaleChapterForager in enemies:
		enemy.feeding_x=820.0 if enemy==enemies[0] else 960.0
		enemy.withdraw()
	# 通行结果持久化为稳定叙事事实；不依赖击杀和Combo，退出后不重复拦路。
	host.dialogue.seen["loop.passage"]=true
	host.dialogue.objective={"id":"loop.confirm","text":"已穿过聚食区 · 补巢者正在回应","room":"R1-01"}
	mark("passage",{"alive":enemies.filter(func(e: WhaleChapterForager) -> bool: return e.data.alive).size()})
	host.save_progress(false)

func _dialogue_finished() -> void:
	if host.dialogue.seen.get("loop.warning",false) and stage=="arrival": stage="approach"
	if host.dialogue.seen.get("loop.aftermath",false) and passed:
		stage="onward"
		mark("onward_goal")

func save_report() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapter-loop")
	var file := FileAccess.open("res://build/qa/chapter-loop/latest-play.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"stage":stage,"beats":beats,"seconds":elapsed,"strikes":strikes,"guards":guards,"backsteps":backsteps,"damage_taken":damage_taken,"observed":observed,"notes":"Scripted input proves route execution only; player motivation and pacing require human playtest."},"\t"))

func _failed() -> void:
	mark("failed",{"strikes":strikes,"guards":guards,"backsteps":backsteps,"damage_taken":damage_taken})
