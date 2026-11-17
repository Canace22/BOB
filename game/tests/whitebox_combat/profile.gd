extends Node
## GPU环境中的固定回放，分别隔离脚底回读与调试UI，输出壁钟帧耗时。

var arena: Node2D
const OUTPUT: String = "res://build/qa/whitebox-performance/"
var results: Array[Dictionary] = []

func _ready() -> void:
	arena = get_parent()
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for i: int in 30: await get_tree().process_frame
	await sample("baseline-A",false,false)
	await sample("no-foot-readback",true,false)
	await sample("no-debug-ui",false,true)
	await sample("baseline-B",false,false)
	var file := FileAccess.open(OUTPUT+"profile.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	print("WHITEBOX PROFILE: ",JSON.stringify(results))
	get_tree().quit()

func sample(label: String, skip_foot: bool, skip_ui: bool) -> void:
	var view: CombatWhiteboxActionVisual = arena.player.action_visual
	view.profile_skip_foot = skip_foot
	view.foot_reads = 0
	arena.timeline.set_process(not skip_ui)
	arena.timeline.visible = not skip_ui
	arena.hud.visible = not skip_ui
	arena.event_hud.visible = not skip_ui
	# 主场景进程还负责常规调试快照；对照一并关闭，战斗物理仍继续。
	arena.set_process(not skip_ui)
	var frame_ms: Array[float] = []
	var visual_ms: Array[float] = []
	var readback_ms: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	var legacy_before: int = arena.player.profile_legacy_us
	var spikes: Array[Dictionary] = []
	for i: int in 240:
		if i % 40 == 0:
			arena.reset_arena()
			arena.enemy.health = 9999
			var key: String = ["wb_flurry","wb_draw","wb_drive","wb_rise","wb_charge","cyclone"][i/40]
			arena.player.request_action(key)
		if i % 40 == 15: arena.player.try_backstep()
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		frame_ms.append(float(now-previous)/1000.0)
		if float(now-previous)/1000.0 > 25.0:
			spikes.append({"frame":i,"ms":float(now-previous)/1000.0,"clip":view.current_key,"legacy_total_ms":float(arena.player.profile_legacy_us-legacy_before)/1000.0,"visual_ms":float(view.update_us)/1000.0,"readback_ms":float(view.foot_us)/1000.0})
		visual_ms.append(float(view.update_us)/1000.0)
		readback_ms.append(float(view.foot_us)/1000.0)
		previous = now
	var row: Dictionary = {"case":label,"frames":frame_ms.size(),"frame":summary(frame_ms),"visual":summary(visual_ms),"readback":summary(readback_ms),"read_calls":view.foot_reads,"legacy_load_ms":float(arena.player.profile_legacy_us-legacy_before)/1000.0,"warmup_ms":float(view.warmup_us)/1000.0,"spikes":spikes}
	results.append(row)
	print("PROFILE CASE: ",JSON.stringify(row))

func summary(values: Array[float]) -> Dictionary:
	values.sort()
	return {"median_ms":values[values.size()/2],"p95_ms":values[int(values.size()*0.95)],"max_ms":values.back()}
