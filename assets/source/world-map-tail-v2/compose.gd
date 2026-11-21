extends SceneTree
## The two source paintings are placed at uniform scale. The tail and the joins
## come from the painted plate. Coordinates below are in the source paintings.
const BATCH := "res://../assets/source/world-map-tail-v2/"
const HEAD := "res://../assets/source/world-continuity-v1/images/02-r1-continuous.png"
const BODY := "res://../docs/鲸腹遗城原画集/V2/images/A02_鲸体剖面_空间分区.png"

func _initialize() -> void:
	var plate := Image.load_from_file(BATCH + "tail-paint.png")
	var head := Image.load_from_file(HEAD)
	var body := Image.load_from_file(BODY)
	if plate == null or head == null or body == null or plate.get_size() != Vector2i(2171, 724):
		quit(1)
		return
	var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BATCH + "registration.json"))
	var result := plate.duplicate() as Image
	restore(result, plate, head, Vector2i(8, 86), 0.48, head_edge, registration.head)
	restore(result, plate, body, Vector2i(552, -20), 0.892, body_edge, registration.body)
	var tail := Image.load_from_file(BATCH + "tail-detail.png")
	if tail == null:
		quit(1)
		return
	quit(attach_tail(result, tail).save_png(BATCH + "whale-overview.png"))

func attach_tail(torso: Image, tail: Image) -> Image:
	tail.resize(1230, 724, Image.INTERPOLATE_LANCZOS)
	var full := Image.create_empty(2340, 724, false, torso.get_format())
	full.blit_rect(tail, Rect2i(Vector2i.ZERO, tail.get_size()), Vector2i(1110, 0))
	full.blit_rect(torso, Rect2i(0, 0, 1640, 724), Vector2i.ZERO)
	for x in range(1640, 1800):
		var join := smoothstep(1640, 1710, x)
		var offset := 2.0 * (1.0 - smoothstep(1710, 1800, x))
		for y in full.get_height():
			var color := sample(tail, Vector2(x-1110, y) + Vector2(offset, offset))
			full.set_pixel(x, y, torso.get_pixel(x, y).lerp(color, join))
	return full

func restore(result: Image, plate: Image, source: Image, origin: Vector2i, scale_by: float, edge_at: Callable, registration: Dictionary) -> void:
	source.resize(roundi(source.get_width() * scale_by), roundi(source.get_height() * scale_by), Image.INTERPOLATE_LANCZOS)
	var field := offset_image(registration.rows)
	var start := Vector2(registration.start[0], registration.start[1])
	var area := Rect2i(origin, source.get_size()).grow(64).intersection(Rect2i(Vector2i.ZERO, plate.get_size()))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var position := Vector2i(x, y)
			var local := position - origin
			var edge: float = edge_at.call(Vector2(local) / scale_by) * scale_by
			if edge <= -64.0:
				continue
			if edge >= 20.0:
				result.set_pixelv(position, source.get_pixelv(local))
				continue
			# Only the new painting moves to meet the original ink in the collar.
			var shift := sample(field, (Vector2(local) - start) / float(registration.step))
			var uv := Vector2(position) + Vector2(shift.r, shift.g) * smoothstep(-64, 0, edge)
			var color := sample(plate, uv)
			if edge > 0.0:
				color = color.lerp(source.get_pixelv(local), smoothstep(0, 20, edge))
			result.set_pixelv(position, color)

func offset_image(rows: Array) -> Image:
	var field := Image.create_empty(rows[0].size(), rows.size(), false, Image.FORMAT_RGF)
	for y in field.get_height():
		for x in field.get_width():
			var offset: Array = rows[y][x]
			field.set_pixel(x, y, Color(offset[0], offset[1], 0))
	return field

func sample(img: Image, point: Vector2) -> Color:
	var limit := img.get_size() - Vector2i.ONE
	var uv := point.clamp(Vector2.ZERO, Vector2(limit))
	var a := Vector2i(uv)
	var b := (a + Vector2i.ONE).min(limit)
	var upper := img.get_pixel(a.x, a.y).lerp(img.get_pixel(b.x, a.y), uv.x-a.x)
	var lower := img.get_pixel(a.x, b.y).lerp(img.get_pixel(b.x, b.y), uv.x-a.x)
	return upper.lerp(lower, uv.y-a.y)

func head_edge(p: Vector2) -> float:
	var bottom := lerpf(455.0, 600.0, smoothstep(0, 1200, p.x))
	var right := lerpf(1880.0, 1675.0, smoothstep(300, 570, p.y))
	return minf(minf(p.y, p.x), minf(bottom - p.y, right - p.x))

func body_edge(p: Vector2) -> float:
	var left := lerpf(660.0, 545.0, smoothstep(150, 360, p.y))
	var right := lerpf(1370.0, 1490.0, smoothstep(250, 490, p.y))
	return minf(minf(p.x - left, right - p.x), minf(p.y - 148.0, 638.0 - p.y))
