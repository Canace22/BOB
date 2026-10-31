class_name EnvironmentSoftLight
extends Sprite2D
## Independent painted light volume. It never samples the scene/background.
@export var external_clock: bool = false
@export var period: float = 12.0
@export var phase: float = 0.0
@export_range(0.0,1.0) var intensity: float = 0.12
var time: float = 0.0
func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader=load("res://src/world/scenery/local_environment/elements/soft_underwater_light.gdshader")
	material=mat
	mat.set_shader_parameter("period",period)
	mat.set_shader_parameter("phase",phase)
	mat.set_shader_parameter("strength",intensity)
	update_at(0.0)
func _process(delta: float) -> void:
	if not external_clock:update_at(time+delta)
func update_at(t: float, _camera_offset: Vector2=Vector2.ZERO) -> void:
	time=t
	material.set_shader_parameter("clock",t)
