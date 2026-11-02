class_name ChapterResident
extends Sprite2D

var poses: Array[Texture2D] = []
var elapsed: float = 0.0


func _ready() -> void:
	for index in 4:
		poses.append(load("res://art/chapters/world/resident-%d.png" % index) as Texture2D)


func _process(delta: float) -> void:
	elapsed += delta
	texture = poses[int(elapsed / 0.24) % 4]
