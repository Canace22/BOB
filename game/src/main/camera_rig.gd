class_name CameraRig
extends Camera2D

@export var player: Player


func reset_for(room: Room) -> void:
	limit_left = -300 if room.room_id == SaveService.START_ROOM else 0
	limit_right = int(room.dimensions.x)
	limit_top = 0
	limit_bottom = int(room.dimensions.y + 30)
	position = player.position + Vector2(player.facing * 145, -200)
	reset_smoothing()


func _process(delta: float) -> void:
	if player == null:
		return
	var focus := player.position + Vector2(player.facing * 145, -200)
	zoom = Vector2.ONE
	if GameState.arena_active:
		zoom = Vector2(0.68, 0.68)
		focus = Vector2(21 * 64, 14 * 64 - 260)
	position = position.lerp(focus, 1.0 - exp(-5 * delta))
