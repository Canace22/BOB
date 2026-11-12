class_name KitParallaxLayer
extends Node2D
## Bitmap layer for rooms larger than one screen. factor 0 stays with the
## camera, 1 stays with the world; children are authored around room_center.
@export_range(0.0, 2.0) var factor: float = 0.1
@export var room_center: Vector2 = Vector2.ZERO
@export var vertical: bool = true # false keeps a ground-hugging layer at its authored height

func _process(_dt: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null: position = offset_for(camera.get_screen_center_position())

func offset_for(view_center: Vector2) -> Vector2:
	var offset: Vector2 = (view_center - room_center) * (1.0 - factor)
	return offset if vertical else Vector2(offset.x, 0.0)
