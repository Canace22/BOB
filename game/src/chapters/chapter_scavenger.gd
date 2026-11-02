class_name ChapterScavenger
extends ChapterEnemy

var poses: Array[Texture2D] = []
var stride: float = 0.0


func _ready() -> void:
	for index in 8:
		poses.append(load("res://art/chapters/world/scavenger-%d.png" % index) as Texture2D)
	super._ready()
	_update_visual()


func _physics_process(delta: float) -> void:
	var before := position.x
	super._physics_process(delta)
	stride += absf(position.x - before) / 56.0 * 4.0
	_update_visual()


func _update_visual() -> void:
	if poses.is_empty():
		return
	var frame := int(stride) % 4 if absf(velocity.x) > 1 else 0
	match state:
		"tell": frame = 4 if timer < 0.4 else 5
		"active": frame = 6
		"recover", "stagger", "dead": frame = 7
	visual.texture = poses[frame]
	visual.flip_h = facing > 0
	visual.scale = Vector2(0.36, 0.36)
	visual.rotation = 0
	visual.modulate = Color(1.5, 1.3, 1.1) if flash > 0 else Color.WHITE
	warning.hide()
