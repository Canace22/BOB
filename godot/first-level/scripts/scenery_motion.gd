@tool
extends Node2D
## Independent decorative transforms. No collision nodes inherit this script.
@export var sway: float = 0.0
@export var speed: float = 0.7
@export var phase: float = 0.0
@export var drift: Vector2 = Vector2.ZERO
@export var parallax: Vector2 = Vector2.ONE
@export var reference_center: Vector2 = Vector2.ZERO
@export var fade_near_player: bool = false
var origin: Vector2
var elapsed: float = 0.0
var level: Node2D

func _ready() -> void:
	origin=position
	if Engine.is_editor_hint(): set_process(false)

func bind(owner_level: Node2D) -> void:
	level=owner_level

func _process(delta: float) -> void:
	elapsed+=delta
	rotation=sin(elapsed*speed+phase)*sway
	if material is ShaderMaterial:
		material.set_shader_parameter("wind_time",elapsed)
	position=origin+Vector2(sin(elapsed*speed+phase)*drift.x,cos(elapsed*speed*0.7+phase)*drift.y)
	if is_instance_valid(level) and is_instance_valid(level.camera):
		position+=(level.camera.get_screen_center_position()-reference_center)*(Vector2.ONE-parallax)
	if fade_near_player and is_instance_valid(level):
		var obscured=false
		for child in get_children():
			if level.player.visible and child is Sprite2D and child.get_rect().has_point(child.to_local(level.player.global_position-Vector2(0,30))): obscured=true
		modulate.a=move_toward(modulate.a,0.22 if obscured else 1.0,delta*3)

func get_effect_state() -> Dictionary:
	return {"layer":"far","seconds":elapsed,"scroll_scale":[parallax.x,parallax.y],"texture_loaded":true}
