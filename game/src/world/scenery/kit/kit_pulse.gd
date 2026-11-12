class_name KitGlowPulse
extends Sprite2D
## Slow brightness breathing for a library light bitmap; the shape never moves.
@export_range(0.0, 1.0) var base_alpha: float = 0.18
@export_range(0.0, 0.5) var depth: float = 0.08
@export var period: float = 8.0
@export var phase: float = 0.0
var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	modulate.a = clampf(base_alpha + sin(time * TAU / maxf(period, 0.1) + phase) * depth, 0.0, 1.0)
