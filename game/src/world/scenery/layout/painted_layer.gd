class_name XumenPaintedLayer
extends Node2D
## Limited camera response keeps native cutouts and their moving roots registered.
@export var room_center := Vector2.ZERO
@export var response: float = 0.025
@export var limit := Vector2(8, 5)

func offset_for(center: Vector2) -> Vector2:
	return ((center-room_center)*response).clamp(-limit,limit)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null: position = offset_for(get_parent().to_local(camera.get_screen_center_position()))
