class_name EnemyLabAttackEffects
extends Node2D
## 攻击事件驱动已有位图；固定池复用，伤害仍由敌人原判定执行。
var enemy: EnemyLabEnemy
var clips: Dictionary={}
var particles: Array[Dictionary]=[]
var sound: AudioStreamPlayer
var trail_clock: float=0.0
var bursts: int=0
const DOT: Texture2D=preload("res://art/tide-picker-action36/projectile.png")

func _ready() -> void:
	var material := ShaderMaterial.new()
	material.shader=preload("effect_tint.gdshader")
	for key: String in ["strike1","heavy","dash_slash"]:
		var spec: Dictionary=enemy.player.action_visual.manifest[key].fx
		var texture: Texture2D=load(str(spec.texture))
		var frames: Array[Texture2D]=[]
		for r: Array in spec.frames:
			var frame := AtlasTexture.new()
			frame.atlas=texture
			frame.region=Rect2(r[0],r[1],r[2],r[3])
			frame.filter_clip=true
			frames.append(frame)
		# 出招事件从接触帧播，原图集最前面的空白蓄势帧不能再次延迟特效。
		clips[key]=frames.slice(4,8) if key=="heavy" else (frames.slice(5,9) if key=="dash_slash" else frames.slice(3,7))
		if key=="strike1": clips[key]=[frames[4],frames[4],frames[5],frames[6]]
	for i: int in 24:
		var sprite := Sprite2D.new()
		sprite.material=material
		sprite.top_level=true
		sprite.z_index=6
		add_child(sprite)
		sprite.hide()
		particles.append({"sprite":sprite,"age":1.0,"life":0.3,"velocity":Vector2.ZERO,"scale":Vector2.ONE,"frames":[],"color":Color.WHITE})
	sound=AudioStreamPlayer.new()
	sound.stream=preload("res://art/whalebelly/runtime/audio/strike.wav")
	sound.volume_db=-15.0
	add_child(sound)
	enemy.phase_started.connect(_phase)

func _phase(phase: String) -> void:
	if phase in ["hurt","ended"]:
		for item: Dictionary in particles: (item.sprite as Sprite2D).hide()
		return
	if phase!="active": return
	if str(enemy.profile.id) in ["membrane_hunter","nest_eel","beam_guard","elder_guardian"]:
		if DisplayServer.get_name()!="headless": sound.play()
		return
	bursts+=1
	trail_clock=0.0
	var area: Rect2=enemy.attack_rect()
	var point: Vector2=area.get_center()
	var color: Color=Color("efba6f")
	if enemy.move_key=="flip":
		ground_impact(Vector2(point.x,enemy.global_position.y),area.size.x)
	elif enemy.move_key in ["rush","ambush","press","shell_push"]:
		_emit(clips.dash_slash,point,Vector2(enemy.facing*area.size.x/429.0,area.size.y/218.0),color,0.28)
	elif enemy.move_key!="sweep":
		var height: float=65.0
		_emit(clips.strike1,Vector2(point.x,enemy.global_position.y-height*0.5),Vector2(enemy.facing*area.size.x/280.0,height/130.0),color,0.30)
	if DisplayServer.get_name()!="headless": sound.play()

func ground_impact(point: Vector2, width: float) -> void:
	_emit(clips.heavy,point+Vector2(0,-4),Vector2(width/180.0,0.65),Color("ff8663"),0.38)
	for i: int in 10:
		var direction: float=-1.0 if i%2==0 else 1.0
		_emit([],point+Vector2(0,-5),Vector2(0.10,0.035),Color("cbbf99"),0.38,Vector2(direction*(60+i*13),-50.0-i*4.0))

func _emit(frames: Array, point: Vector2, size: Vector2, color: Color, life: float, velocity: Vector2=Vector2.ZERO) -> void:
	for item: Dictionary in particles:
		var sprite: Sprite2D=item.sprite
		if sprite.visible: continue
		item.age=0.0
		item.life=life
		item.velocity=velocity
		item.scale=size
		item.frames=frames
		item.color=color
		sprite.texture=DOT if frames.is_empty() else frames[0]
		sprite.global_position=point
		sprite.scale=size
		sprite.rotation=velocity.angle() if not velocity.is_zero_approx() else 0.0
		sprite.modulate=color
		sprite.show()
		return

func _physics_process(dt: float) -> void:
	# 与敌人的局部停顿同步，暂停/逐帧由场景树继承。
	if enemy.feedback.stop_left>0.0: return
	if enemy.state=="evade" or (enemy.state=="active" and enemy.move_key in ["rush","ambush","press","shell_push"]):
		trail_clock+=dt
		if trail_clock>=0.055:
			trail_clock=0.0
			_emit([],enemy.global_position+Vector2(-enemy.facing*35.0,-12.0),Vector2(0.16,0.045),Color("b5b798"),0.24,Vector2(-enemy.facing*110.0,-25.0))
	for item: Dictionary in particles:
		var sprite: Sprite2D=item.sprite
		if not sprite.visible: continue
		item.age=float(item.age)+dt
		var t: float=float(item.age)/float(item.life)
		if t>=1.0:
			sprite.hide()
			continue
		var frames: Array=item.frames
		if not frames.is_empty(): sprite.texture=frames[mini(int(t*frames.size()),frames.size()-1)]
		sprite.global_position+=Vector2(item.velocity)*dt
		sprite.modulate.a=1.0-t

func _exit_tree() -> void:
	if is_instance_valid(sound): sound.stop()
