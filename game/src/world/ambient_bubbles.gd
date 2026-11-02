class_name AmbientBubbles
extends Node2D
## Painted bubbles from main, with arena-local bounds and no collision.

@export var bounds: Rect2 = Rect2(0, 0, 230, 240)
@export_range(1, 12) var population: int = 5
@export var seed_id: int = 0
@export var base_speed: float = 12.0
@export_range(0.0, 1.0) var opacity: float = 0.3
var elapsed: float = 0.0
var bubbles: Array[Sprite2D] = []


func _ready() -> void:
	var image := preload("res://art/environment/bubble.png")
	for i in population:
		var sprite := Sprite2D.new()
		sprite.texture = image
		var size_px := 3.0 + fposmod(float(i * 17 + seed_id * 3), 5.0)
		sprite.scale = Vector2.ONE * size_px / image.get_width()
		add_child(sprite)
		bubbles.append(sprite)
	_present()


func _process(delta: float) -> void:
	elapsed += delta
	_present()


func _present() -> void:
	for i in bubbles.size():
		var distance := elapsed * (base_speed + float(i % 7)) + float(i) / population * bounds.size.y
		var y := bounds.end.y - fposmod(distance, bounds.size.y)
		var x := bounds.position.x + bounds.size.x * (0.18 + fposmod(float(i + seed_id) * 0.367, 0.64))
		bubbles[i].position = Vector2(x + sin(elapsed * 0.7 + i) * 3.0, y)
		bubbles[i].modulate.a = smoothstep(0.0, 26.0, minf(y - bounds.position.y, bounds.end.y - y)) * opacity
