class_name TideVisualPhaseMap
extends RefCounted
## 只读呈现分段：图片进度不反向驱动输入、真实命中或状态时钟。

const ROOT: String = "res://art/combat-animation-v2/player/"
var profiles: Dictionary = {}
var skill_families: Dictionary = {}
var clock: float = 0.0
var last_key: String = ""

func reset() -> void:
	clock = 0.0
	last_key = ""

func load_manifest(base_root: String) -> Dictionary:
	var base: Dictionary = read_json(base_root+"animations.json").get("actions",{})
	var overlay: Dictionary = read_json(ROOT+"animations.json").get("actions",{})
	for key: String in overlay:
		# 元数据按动作合并；保留原有FX、socket和真实释放相位。
		var spec: Dictionary = base.get(key,{}).duplicate(true)
		spec.merge(overlay[key],true)
		base[key] = spec
	var config: Dictionary = read_json(ROOT+"phase-profiles.json")
	profiles = config.get("profiles",{})
	skill_families = config.get("skill_families",{})
	return base

static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("主角呈现配置缺失，保留基础动画："+path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if value is Dictionary: return value
	push_warning("主角呈现配置无效："+path)
	return {}

func body_index(key: String, spec: Dictionary, fraction: float, actor: TidePlayer, dt: float) -> int:
	if key != last_key:
		clock = 0.0
		last_key = key
	else: clock += dt
	var c: TideSkillController = actor.skill_controller
	return index_from_context(key,spec,fraction,{"clock":clock,"active":c.active,"visual_key":c.visual_key,
		"elapsed":c.elapsed,"duration":c.duration,"release":float(c.data.get("release",0.0)),
		"parry_end":float(c.data.get("parry_end",0.0)),"landed":c.landed,"landed_at":c.landed_at,
		"long_hold":c.input.long_hold,"full_timeline":actor.state_duration>0.0})

func index_from_context(key: String, spec: Dictionary, fraction: float, context: Dictionary) -> int:
	## 主角与幻影共用的只读解析口；调用者提供自己的时钟，不能借此驱动另一执行器。
	var count: int = int(spec.frame_count)
	var profile: Dictionary = profiles.get(key,{})
	var active_: bool = bool(context.get("active",false))
	var source_key: String = str(context.get("visual_key",""))
	var time: float = float(context.get("elapsed",0.0))
	var duration: float = float(context.get("duration",0.0))
	var release: float = float(context.get("release",0.0))
	var visual_clock: float = float(context.get("clock",0.0))
	# 长冲未新绘，准备/飞行/退出仍完全由原TideActionPhases排他边界决定。
	if key == "crystal_dash": return clampi(int(fraction*count),0,count-1)
	if str(profile.get("mode","")) == "full_timeline" and bool(context.get("full_timeline",false)):
		# 反解旧的结束事件映射，也保留禁用操作时既有的呈现时钟推进。
		return clampi(int(fraction/maxf(float(spec.get("event_phase",1.0)),0.001)*count),0,count-1)
	if str(profile.get("mode","")) == "dive" and active_:
		# 空中只播起手/下坠；真正落地后才进入落地回收段，绝不提前画出地面冲击。
		var landed_at: float = float(context.get("landed_at",0.0))
		if bool(context.get("landed",false)): return sequence_index(profile.recover,(time-landed_at)/maxf(duration-landed_at,0.001))
		if time < release: return sequence_index(profile.prepare,time/maxf(release,0.001))
		return loop_index(profile.air_loop,visual_clock,float(profile.get("loop_fps",10.0)))
	if str(profile.get("mode","")) == "guard" and active_ and source_key == "parry":
		var end: float = float(context.get("parry_end",0.0))
		if time < release: return sequence_index(profile.prepare,time/maxf(release,0.001))
		if time <= end: return loop_index(profile.hold_loop,visual_clock,float(profile.get("loop_fps",8.0)))
		return sequence_index(profile.recover,(time-end)/maxf(duration-end,0.001))
	if not active_ and source_key == key and profile.has("charge_loop"):
		# 只在输入层已经选择蓄力状态后播放，不预判60ms组合输入。
		return loop_index(profile.charge_loop,visual_clock,float(profile.get("loop_fps",9.0)))
	if profile.has("prepare") and profile.has("release"):
		return phase_index(profile,fraction,float(spec.get("event_phase",0.5)))
	return clampi(int(fraction*count),0,count-1)

static func phase_index(profile: Dictionary, fraction: float, event_phase: float) -> int:
	if fraction < event_phase:
		return sequence_index(profile.prepare,fraction/maxf(event_phase,0.001))
	return sequence_index(profile.release,(fraction-event_phase)/maxf(1.0-event_phase,0.001))

static func sequence_index(frames: Array, progress: float) -> int:
	if frames.is_empty(): return 0
	return int(frames[clampi(int(clampf(progress,0.0,1.0)*frames.size()),0,frames.size()-1)])

static func loop_index(frames: Array, time: float, fps: float) -> int:
	if frames.is_empty(): return 0
	return int(frames[posmod(int(time*fps),frames.size())])

static func attack_fx_visible(actor: TidePlayer, key: String) -> bool:
	var c: TideSkillController = actor.skill_controller
	if c.active: return c.elapsed >= float(c.data.get("release",0.0))
	if c.visual_key in ["great_slash","cyclone","crystal_dash"]: return false
	if key in ["strike1","pogo","heavy","orb"] and actor.state_duration > 0.0:
		return actor.state_time >= actor.action_trigger_time()
	return true
