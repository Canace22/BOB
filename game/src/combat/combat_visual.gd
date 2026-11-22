class_name TideCombatVisual
extends TideActionVisual
## 共用技法复用已入库逐帧图集；只编排画面，不改判定、位移或取消窗口。

const SKILL_CLIPS: Dictionary = {"wb_rise":"upper","wb_draw":"great_slash","wb_backcut":"strike2"}
const FLURRY_KEYS: Array[String] = ["strike1","strike2","strike1","strike2","great_slash"]
const FLURRY_EDGES: Array[float] = [0.0,0.17,0.31,0.45,0.59,0.94]
const FLURRY_HITS: Array[float] = [0.10,0.24,0.38,0.52,0.66]
var previous_position: Vector2 = Vector2.ZERO
var ready_position: bool = false
var last_attack_id: int = -1
var last_proxy_start: float = -1.0
var foot_metadata: Dictionary = {}
var pinned_clips: Dictionary = {}
var profile_skip_foot: bool = false
var update_us: int = 0
var foot_us: int = 0
var foot_reads: int = 0
var warmup_us: int = 0
var guard_ring: Sprite2D
var startup_effects: TideStartupEffects
const WARM_KEYS: Array[String] = ["idle","run","walk","jump","dash","strike1","strike2","upper","great_slash","dash_slash","parry","hurt","defeat","heavy","heal","orb","cyclone"]

func setup(player: TidePlayer, height: float) -> void:
	var started: int = Time.get_ticks_usec()
	super.setup(player,height)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://src/combat/foot_offsets.json"))
	if parsed is Dictionary: foot_metadata = parsed.get("actions",{})
	# 在试玩开始前准备有限动作集，避免首次出招时同步加载与8项LRU反复淘汰。
	for key: String in WARM_KEYS:
		if bool(available.get(key,false)): load_clip(key)
	# 复用已入库潮环位图，竖置于持叉前方；只表达格挡，不提供额外防御。
	guard_ring = Sprite2D.new()
	var ring := AtlasTexture.new()
	ring.atlas = load("res://art/tide-picker-action36/ground-ring-fx.png")
	var region: Array = manifest.heavy.fx.frames[4]
	ring.region = Rect2(region[0],region[1],region[2],region[3])
	ring.filter_clip = true
	guard_ring.texture = ring
	guard_ring.rotation = PI*0.5
	guard_ring.scale = Vector2(0.30,0.30)
	guard_ring.material = additive_material
	actor.add_child(guard_ring)
	guard_ring.hide()
	startup_effects = TideStartupEffects.new()
	actor.add_child(startup_effects)
	startup_effects.setup(actor,phase_map.skill_families)
	warmup_us = Time.get_ticks_usec()-started

func load_clip(key: String) -> Dictionary:
	if not pinned_clips.has(key): pinned_clips[key] = super.load_clip(key)
	return pinned_clips[key]

func _physics_process(dt: float) -> void:
	if not is_instance_valid(actor): return
	if not ready_position:
		previous_position = actor.global_position
		ready_position = true
	var travel: float = actor.global_position.x-previous_position.x
	previous_position = actor.global_position
	# 后跳分支不经过主角色的动画更新，也在此统一保持朝向与等比尺寸。
	actor.get_node("Visual").scale = Vector2(actor.visual_scale*actor.facing,actor.visual_scale)
	var c: TideSkillController = actor.skill_controller
	if c.active and c.attack_id != last_attack_id:
		current_key = ""
		last_attack_id = c.attack_id
	elif not c.active and actor.state_time < last_proxy_start:
		current_key = ""
	last_proxy_start = actor.state_time
	foot_us = 0
	var started: int = Time.get_ticks_usec()
	update(dt,travel)
	_update_guard()
	startup_effects.advance(dt)
	update_us = Time.get_ticks_usec()-started

