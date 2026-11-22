extends SceneTree
## 原生GPU manual animation fixture：只验证真实metadata/phase/双向pivot，不是键盘战斗或伤害验收。
const DEFAULT_OUT: String="res://build/qa/player-animation-v2/"
const KEYS: Array[String]=["strike1","strike2","upper","heavy","orb","up_spell","great_slash","cyclone","dive","parry","abyss_scream","interact"]
var output: String=DEFAULT_OUT
var fps: int=60
var failures: int=0
var phases:=TideVisualPhaseMap.new()
var builder:=TideActionVisual.new()
var layout: PlayerAnimationV2QALayout
var report: Array[Dictionary]=[]
var tuning: TidePlayer

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("MANUAL PLAYER ANIMATION QA requires a native GPU renderer; headless is not visual proof")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
		if arg.begins_with("--fps="): fps=clampi(int(arg.trim_prefix("--fps=")),10,120)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720)
	DisplayServer.window_set_title("BOB MANUAL animation fixture - player V2")
	RenderingServer.set_default_clear_color(Color("253944"))
	layout=PlayerAnimationV2QALayout.new()
	root.add_child(layout)
	layout.setup()
	var old: Dictionary=TideVisualPhaseMap.read_json("res://art/tide-picker-action36/animations.json").actions
	var current: Dictionary=phases.load_manifest("res://art/tide-picker-action36/")
	tuning=load("res://content/whalebelly/CampaignPlayer.tscn").instantiate()
	for key: String in KEYS: await capture(key,key,old[key],current[key],false)
	for key: String in ["great_slash","cyclone"]: await capture(key+"-long-charge",key,old[key],current[key],true)
	var file:=FileAccess.open(output.path_join("frames.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"manual_animation_fixture_body_only","runtime_metadata":TideVisualPhaseMap.ROOT,
		"native_renderer":RenderingServer.get_current_rendering_method(),"fps":fps,"failures":failures,
		"scope":"12 authored actions, two directions, actual-scale and x2, long-charge and landing; no real input/combat proof",
		"cases":report},"\t"))
	tuning.free()
	builder.free()
	print("PLAYER_ANIMATION_MANUAL_QA cases=",report.size()," failures=",failures," out=",output)
	quit(1 if failures else 0)

func definition(key: String) -> Dictionary:
	var data: Dictionary=TideSkillCatalog.definition(key)
	if not data.is_empty():
		if key=="parry": data.merge({"release":0.02,"duration":0.70,"parry_end":0.55},true)
		if key=="dive": data.merge({"duration":0.84,"landed_at":0.60},true)
		return data
	var duration: float={"strike1":3.0/tuning.animation_fps+tuning.attack_recovery,"heavy":0.55,"orb":0.50,"interact":0.50}.get(key,0.5)
	var release: float={"strike1":tuning.melee_startup,"heavy":0.25,"orb":1.0/6.0,"interact":duration}.get(key,0.1)
	return {"duration":duration,"release":release}

func capture(name: String, key: String, old: Dictionary, current: Dictionary, charge: bool) -> void:
	var data: Dictionary=definition(key)
	var duration: float=float(data.duration)+(0.8 if charge else 0.0)
	var times: Array[float]=[]
	for i: int in int(ceil(duration*fps))+1: times.append(minf(float(i)/fps,duration))
	times.append(float(data.release)+(0.8 if charge else 0.0))
	if data.has("landed_at"): times.append(float(data.landed_at))
	if charge: times.append(0.8)
	times.sort()
	var unique: Array[float]=[]
	for time: float in times:
		if unique.is_empty() or absf(unique.back()-time)>0.000001: unique.append(time)
	var old_frames: Array[Texture2D]=builder.make_frames(old.body)
	var new_frames: Array[Texture2D]=builder.make_frames(current.body)
	var entries: Array[Dictionary]=[]
	var folder: String=output.path_join(name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for i: int in unique.size():
		var before: int=Time.get_ticks_usec()
		var time: float=unique[i]
		var held: bool=charge and time<0.8
		var elapsed: float=maxf(0.0,time-(0.8 if charge else 0.0))
		var context: Dictionary={"active":not held,"visual_key":key,"elapsed":elapsed,"duration":float(data.duration),
			"release":float(data.release),"parry_end":float(data.get("parry_end",0.0)),"clock":time,
			"long_hold":0.25+time,"full_timeline":true,"landed_at":float(data.get("landed_at",0.0)),
			"landed":data.has("landed_at") and elapsed>=float(data.get("landed_at",0.0))}
		var fraction: float=source_fraction(key,old,context,held)
		var old_index: int=clampi(int(fraction*int(old.frame_count)),0,int(old.frame_count)-1)
		var index: int=phases.index_from_context(key,current,fraction,context)
		var stage: String=stage_name(key,context,held)
		var metrics: Dictionary=layout.show_sample(key,old,current,old_frames,new_frames,old_index,index,
			"%s / %s / t=%.3fs / old=%02d new=%02d / pink cross = root"%[name,stage,time,old_index,index])
		if float(metrics.mirror_root_error_pixels)>0.001: failures+=1
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String=folder.path_join("%04d.png"%i)
		var error: Error=root.get_texture().get_image().save_png(path)
		if error!=OK: failures+=1
		entries.append({"png":path,"time_seconds":time,"display_ms":1000.0*(unique[i+1]-time if i+1<unique.size() else 1.0/fps),
			"wall_capture_ms":float(Time.get_ticks_usec()-before)/1000.0,"stage":stage,"old_index":old_index,"new_index":index,
			"context":context,"metrics":metrics,"save_error":error})
	report.append({"name":name,"key":key,"manual_timing":data,"old_texture":old.body.texture,"new_texture":current.body.texture,"frames":entries})

func source_fraction(key: String, spec: Dictionary, context: Dictionary, held: bool) -> float:
	var time: float=float(context.elapsed)
	var duration: float=float(context.duration)
	var release: float=float(context.release)
	var count: float=float(spec.frame_count)
	if held: return minf(float(context.long_hold)*0.2,0.14)/0.5
	if key=="dive":
		if bool(context.landed): return lerpf(0.5,1.0,clampf((time-float(context.landed_at))/(duration-float(context.landed_at)),0.0,1.0))
		return minf(0.5-1.0/count,time/maxf(release,0.01)*(0.5-1.0/count))
	if key=="parry":
		var end: float=float(context.parry_end)
		if time<release: return 2.0/count*time/maxf(release,0.001)
		if time<=end: return 2.0/count
		return lerpf(2.0/count,1.0,clampf((time-end)/(duration-end),0.0,1.0))
	return TideActionVisual.align_event(time/maxf(duration,0.001),release/maxf(duration,0.001),float(spec.get("event_phase",0.5)))

func stage_name(key: String, context: Dictionary, held: bool) -> String:
	if held: return "long-charge"
	if key=="dive": return "land-recover" if bool(context.landed) else ("air-startup" if float(context.elapsed)<float(context.release) else "air-loop")
	if key=="parry" and float(context.elapsed)>=float(context.release) and float(context.elapsed)<=float(context.parry_end): return "guard-hold"
	if float(context.elapsed)<float(context.release): return "startup"
	var after: float=(float(context.elapsed)-float(context.release))/maxf(float(context.duration)-float(context.release),0.001)
	return "release" if after<0.4 else "recover"
