class_name AmbientSoftLight
extends Sprite2D
## Reuses main's painted light volume; inherits World pause and hit-stop.

@export_range(1.0, 30.0) var period: float = 12.0
@export var phase: float = 0.0
@export_range(0.0, 1.0) var intensity: float = 0.12
var elapsed: float = 0.0


func _ready() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://src/world/ambient_soft_light.gdshader")
	material = shader_material
	_present()


func _process(delta: float) -> void:
	elapsed = fposmod(elapsed + delta, period)
	_present()


func _present() -> void:
	material.set_shader_parameter("phase", elapsed * TAU / period + phase)
	material.set_shader_parameter("strength", intensity)
