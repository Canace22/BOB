class_name XumenBackgroundCurrent
extends Node2D
## Only registered distant paintings receive animated exposure; no screen effects.
var elapsed: float = 0.0
var materials: Array[ShaderMaterial] = []

func _ready() -> void:
	for path: String in ["Far/Depth/Paint","Far/Depth/OriginalFar","Far/Depth/OriginalOralFar"]:
		var sprite: Sprite2D = get_parent().get_node_or_null(path) as Sprite2D
		if sprite!=null and sprite.material is ShaderMaterial:
			var surface: ShaderMaterial = sprite.material
			if float(surface.get_shader_parameter("water_strength"))>0.0: materials.append(surface)
	update_at(0.0)

func update_at(time: float) -> void:
	elapsed=time
	for surface: ShaderMaterial in materials: surface.set_shader_parameter("clock",time)
