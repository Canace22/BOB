class_name CampaignStreamBackdrop
extends Sprite2D
## 远景只有一个世界相位，换房和卸载不改变器官位置。
func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		(material as ShaderMaterial).set_shader_parameter("camera_world",camera.get_screen_center_position())
