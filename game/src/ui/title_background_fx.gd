class_name WhaleTitleBackgroundFX
extends Control

var elapsed: float = 0.0
var bubbles: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in range(30):
		bubbles.append({
			"x": 0.04 + fmod(float(i * 37), 92.0) / 100.0,
			"y": 0.12 + fmod(float(i * 61), 86.0) / 100.0,
			"size": 1.5 + fmod(float(i * 19), 5.0),
			"speed": 0.012 + fmod(float(i * 7), 11.0) * 0.001,
			"phase": fmod(float(i * 29), 100.0) / 100.0
		})
	queue_redraw()

func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, 100.0)
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	# Soft vertical shafts stay near the edges so the title area remains calm.
	for beam: Dictionary in [
		{"x": 0.17, "width": 0.08, "alpha": 0.08},
		{"x": 0.79, "width": 0.11, "alpha": 0.065},
		{"x": 0.91, "width": 0.06, "alpha": 0.07}
	]:
		var x: float = size.x * float(beam.x)
		var w: float = size.x * float(beam.width)
		var points := PackedVector2Array([
			Vector2(x - w * 0.2, 0), Vector2(x + w * 0.35, 0),
			Vector2(x + w, size.y), Vector2(x - w * 0.55, size.y)
		])
		draw_colored_polygon(points, Color(0.35, 0.86, 0.9, float(beam.alpha)))
	for bubble: Dictionary in bubbles:
		var phase: float = fmod(float(bubble.phase) + elapsed * float(bubble.speed), 1.0)
		var x: float = size.x * (float(bubble.x) + sin(elapsed * 0.18 + float(bubble.phase) * 6.0) * 0.012)
		var y: float = size.y * (1.04 - phase * 1.12)
		var fade: float = minf(1.0, minf(phase * 8.0, (1.0 - phase) * 7.0))
		var radius: float = float(bubble.size) * (0.85 + 0.15 * sin(elapsed * 0.7 + float(bubble.phase) * 8.0))
		draw_circle(Vector2(x, y), radius, Color(0.7, 0.94, 0.96, 0.28 * fade))
		draw_arc(Vector2(x, y), radius + 0.8, 3.4, 5.6, 12, Color(0.82, 0.98, 1.0, 0.36 * fade), 0.8)
