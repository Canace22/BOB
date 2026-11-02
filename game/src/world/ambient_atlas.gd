class_name AmbientAtlas
extends Sprite2D
## Authored looping frames with a fixed root; inherits pause/hit-stop from the world.

@export_range(1, 60) var fps: float = 12.0
@export var phase_frame: int = 0
var elapsed: float = 0.0


func _ready() -> void:
	_present()


func _process(delta: float) -> void:
	elapsed = fposmod(elapsed + delta, float(hframes * vframes) / fps)
	_present()


func _present() -> void:
	frame = (int(elapsed * fps) + phase_frame) % (hframes * vframes)
