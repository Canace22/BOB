class_name XumenContinuousDepth
extends Sprite2D
## One anatomical panorama, translated along the designed mouth-to-throat axis.
@export var depth_offset: Vector2 = Vector2(-16,-16)
var base_position: Vector2
var elapsed: float = 0.0
var host: Node2D

func _ready() -> void:
	base_position=position
	process_mode=Node.PROCESS_MODE_PAUSABLE

func _process(dt:float) -> void:
	if is_instance_valid(host):
		visible=not host.reference_visible and host.layer_solo<0 and host.capture_path.is_empty()
		if not visible:return
		var shift:Vector2=(host.camera.position-host.point(host.room.size)*.5)*.006
		position=base_position+shift.clamp(Vector2(-6,-4),Vector2(6,4))
	elapsed+=dt
	(material as ShaderMaterial).set_shader_parameter("clock",elapsed)
