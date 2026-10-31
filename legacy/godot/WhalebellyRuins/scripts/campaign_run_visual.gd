extends Node
## Video-derived run at the requested fixed 12 FPS; physics still owns translation.
const FRAMES: SpriteFrames = preload("res://assets/runtime/tide-picker-run-v03/run.tres")
const PIVOT := Vector2(128,300)
const ART_HEIGHT := 266.0
var actor: CharacterBody2D
var sprite: AnimatedSprite2D
var elapsed := 0.0
var active := false

func setup(player: CharacterBody2D, target_height: float) -> void:
	actor = player
	sprite = AnimatedSprite2D.new()
	sprite.name = "RunAnimation"
	sprite.sprite_frames = FRAMES
	sprite.animation = &"run"
	sprite.centered = false
	sprite.offset = -PIVOT
	# Parent already applies the room-specific scale and facing.
	sprite.scale = Vector2.ONE * target_height / ART_HEIGHT / actor.visual_scale
	sprite.material = actor.body.material.duplicate()
	sprite.material.set_shader_parameter("split_lower",false)
	sprite.material.set_shader_parameter("legs_only",false)
	sprite.visible = false
	actor.get_node("Visual").add_child(sprite)

func update(delta: float, travelled_x: float) -> void:
	var runing: bool = actor.animation_state == "run" and actor.is_on_floor()
	if runing and not active: elapsed = 0.0
	if runing and absf(travelled_x)>0.01:
		elapsed = fposmod(elapsed + delta,7.0)
		sprite.frame = mini(83,int(floor(elapsed*12.0)))
	active = runing
	sprite.visible = runing
	actor.body.visible = not runing
	if runing: actor.get_node("Visual/Legs").visible = false
	sprite.material.set_shader_parameter("flash",actor.body.material.get_shader_parameter("flash"))
