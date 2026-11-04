class_name StoryFlow
extends RefCounted
## Chapter one facts advance through observable actions and completed conversations.

var host: Node2D
var encounter_started: bool = false
var encounter_time: float = 0.0
var save_retry_left: float = 0.0
var whale_left: float = 0.0
var completion_shown: bool = false

func reset() -> void:
	encounter_started = false
	encounter_time = 0.0
	completion_shown = host.progress.has_flag("c01.completed")
	whale_left = 2.0

func tick(delta: float) -> void:
	if host.player.health <= 0: return
	save_retry_left = maxf(0.0, save_retry_left-delta)
	whale_left -= delta
	if host.progress.has_flag("c01.met_mender") and not host.progress.has_flag("c01.route_known") and whale_left<=0:
		whale_left = 18.0
		host.audio.cue("whale")
	if host.progress.has_flag("c01.met_mender") and not host.progress.has_flag("c01.foragers_retreated"):
		if not encounter_started and host.player.position.x >= host.mark("EncounterStart").x:
			encounter_started = true
			host.foragers[0].engage()
			host.record("encounter_started")
		if encounter_started:
			encounter_time += delta
			if encounter_time > 1.4 and host.player.position.x > 1330:
				host.foragers[1].engage()
			if host.foragers.all(func(enemy: StoryForager) -> bool: return enemy.state == "settled") and save_retry_left<=0:
				if commit("c01.foragers_retreated"):
					host.ui.show_notice("食腐甲退回聚食处。补巢者提着菌灯向内侧走去。")
				else: save_retry_left = 3.0
	if host.progress.has_flag("c01.foragers_retreated"):
		_move_mender(delta)
	if host.player.position.x >= host.mark("Exit").x and host.progress.has_flag("c01.route_known") and not completion_shown:
		if save_retry_left<=0:
			if commit("c01.completed"):
				completion_shown = true
				host.ui.show_complete()
			else: save_retry_left = 3.0

func _move_mender(delta: float) -> void:
	var target: Vector2 = host.mark("MenderEnd")
	if host.mender.position.distance_to(target) > 2:
		host.mender.position = host.mender.position.move_toward(target, 135.0*delta)
		host.mender.set_action(&"walk")
		host.mender.set_facing(1.0)
		# The authored low maintenance opening is behind the central support.
		host.mender.z_index = -3 if host.mender.position.x > 1390 and host.mender.position.x < 1750 else 5
	else:
		host.mender.set_action(&"idle")
		host.mender.z_index = 5

func interact() -> void:
	if host.ui.modal_open or host.player.health<=0: return
	if host.player.position.distance_to(host.mender.position)<135:
		var id: String = "intro"
		var lines: Array[String] = StoryText.INTRO
		if host.progress.has_flag("c01.route_known"):
			id = "again"; lines = StoryText.AGAIN
		elif host.progress.has_flag("c01.foragers_retreated"):
			if host.mender.position.distance_to(host.mark("MenderEnd"))>10:
				host.ui.show_notice("补巢者正沿维护窄缝向内侧走去，跟上菌灯。")
				return
			id = "route"; lines = StoryText.ROUTE
		elif host.progress.has_flag("c01.met_mender"):
			id = "wait"; lines = StoryText.WAIT
		host.player.skill_controller.cancel()
		host.player._enter("idle", 0.0)
		host.mender.set_action(&"talk", true)
		host.audio.cue("resonance")
		host.ui.show_dialogue(id, lines)
	elif host.player.position.distance_to(host.mark("Camp"))<110:
		host.player.health = host.player.max_health
		host.player.soul = host.player.max_soul
		host.player.stats_changed.emit(host.player.health, host.player.soul)
		host.audio.cue("save")
		host.ui.show_notice("在安全台歇息。章节事件会在完成时保存。")
	elif host.player.position.distance_to(host.mark("Exit"))<170:
		host.ui.show_notice("先与补巢者确认折井的方向。")

func dialogue_finished(id: String) -> void:
	if id == "intro":
		if commit("c01.met_mender"):
			whale_left = 0.0
			host.ui.show_notice("须板深处传来断续的低鸣。")
	elif id == "route": commit("c01.route_known")
	host.mender.set_action(&"idle" if host.progress.has_flag("c01.foragers_retreated") else &"mend")

func commit(id: String) -> bool:
	if host.progress.advance(id) != OK:
		host.ui.show_notice(host.progress.last_message)
		host.record("save_failed", {"stage":id})
		return false
	host.record("stage_saved", {"stage":id})
	return true

func hint() -> String:
	if host.player.position.distance_to(host.mender.position)<135: return "E  共鸣 · 补巢者"
	if host.player.position.distance_to(host.mark("Camp"))<110: return "E  歇息 · 安全台"
	if host.player.position.x>=host.mark("Exit").x-170 and not host.progress.has_flag("c01.route_known"):
		return "先完成内侧指路，再沿支架前往折井"
	return "A / D 移动 · Space 跳跃 · J 短击 · Esc 暂停"
