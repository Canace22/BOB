class_name CampaignCinematic
extends Node
## 过场唯一生命周期：冻结世界 → 播放只读演出 → 松键恢复 → 交还原剧情提交口。
const DATA: String="res://content/narrative/campaign_cinematics.json"
var story: CampaignStory
var plans: Dictionary={}
var active: bool=false
var view: CampaignCinematicView
var key: String=""
var shots: Array=[]
var cursor: int=0
var clock: float=0.0
var age: float=0.0
var returning: float=-1.0
var skip_armed: bool=false
var finished_playback: bool=false
var waiting_release: bool=false
var previous_pause: bool=false
var previous_controls: bool=false
var previous_hud: bool=false
var callback: Callable
var session_seen: Dictionary={}
var frozen_modes: Array[Dictionary]=[]
var pending_id: String=""
var pending_done: Callable

func setup(value: CampaignStory) -> void:
	story=value
	process_mode=Node.PROCESS_MODE_ALWAYS
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if parsed is Dictionary: plans=parsed.get("plans",{})

func play(id: String, done: Callable) -> bool:
	if not plans.has(id) or session_seen.has(id): return false
	var host: WhalebellyMain=story.host
	if active: return key==id
	# 踩进触发点时仍在收招，先等安全时机；不能因此退回纯对白而漏掉整段过场。
	if not host.dialogue.available() or not host.dialogue.safe_to_talk():
		pending_id=id
		pending_done=done
		return true
	var spec: Dictionary=plans[id]
	shots=spec.get("shots",[])
	if shots.is_empty(): return false
	key=id
	callback=done
	active=true
	cursor=0
	clock=0
	age=0
	returning=-1
	finished_playback=false
	waiting_release=false
	skip_armed=false
	previous_pause=get_tree().paused
	previous_controls=host.player.controls_enabled
	previous_hud=host.player_ui.hud.visible
	host.player.clear_combat_input()
	host.player.skill_controller.cancel()
	host.player.velocity=Vector2.ZERO
	host.player.controls_enabled=false
	host.player_ui.hud.hide()
	# 主控为菜单使用ALWAYS，ActorFrame会继承它；仅暂停SceneTree不足以停止其视觉脚本。
	for node: Node in [host.actor_frame,host.streaming,host.streaming.corridors,host.camera]:
		frozen_modes.append({"node":node,"mode":node.process_mode})
		node.process_mode=Node.PROCESS_MODE_PAUSABLE
	if is_instance_valid(story.view.marker_layer): story.view.marker_layer.hide()
	get_tree().paused=true
	view=CampaignCinematicView.new()
	add_child(view)
	view.setup(self)
	view.begin_shot(shots[0])
	host.record_event("cinematic_started",{"id":key})
	return true

func _process(dt: float) -> void:
	if not pending_id.is_empty() and not active:
		if not story.running() or story.host.quitting or story.host.player.health<=0:
			cancel()
		elif story.host.dialogue.available() and story.host.dialogue.safe_to_talk():
			var id: String=pending_id
			var done: Callable=pending_done
			pending_id=""
			pending_done=Callable()
			play(id,done)
	if not active: return
	var host: WhalebellyMain=story.host
	if host.quitting or not story.running() or not is_instance_valid(host.player) or host.player.health<=0:
		cancel()
		return
	age+=dt
	if waiting_release:
		view.hint.text="松开移动或技能按键，继续游戏"
		if not _held(): _finish()
		return
	if Input.is_key_pressed(KEY_TAB): return
	if returning>=0:
		returning=minf(1.0,returning+dt/0.65)
		view.return_camera(returning)
		if returning>=1: waiting_release=true
		return
	clock+=dt
	var shot: Dictionary=shots[cursor]
	view.advance(shot,clock,float(shot.seconds))
	if clock<float(shot.seconds): return
	clock=0
	cursor+=1
	if cursor>=shots.size():
		finished_playback=true
		view.begin_return()
		returning=0
	else: view.begin_shot(shots[cursor])

func handle_input(event: InputEvent) -> void:
	if not active: return
	if not event is InputEventKey: return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
		if code==KEY_ESCAPE: request_skip()
		elif code==KEY_ENTER and skip_armed: skip()
		elif code==KEY_F and age>0.35: skip()
	# 过场期间输入不能落到暂停、存档、练习或旧房间快捷键。
	get_viewport().set_input_as_handled()

func request_skip() -> void:
	if not active or waiting_release or returning>=0: return
	if skip_armed: skip()
	else:
		skip_armed=true
		view.hint.text="再按 Esc 或 Enter 跳过本段 · 不会代做后续交互"
		view.skip_button.text="确认跳过"

func skip() -> void:
	if not active or returning>=0: return
	finished_playback=true
	view.begin_return()
	returning=0
	story.host.record_event("cinematic_skipped",{"id":key})

func _held() -> bool:
	for action: StringName in InputMap.get_actions():
		if str(action).begins_with("tp_") or str(action).begins_with("wb_") or action in [&"left",&"right",&"jump",&"attack",&"interact",&"float",&"grapple"]:
			if Input.is_action_pressed(action): return true
	return false

func _finish() -> void:
	var done: Callable=callback
	var id: String=key
	session_seen[id]=true
	_cleanup()
	story.host.record_event("cinematic_finished",{"id":id})
	# 剧情仍由原complete/finish_task唯一提交；关闭/换房只清理，绝不调用此回调。
	if done.is_valid(): done.call()

func cancel() -> void:
	pending_id=""
	pending_done=Callable()
	if active: _cleanup()

func _cleanup() -> void:
	active=false
	callback=Callable()
	if is_instance_valid(view): view.release()
	view=null
	for entry: Dictionary in frozen_modes:
		if is_instance_valid(entry.node): entry.node.process_mode=entry.mode
	frozen_modes.clear()
	var host: WhalebellyMain=story.host
	if is_instance_valid(host.player):
		host.player.clear_combat_input()
		host.player.controls_enabled=previous_controls and host.player.health>0
	if is_instance_valid(host.player_ui): host.player_ui.hud.visible=previous_hud
	if is_instance_valid(story.view.marker_layer): story.view.marker_layer.show()
	get_tree().paused=previous_pause
	shots=[]
	key=""

func _exit_tree() -> void:
	cancel()
