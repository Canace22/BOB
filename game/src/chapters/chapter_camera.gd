class_name ChapterCamera
extends CameraRig
## Chapter arena has its own dimensions; never inherit R1's hard-coded focus.


func _process(delta: float) -> void:
	if player == null:
		return
	var focus := player.position + Vector2(player.facing * 115, -190)
	var target_zoom := Vector2.ONE
	if GameState.arena_active:
		focus = Vector2(1170, 550)
		target_zoom = Vector2(0.86, 0.86)
	zoom = zoom.lerp(target_zoom, 1.0 - exp(-4 * delta))
	position = position.lerp(focus, 1.0 - exp(-5 * delta))
