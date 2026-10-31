class_name WorldHazard
extends Node2D

@export var width: float = 128.0
@export var rescue_only: bool = false
var elapsed: float = 0.0


func _physics_process(delta: float) -> void:
	elapsed += delta
	var phase := fmod(elapsed, 5.0)
	var active := phase >= 0.8 and phase < 1.5
	var warning := get_node_or_null("Warning") as Sprite2D
	if warning != null:
		warning.visible = phase < 1.5
		warning.modulate.a = 1.0 if active else 0.5
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.dead:
		return
	var point := player.global_position - global_position
	if point.x < 0 or point.x > width:
		return
	if rescue_only and point.y > 0:
		player.recover_fall()
	elif active and point.y > -70 and point.y < 16:
		if player.hurtbox.receive(HitData.create(1, global_position)):
			player.position = player.last_safe
			player.velocity = Vector2.ZERO
