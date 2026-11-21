extends SceneTree
## Run from the repository root with Godot --headless --path game --script ../assets/source/world-map-outpaint/compose.gd.

const SOURCE := "res://../assets/source/"
const HEAD := SOURCE + "world-continuity-v1/images/02-r1-continuous.png"
const BATCH := SOURCE + "world-map-outpaint/"
const HEAD_SIZE := Vector2i(1002, 334)
const HEAD_ORIGIN := Vector2i(11, 179)

func _initialize() -> void:
	var canvas := Image.load_from_file(BATCH + "outpaint.png")
	var head := Image.load_from_file(HEAD)
	if canvas == null or head == null or canvas.get_size() != Vector2i(2172, 724) or head.get_size() != Vector2i(2172, 724):
		printerr("Expected the registered 2172 × 724 source images.")
		quit(1)
		return
	head.resize(HEAD_SIZE.x, HEAD_SIZE.y, Image.INTERPOLATE_LANCZOS)
	# Restore the source brushwork. Only feather the outer sea, skin, and join.
	var inner := Rect2i(12, 36, HEAD_SIZE.x - 12 - 40, HEAD_SIZE.y - 72)
	canvas.blit_rect(head, inner, HEAD_ORIGIN + inner.position)
	for y: int in HEAD_SIZE.y:
		for x: int in HEAD_SIZE.x:
			if inner.has_point(Vector2i(x, y)):
				continue
			var edge_x := minf(x / 12.0, (HEAD_SIZE.x - 1 - x) / 40.0)
			var edge_y := minf(y, HEAD_SIZE.y - 1 - y) / 36.0
			var weight := smoothstep(0.0, 1.0, minf(edge_x, edge_y))
			var p := HEAD_ORIGIN + Vector2i(x, y)
			canvas.set_pixelv(p, canvas.get_pixelv(p).lerp(head.get_pixel(x, y), weight))
	quit(canvas.save_png(BATCH + "whale-overview.png"))
