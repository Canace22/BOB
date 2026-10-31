extends Sprite2D
## Authored RGBA frame atlases. Per-element scene owns FPS and frame count.
@export var external_clock: bool=false
@export var playback_fps: float=12.0
@export var frame_count: int=72
@export var period: float=6.0
@export var phase_offset_frames: int=0
var time: float=0.0
var home: Vector2
func _ready() -> void:
	home=position
	update_at(0.0)
func _process(delta: float) -> void:
	if not external_clock:
		time+=delta
		update_at(time)
func update_at(t: float, _camera_offset: Vector2=Vector2.ZERO) -> void:
	time=t
	frame=(int(floor(fposmod(t*playback_fps,float(frame_count))))+phase_offset_frames)%frame_count
	position=home
