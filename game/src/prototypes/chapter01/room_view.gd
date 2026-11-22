class_name Chapter01RoomView
extends Node2D
## 同一套原口腔位图和地形轮廓配对复用；碰撞不随视差移动。

const FONT: Font = preload("res://art/fonts/WhalefallUI.ttf")
var data: Dictionary
var environment: Node
var door_nodes: Dictionary = {}


func setup(room: Dictionary) -> void:
	data = room
	environment=load(str(data.environment_scene)).instantiate()
	if environment is WhalebellyReferenceEnvironment:
		environment.level_mode=true
		environment.scale=Vector2.ONE*(float(data["size"].x)/1280.0)
	add_child(environment)
	for index in range(data.surfaces.size()):
		var points: Array = data.surfaces[index]
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var polygon := CollisionPolygon2D.new()
		var contour := collision_contour(points, data["size"].y + 180 if index == 0 else 0.0)
		if index > 0:
			polygon.one_way_collision = true
		polygon.polygon = contour
		body.add_child(polygon)
		add_child(body)
	for door: Dictionary in data.doors:
		_add_door(door)


static func collision_contour(points: Array, floor_bottom: float) -> PackedVector2Array:
	var contour := PackedVector2Array()
	for point: Array in points:
		contour.append(Vector2(float(point[0]), float(point[1])))
	if floor_bottom > 0:
		contour.append(Vector2(float(points[-1][0]), floor_bottom))
		contour.append(Vector2(float(points[0][0]), floor_bottom))
	else:
		# 下沿沿原曲线反向偏移，避免弧形台面与直线封底相交。
		for index in range(points.size() - 1, -1, -1):
			contour.append(Vector2(float(points[index][0]), float(points[index][1]) + 16))
	return contour


func _add_door(door: Dictionary) -> void:
	var anchor := Node2D.new()
	anchor.position = door.position
	anchor.z_index = 3
	add_child(anchor)
	var label := Label.new()
	label.position = Vector2(-140, -190)
	label.size = Vector2(280, 44)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("e3d7b9"))
	label.add_theme_color_override("font_outline_color", Color("e3d7b9"))
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", Color("06131a"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.text = str(door.label)
	anchor.add_child(label)
	door_nodes[door.to] = {"root": anchor, "label": label}


func update_doors(visited: Dictionary, near: String) -> void:
	for door: Dictionary in data.doors:
		var label: Label = door_nodes[door.to].label
		var available := Chapter01Layout.door_open(door, visited)
		var arrow: String = {"left": "←", "right": "→", "up": "↑", "down": "↓"}[door.direction]
		label.text = arrow + " " + str(door.label)
		if not available:
			label.text += " · 尚未接通"
		elif near == door.to:
			label.text = "[E] " + label.text
		label.modulate.a = 1.0 if near == door.to else 0.65


func parallax(camera: Vector2) -> void:
	if environment is ChapterRoomEnvironment:
		environment.set_camera_offset(camera-data["size"]*0.5)
