@tool
class_name SceneryMotion
extends Node2D
## Decorative transforms only. Collision belongs to the stationary World layer.

@export var sway: float = 0.0
@export var speed: float = 0.7
@export var phase: float = 0.0
@export var drift: Vector2 = Vector2.ZERO
@export var parallax: Vector2 = Vector2.ONE
@export var reference_center: Vector2 = Vector2.ZERO
@export var fade_near_player: bool = false

var origin: Vector2
var elapsed: float = 0.0


func _ready() -> void:
	origin = position
	set_process(not Engine.is_editor_hint())
	if material is ShaderMaterial:
		material = material.duplicate()


func _process(delta: float) -> void:
	elapsed += delta
	rotation = sin(elapsed * speed + phase) * sway
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("wind_time", elapsed)
	position = origin + Vector2(sin(elapsed * speed + phase) * drift.x, cos(elapsed * speed * 0.7 + phase) * drift.y)
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		position += (camera.get_screen_center_position() - reference_center) * (Vector2.ONE - parallax)
	if fade_near_player:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var obscured := false
		if player != null:
			for child in get_children():
				if child is Sprite2D and (child as Sprite2D).get_rect().has_point((child as Sprite2D).to_local(player.global_position - Vector2(0, 30))):
					obscured = true
		modulate.a = move_toward(modulate.a, 0.22 if obscured else 1.0, delta * 3)
