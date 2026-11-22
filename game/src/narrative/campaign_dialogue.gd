class_name WhaleCampaignDialogue
extends Node
## 主线拥有叙事进度；触发器提供内容，UI拥有暂停与恢复，控制器不另改time_scale。
signal started(spec: Dictionary)
signal line_changed(speaker: String, text: String)
signal ended
signal subtitle_changed(text: String)
signal committed(id: String)
var host: Node2D
var enabled: bool = true
var seen: Dictionary = {}
var objective: Dictionary = {}
var active: Dictionary = {}
var cursor: int = 0
var pending: WeakRef
var subtitle_left: float = 0.0
var subtitle_room: String = ""
var subtitle_player: WeakRef

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func available() -> bool:
	if not enabled or host.quitting or host.practice or host.room_preview: return false
	if host.qa and not host.ui_interactive_in_tests: return false
	if not is_instance_valid(host.player) or not is_instance_valid(host.player_ui): return false
	if host.player.health <= 0 or not host.player.controls_enabled or host.player.transition_locked: return false
	if host.reference_visible or host.layer_solo >= 0 or not host.capture_path.is_empty(): return false
	return host.player_ui.page_id.is_empty() and not host.player_ui.pending_resume and not get_tree().paused

func safe_to_talk() -> bool:
	var p: TidePlayer = host.player
	if p.state_duration > 0.0 or p.hitstop > 0.0 or p.damage_flash_left > 0.0: return false
	if p.get("retreating") == true: return false
	for target: Node2D in get_tree().get_nodes_in_group("tide_targets"):
		if target.has_method("can_receive_hit") and not target.can_receive_hit(): continue
		if target.global_position.distance_to(p.global_position)<320.0: return false
	for orb: Node2D in get_tree().get_nodes_in_group("tide_hostile_projectiles"):
		if orb.global_position.distance_to(p.global_position)<420.0: return false
	return true

func triggers() -> Array[WhaleDialogueTrigger]:
	var result: Array[WhaleDialogueTrigger] = []
	if is_instance_valid(host.get("story")) and host.story.running(): return result
	for node: Node in get_tree().get_nodes_in_group("campaign_dialogue_triggers"):
		if node is WhaleDialogueTrigger and node.eligible(host,seen): result.append(node)
	result.sort_custom(func(a: WhaleDialogueTrigger,b: WhaleDialogueTrigger) -> bool: return a.priority>b.priority)
	return result

func _process(dt: float) -> void:
	if subtitle_left > 0.0:
		subtitle_left = maxf(0.0,subtitle_left-dt)
		if str(host.room.id)!=subtitle_room or not is_instance_valid(subtitle_player.get_ref()) or host.player!=subtitle_player.get_ref() or host.player.health<=0: subtitle_left=0.0
		if subtitle_left<=0.0: subtitle_changed.emit("")
	if not available() or not active.is_empty() or subtitle_left>0.0: return
	# 在战斗中进入触发范围时先登记，到安全处再播；跨房后丢弃旧房请求。
	if pending != null:
		var queued: WhaleDialogueTrigger = pending.get_ref() as WhaleDialogueTrigger
		if not is_instance_valid(queued) or not queued.eligible(host,seen): pending=null
	if pending == null:
		for trigger: WhaleDialogueTrigger in triggers():
			if trigger.activation!=1 and trigger.contains(host.player):
				pending=weakref(trigger)
				break
	if pending == null or not safe_to_talk(): return
	var next: WhaleDialogueTrigger = pending.get_ref() as WhaleDialogueTrigger
	if next.activation==0 and not host.player.is_on_floor(): return
	pending=null
	play(next)

func nearby() -> WhaleDialogueTrigger:
	if not available() or not active.is_empty() or not safe_to_talk(): return null
	for trigger: WhaleDialogueTrigger in triggers():
		if trigger.activation==1 and trigger.contains(host.player): return trigger
	return null

func try_interact() -> bool:
	var trigger: WhaleDialogueTrigger = nearby()
	return play(trigger) if trigger!=null else false

func play(trigger: WhaleDialogueTrigger) -> bool:
	if trigger==null or not available() or not safe_to_talk() or not active.is_empty() or not trigger.eligible(host,seen): return false
	var spec: Dictionary = trigger.specification()
	if trigger.activation==2:
		subtitle_left=float(spec.seconds)
		subtitle_room=str(spec.room)
		subtitle_player=weakref(host.player)
		subtitle_changed.emit("\n".join(spec.lines))
		_commit(spec,false)
		return true
	if not host.player.is_on_floor(): return false
	active=spec
	cursor=0
	started.emit(active)
	_emit_line()
	host.record_event("dialogue_started",{"id":spec.id})
	return true

func _emit_line() -> void:
	var speakers: PackedStringArray = active.speakers
	line_changed.emit(speakers[mini(cursor,speakers.size()-1)] if not speakers.is_empty() else "",active.lines[cursor])

func play_script(id: String, lines: Array) -> bool:
	if lines.is_empty() or not available() or not safe_to_talk() or not active.is_empty() or not host.player.is_on_floor(): return false
	var speakers: PackedStringArray=[]
	var texts: PackedStringArray=[]
	for line: Array in lines:
		if line.size()!=2: return false
		speakers.append(str(line[0]))
		texts.append(str(line[1]))
	active={"id":id,"room":str(host.room.id),"lines":texts,"speakers":speakers,"objective_id":"","objective":""}
	cursor=0
	started.emit(active)
	_emit_line()
	host.record_event("dialogue_started",{"id":id})
	return true

func advance() -> void:
	if active.is_empty(): return
	cursor+=1
	if cursor>=active.lines.size(): finish(false)
	else: _emit_line()

func finish(skipped: bool = false) -> void:
	if active.is_empty(): return
	var spec: Dictionary = active
	active={}
	_commit(spec,skipped)
	ended.emit()

func _commit(spec: Dictionary, skipped: bool) -> void:
	var first_completion: bool = not seen.get(str(spec.id),false)
	seen[str(spec.id)]=true
	# 重读旧内容不回退已经推进的目标。
	if first_completion and not str(spec.objective_id).is_empty(): objective={"id":spec.objective_id,"text":spec.objective,"room":spec.room}
	host.record_event("dialogue_finished",{"id":spec.id,"skipped":skipped})
	committed.emit(str(spec.id))
	host.save_progress(false)

func objective_hint() -> String:
	return str(objective.get("text","")) if str(objective.get("room",""))==str(host.room.id) else ""

func to_save() -> Dictionary:
	return {"seen":seen.duplicate(true),"objective":objective.duplicate(true)}

func cancel() -> void:
	if active.is_empty(): return
	active={}
	ended.emit()

func restore(value: Dictionary) -> void:
	# 完成记录与目标一起恢复；不保存半句游标，未完成对话在重试后可重新触发。
	active={}
	pending=null
	subtitle_left=0.0
	subtitle_changed.emit("")
	seen=value.get("seen",{}).duplicate(true)
	objective=value.get("objective",{}).duplicate(true)
