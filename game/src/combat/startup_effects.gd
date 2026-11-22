class_name TideStartupEffects
extends Node2D
## 已入库位图的共用起手粒子池；只读取真实技能时钟，不创建攻击或改变角色运动。

const DOT: Texture2D = preload("res://art/tide-picker-action36/projectile.png")
const INSTANT_KEYS: Array[String] = ["A1_dash","A5_slit","shadow_dash","crystal_dash"]
var actor: TideCombatPlayer
var families: Dictionary = {}
var motes: Array[Sprite2D] = []
var visible_key: String = ""
var strength: float = 0.0
var clock: float = 0.0

func setup(player: TideCombatPlayer, configured_families: Dictionary) -> void:
	actor = player
	families = configured_families
	z_index = 6
	var material := ShaderMaterial.new()
	material.shader = preload("hit_particle.gdshader")
	for i: int in 7:
		var mote := Sprite2D.new()
		mote.texture = DOT
		mote.material = material
		add_child(mote)
		mote.hide()
		motes.append(mote)
	actor.animation_tag.connect(_animation)
	actor.damaged.connect(clear)

func _animation(tag: String) -> void:
	if tag in ["hit:start","defeat:start"] or tag.ends_with(":cancel"):
		clear()
	elif tag.ends_with(":start"):
		clock = 0.0

func advance(dt: float) -> void:
	if not is_instance_valid(actor): return
	if actor.health <= 0 or not actor.controls_enabled or not actor.get_node("Visual").visible:
		clear()
		return
	if actor.hitstop > 0.0: return
	clock += dt
	var c: TideSkillController = actor.skill_controller
	var key: String = c.visual_key if c.active else actor.state
	var charging: bool = not c.active and c.visual_key in ["great_slash","cyclone","crystal_dash"]
	if charging: key = c.visual_key
	if not families.has(key) or (not charging and not c.active and actor.state_duration <= 0.0):
		clear()
		return
	var family: String = str(families[key])
	var time: float = c.elapsed if c.active else actor.state_time
	var release: float = float(c.data.get("release",0.0)) if c.active else actor.action_trigger_time()
	if key in INSTANT_KEYS: release = 0.0
	if key in ["recover","interact"]: release = actor.state_duration
	if charging:
		var held: float = c.input.long_hold if key == "crystal_dash" else c.input.attack_hold
		strength = 0.25+0.5*clampf(held/0.6,0.0,1.0)
	elif family == "guard" and c.active and time >= release and time <= float(c.data.get("parry_end",0.0)):
		strength = 0.22
	else:
		# 多段招式在各自真实脉冲前聚拢，首段之后不伪造额外攻击。
		var pulses: Array = c.data.get("pulses",[]) if c.active else []
		strength = startup_strength(time,release,pulses)
	if strength <= 0.0:
		clear()
		return
	visible_key = key
	_draw_family(family,c.locked_facing if c.active else actor.facing)

static func startup_strength(time: float, release: float, pulses: Array) -> float:
	var previous: float = 0.0
	for value: Variant in pulses:
		var next: float = float(value)
		if time < next:
			var start: float = 0.0 if previous == 0.0 else maxf(previous,next-0.10)
			if time < start: return 0.0
			return lerpf(0.18,0.78,clampf((time-start)/maxf(next-start,0.001),0.0,1.0))
		previous = next
	if not pulses.is_empty(): release = float(pulses.back())
	if time < release:
		return lerpf(0.18,0.78,clampf(time/maxf(release,0.001),0.0,1.0))
	# 即时移动只有开始后的短尾迹，不添加防御或位移前摇。
	return 0.7*(1.0-clampf((time-release)/0.08,0.0,1.0))

func _draw_family(family: String, facing: float) -> void:
	var count: int = 3 if family in ["light","guard","interact"] else 7
	var anchor := Vector2(facing*34.0,-58.0)
	if family in ["spell","heal","interact"]: anchor = Vector2(facing*13.0,-53.0)
	var color := Color("b9f1e7")
	if family == "light": color = Color("ffe4a1")
	elif family == "heavy": color = Color("8fdce8")
	elif family == "spell": color = Color("b8c9ff")
	elif family == "heal": color = Color("a9ebbc")
	var unit: float = 1.0/maxf(DOT.get_width(),DOT.get_height())
	for i: int in motes.size():
		var mote: Sprite2D = motes[i]
		mote.visible = i < count
		if not mote.visible: continue
		var angle: float = TAU*float(i)/count+clock*(1.8 if family == "spell" else 0.65)
		var radius: float = lerpf(19.0,4.0,strength)*(0.65 if family == "light" else 1.0)
		mote.position = anchor+Vector2(cos(angle)*facing,sin(angle)*0.65)*radius
		mote.rotation = angle
		# 水丝与聚光是已有位图的程序驱动特效，不登记为新动作帧。
		var size := Vector2(9.0,1.8) if family == "heavy" else Vector2(4.5,4.5)
		if family == "move": size = Vector2(12.0,2.0)
		mote.scale = size*unit*(0.65+strength)
		mote.modulate = Color(color,strength*0.6)

func clear() -> void:
	visible_key = ""
	strength = 0.0
	for mote: Sprite2D in motes: mote.hide()
