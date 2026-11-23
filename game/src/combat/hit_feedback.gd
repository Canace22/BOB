class_name TideCombatFeedback
extends Node2D
## 共用命中呈现：订阅已结算目标与伤害前的命中框；资源、粒子池和声音均预载。

const DOT: Texture2D = preload("res://art/tide-picker-action36/projectile.png")
const AUDIO_ROOT: String = "res://art/whalebelly/runtime/audio/"
var hits: Array[AudioStream] = []
var swing: AudioStream
var heavy: AudioStream
var actor: TideCombatPlayer
var enabled: bool = true
var audio_enabled: bool = true
var particles: Array[Dictionary] = []
var voices: Array[AudioStreamPlayer] = []
var voice_cursor: int = 0
var event_count: int = 0
var last_point: Vector2 = Vector2.ZERO
var last_grade: int = 0
var batch_frame: int = -1
var batch_stop: float = 0.0
var sound_frame: int = -1

func setup(player: TideCombatPlayer) -> void:
	actor = player
	for file: String in ["hit.wav","hit_2.wav","hit_3.wav"]: hits.append(load(AUDIO_ROOT+file))
	swing = load(AUDIO_ROOT+"strike.wav")
	heavy = load(AUDIO_ROOT+"heavy.wav")
	actor.hit_resolved.connect(_resolved)
	actor.animation_tag.connect(_animation)
	var material := ShaderMaterial.new()
	material.shader = preload("hit_particle.gdshader")
	for i: int in 32:
		var sprite := Sprite2D.new()
		sprite.texture = DOT
		sprite.material = material
		sprite.top_level = true
		sprite.z_index = 5
		add_child(sprite)
		sprite.hide()
		particles.append({"node":sprite,"age":1.0,"life":0.16,"velocity":Vector2.ZERO,"size":Vector2.ONE})
	for i: int in 6:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func _process(dt: float) -> void:
	for item: Dictionary in particles:
		var sprite: Sprite2D = item.node
		if not sprite.visible: continue
		item.age = float(item.age)+dt
		var progress: float = float(item.age)/float(item.life)
		if progress >= 1.0:
			sprite.hide()
			continue
		sprite.global_position += Vector2(item.velocity)*dt
		sprite.scale = Vector2(item.size)*lerpf(1.0,0.35,progress)
		sprite.modulate.a = pow(1.0-progress,1.5)

func _resolved(target: Node, rect: Rect2, key: String, direction: float) -> void:
	if not enabled or not is_instance_valid(target): return
	var origin: Vector2 = rect.get_center()
	var c: TideSkillController = actor.skill_controller
	var grade: int = 1
	if key in ["wb_draw","wb_charge","great_slash","heavy","dive","dash_slash"]: grade = 2
	if c.active and c.data.has("pulses"):
		grade = 2 if c.pulse_index >= c.data.pulses.size()-1 else 0
	if (target.get("data") is Dictionary and not bool(target.data.get("alive",true))) or target.get("health") == 0: grade = 2
	var stop: float = [1.0/60.0,3.0/60.0,4.0/60.0][grade]
	if key in ["strike1","strike2"]:
		stop=maxf(stop,(4.0 if key=="strike1" else 5.0)/60.0)
	var frame: int = Engine.get_physics_frames()
	if frame != batch_frame:
		batch_frame = frame
		batch_stop = 0.0
	batch_stop = maxf(batch_stop,stop)
	# 原伤害路径会在impact之后赋hitstop，统一指定本批最大值，群攻不能按目标数叠加。
	actor.hitstop_duration = batch_stop
	if actor.hitstop <= 0.0: actor.action_visual.update(0.0,0.0)
	if target.has_method("receive_feedback"): target.receive_feedback(stop,direction,float([3.0,6.0,10.0][grade]))
	var toward: float = signf(actor.global_position.x-origin.x)
	if is_zero_approx(toward): toward = -direction
	last_point = Vector2(rect.position.x if toward < 0 else rect.end.x,clampf(actor.global_position.y-46.0,rect.position.y+5.0,rect.end.y-5.0))
	last_grade = grade
	event_count += 1
	_burst(last_point,direction,grade)
	if sound_frame != frame:
		sound_frame = frame
		_play(heavy if grade == 2 else hits[event_count % hits.size()],-12.0 if grade == 0 else -7.0,1.05 if grade == 0 else 1.0)

func _burst(point: Vector2, direction: float, grade: int) -> void:
	var count: int = 4 if grade == 0 else (8 if grade == 2 else 6)
	for i: int in count:
		var item: Dictionary = _available_particle()
		var sprite: Sprite2D = item.node
		item.age = 0.0
		item.life = 0.20 if grade == 2 else 0.14
		var angle: float = -1.1+2.2*float(i)/maxi(1,count-1)
		var velocity: Vector2 = Vector2(direction*cos(angle),sin(angle))*(95.0 if grade == 2 else 65.0)
		item.velocity = Vector2.ZERO if i == 0 else velocity
		item.size = Vector2.ONE*(0.42 if grade == 2 else 0.28) if i == 0 else Vector2(0.16,0.035)
		sprite.global_position = point
		sprite.rotation = 0.0 if i == 0 else velocity.angle()
		sprite.scale = item.size
		sprite.modulate = Color(1.0,0.88,0.55,1.0) if grade == 2 else Color(0.78,0.96,1.0,1.0)
		sprite.show()

func _available_particle() -> Dictionary:
	for item: Dictionary in particles:
		if not (item.node as Sprite2D).visible: return item
	var oldest: Dictionary = particles[0]
	for item: Dictionary in particles:
		if float(item.age) > float(oldest.age): oldest = item
	return oldest

func _animation(tag: String) -> void:
	if not enabled or not tag.ends_with(":start"): return
	if tag.trim_suffix(":start") in ["strike_01","heavy","A4_parry"]: _play(swing,-17.0,1.0)

func _play(stream: AudioStream, volume: float, pitch: float) -> void:
	if not audio_enabled: return
	var voice: AudioStreamPlayer = voices[voice_cursor % voices.size()]
	voice_cursor += 1
	voice.stop()
	voice.stream = stream
	voice.volume_db = volume
	voice.pitch_scale = pitch
	# 无界面回归只验证路由与资源，不启动实时混音线程；否则高速固定帧退出会残留异步播放引用。
	if DisplayServer.get_name() != "headless": voice.play()

func clear() -> void:
	for item: Dictionary in particles: (item.node as Sprite2D).hide()
	for voice: AudioStreamPlayer in voices:
		if is_instance_valid(voice): voice.stop()
	batch_frame = -1
	batch_stop = 0.0
	sound_frame = -1
	actor.hitstop_duration = 3.0/60.0
	for target: Node in actor.get_tree().get_nodes_in_group("tide_targets"):
		if target.has_method("clear_feedback"): target.clear_feedback()

func toggle() -> void:
	enabled = not enabled
	clear()

func toggle_audio() -> void:
	audio_enabled = not audio_enabled
	if not audio_enabled:
		for voice: AudioStreamPlayer in voices:
			if is_instance_valid(voice): voice.stop()

func _exit_tree() -> void:
	for voice: AudioStreamPlayer in voices:
		if not is_instance_valid(voice): continue
		voice.stop()
		voice.stream = null
	hits.clear()
	swing = null
	heavy = null
