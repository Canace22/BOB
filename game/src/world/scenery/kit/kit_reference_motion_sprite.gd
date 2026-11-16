class_name KitReferenceMotionSprite
extends Sprite2D
## Local painted surface motion. Rigid roots and source alpha remain protected.
@export_enum("membrane", "glow") var motion_kind: String = "membrane"
@export var phase: float = 0.0
@export var amplitude_pixels: float = 4.0
@export var external_clock: bool = true
var elapsed: float = 0.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	var painted:=ShaderMaterial.new()
	painted.shader=load("res://src/world/scenery/kit/reference_surface_motion.gdshader")
	material=painted
	painted.set_shader_parameter("glow_mode",motion_kind=="glow")
	painted.set_shader_parameter("phase",phase)
	painted.set_shader_parameter("amplitude_pixels",amplitude_pixels)
	update_at(0.0)

func _process(delta: float) -> void:
	if not external_clock:update_at(elapsed+delta)

func update_at(time: float) -> void:
	elapsed=time
	material.set_shader_parameter("clock",time)