func _update_guard() -> void:
	var c: TideSkillController = actor.skill_controller
	guard_ring.visible = c.active and c.visual_key == "parry" and actor.health > 0
	if not guard_ring.visible: return
	var start: float = float(c.data.release)
	var end: float = float(c.data.parry_end)
	var strength: float = clampf(c.elapsed/maxf(start,0.001),0.0,1.0)
	if c.elapsed > end:
		strength *= 1.0-clampf((c.elapsed-end)/maxf(c.duration-end,0.001),0.0,1.0)
	guard_ring.position = Vector2(c.locked_facing*44.0,-58.0)
	guard_ring.modulate = Color(1.0,0.90,0.60,strength) if c.parried else Color(0.65,0.95,1.0,strength*0.65)
	guard_ring.scale = Vector2.ONE*(0.36 if c.parried else 0.30)

func choose_key(dt: float) -> String:
	var base: String = super.choose_key(dt)
	var c := actor.skill_controller as TideCombatSkills
	if c.active:
		if SKILL_CLIPS.has(c.visual_key): return str(SKILL_CLIPS[c.visual_key])
		if c.visual_key == "wb_drive": return ["strike1","strike2","dash_slash"][clampi(c.drive_step-1,0,2)]
		if c.visual_key == "wb_charge": return "dash" if actor.state_time < float(c.data.release)*0.6 else "upper"
		if c.visual_key == "wb_flurry": return FLURRY_KEYS[flurry_segment(actor.state_time)]
	if bool(actor.get("retreating")): return "jump"
	return base

static func flurry_segment(time: float) -> int:
	for i: int in 5:
		if time < FLURRY_EDGES[i+1]: return i
	return 4

func frame_fraction(key: String, spec: Dictionary, dt: float, travel: float) -> float:
	var c := actor.skill_controller as TideCombatSkills
	if c.active and c.visual_key == "parry" and key == "parry":
		# 第2帧是原画的抬叉接触帧：前摇快速到位，整个有效窗保持，后摇再收叉。
		var contact: float = 2.0/float(spec.frame_count)
		var start: float = float(c.data.release)
		var end: float = float(c.data.parry_end)
		if c.elapsed < start: return contact*clampf(c.elapsed/maxf(start,0.001),0.0,1.0)
		if c.elapsed <= end: return contact
		return lerpf(contact,1.0,clampf((c.elapsed-end)/maxf(c.duration-end,0.001),0.0,1.0))
	if c.active and TideCombatSkills.DEFINITIONS.has(c.visual_key):
		var time: float = actor.state_time
		var span: float = c.duration
		var hit: float = float(c.data.release)
		if c.visual_key == "wb_flurry":
			var i: int = flurry_segment(time)
			time -= FLURRY_EDGES[i]
			span = FLURRY_EDGES[i+1]-FLURRY_EDGES[i]
			hit = FLURRY_HITS[i]-FLURRY_EDGES[i]
		elif c.visual_key == "wb_charge":
			var split: float = float(c.data.release)*0.6
			if key == "dash": return clampf(time/split,0.0,1.0)
			time -= split
			span -= split
			hit -= split
		# 直接以真实命中时间对齐图集event_phase，不让整段源视频拖慢出招。
		return align_event(time/maxf(span,0.001),hit/maxf(span,0.001),float(spec.get("event_phase",0.5)))
	if bool(actor.get("retreating")):
		return clampf(float(actor.get("retreat_time"))/0.30,0.0,1.0)
	return super.frame_fraction(key,spec,dt,travel)

func apply_layer(layer: Sprite2D, frames: Array[Texture2D], spec: Dictionary, index: int, height: float) -> void:
	var c: TideSkillController=actor.skill_controller
	if layer==effect and c.active and c.visual_key=="strike1":
		# 原弧光第4帧是接触峰值；独立从释放计时，避免整体进度映射在60Hz跳过峰值。
		index=4+int(maxf(0.0,c.elapsed-float(c.data.release))*24.0)
	super.apply_layer(layer,frames,spec,index,height)
	if layer != sprite or layer.texture == null or not actor.is_on_floor(): return
	if bool(manifest.get(current_key,{}).get("authored_pivot",false)): return
	if profile_skip_foot: return
	# 脚底元数据从PNG离线生成；战斗中禁止get_image触发GPU同步回读。
	var values: Array = foot_metadata.get(current_key,{}).get("bottom",[])
	if not values.is_empty(): layer.offset.y = -float(values[mini(index,values.size()-1)])
