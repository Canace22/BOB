class_name Chapter01Explorer
extends CharacterBody2D
## 只处理探索移动，完全不接战斗、营地或存档模块。

const RUN: SpriteFrames = preload("res://art/whalebelly/runtime/tide-picker-run-v03/run.tres")
const IDLE: Texture2D = preload("res://art/whalebelly/animations/player/body/idle/000.png")
var frozen := false
var facing := 1.0
var jump_held := false
var visual: Node2D
var running: AnimatedSprite2D
var idle: Sprite2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 30.0
	floor_max_angle = deg_to_rad(52)
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15.0
	capsule.height = 76.0
	var shape := CollisionShape2D.new()
	shape.position.y = -38
	shape.shape = capsule
	add_child(shape)
	visual = Node2D.new()
	add_child(visual)
	idle = Sprite2D.new()
	idle.texture = IDLE
	idle.centered = false
	idle.offset = Vector2(-308, -414)
	idle.scale = Vector2.ONE * 0.33
	visual.add_child(idle)
	running = AnimatedSprite2D.new()
	running.sprite_frames = RUN
	running.centered = false
	running.offset = Vector2(-128, -300)
	running.scale = Vector2.ONE * (90.0 / 266.0)
	running.play(&"run")
	visual.add_child(running)
	set_visual(false)


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		set_visual(false)
		return
	var axis := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
	axis -= float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	velocity.x = move_toward(velocity.x, axis * 350.0, delta * 2000.0)
	velocity.y += 1450.0 * delta
	var jump := Input.is_physical_key_pressed(KEY_SPACE)
	if jump and not jump_held and is_on_floor():
		velocity.y = -570.0
	jump_held = jump
	if absf(axis) > 0.01:
		facing = signf(axis)
	visual.scale.x = facing
	move_and_slide()
	set_visual(absf(velocity.x) > 15 and is_on_floor())


func set_visual(moving: bool) -> void:
	running.visible = moving
	idle.visible = not moving
	if moving:
		running.play(&"run")
	else:
		running.pause()
