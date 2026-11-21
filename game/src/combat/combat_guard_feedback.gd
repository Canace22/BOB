class_name TideCombatGuardFeedback
extends Node2D
## 格挡结算后驱动已有位图特效和声音，特效不参与防御判定。
var player: TideCombatPlayer
var age: float=2.0
var perfect: bool=false
var broken: bool=false
var ring: Sprite2D
var audio: AudioStreamPlayer
var message: String=""
var font: Font=preload("res://art/fonts/WhalefallUI.ttf")

func _ready() -> void:
	ring=Sprite2D.new()
	var tex := AtlasTexture.new()
	tex.atlas=preload("res://art/tide-picker-action36/ground-ring-fx.png")
	var frame: Array=player.action_visual.manifest.heavy.fx.frames[4]
	tex.region=Rect2(frame[0],frame[1],frame[2],frame[3])
	ring.texture=tex
	ring.rotation=PI*0.5
	ring.z_index=8
	add_child(ring)
	ring.hide()
	audio=AudioStreamPlayer.new()
	audio.stream=preload("res://art/whalebelly/runtime/audio/hit_3.wav")
	audio.volume_db=-5.0
	add_child(audio)
	player.guard_success.connect(_success)
	player.guard_broken.connect(_broken)

func _broken() -> void:
	age=0.0
	perfect=false
	broken=true
	message="破防！松开 I 恢复架势"
	ring.position=Vector2(player.facing*36.0,-48.0)
	if DisplayServer.get_name()!="headless": audio.play()

func _success(value: bool) -> void:
	perfect=value
	broken=false
	age=0.0
	message="完美格挡！反击 +2" if perfect else "格挡成功！反击 +1"
	ring.position=Vector2(player.facing*36.0,-48.0)
	player.hitstop=maxf(player.hitstop,0.08 if perfect else 0.045)
	if DisplayServer.get_name()!="headless": audio.play()

func _physics_process(dt: float) -> void:
	age+=dt
	ring.visible=age<0.32
	if ring.visible:
		ring.scale=Vector2.ONE*lerpf(0.35,0.8,age/0.32)
		ring.modulate=Color(1.0,0.83,0.35,1.0-age/0.32) if perfect else Color(0.65,0.95,1.0,1.0-age/0.32)
		if broken: ring.modulate=Color(1.0,0.35,0.20,1.0-age/0.32)
	queue_redraw()

func _draw() -> void:
	if age>=1.1: return
	var color := Color("ffe19b") if perfect else Color("a9edff")
	if broken: color=Color("ff8a70")
	color.a=clampf((1.1-age)*3.0,0.0,1.0)
	draw_string(font,Vector2(-95,-108-age*15.0),message,HORIZONTAL_ALIGNMENT_LEFT,-1,22,color)
