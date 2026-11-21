@tool
extends Node2D

## Runtime-room panorama editor.
## Every Preview_* child is instantiated from the same PackedScene path used by
## CampaignRoomStream, so the editor and F5 use the same room source files.

@export var show_room_bounds := true:
	set(value):
		show_room_bounds = value
		queue_redraw()
@export var show_room_labels := true:
	set(value):
		show_room_labels = value
		queue_redraw()
@export var show_room_content := true:
	set(value):
		show_room_content = value
		_rebuild_rooms()

const ROOM_DATA := "res://art/whalebelly/rooms.json"
const WHALE_OVERVIEW := "res://art/world-map/whale-anatomy-overview.png"
const ANATOMY_CONTRACT := "res://content/whalebelly/world/anatomy_map_contract.json"
## Runtime room scenes are authored in large pixel coordinates (roughly
## 2,000–4,000 px per room). The cutaway is a 2,340 px source panorama, so
## this scale keeps the real room art readable while fitting its anatomy band.
const PREVIEW_SCENE_SCALE := 0.035
const PREVIEW_Y := {
	"R1-01": 0.47, "R1-02": 0.34, "R1-03": 0.52, "R1-04": 0.58,
	"R1-05": 0.45, "R1-06": 0.16, "R1-07": 0.28,
	"R2-01": 0.26, "R2-03": 0.46, "R2-04": 0.57,
	"R3-01": 0.56,
	"R4-01": 0.24, "R4-03": 0.14, "R4-05": 0.22, "R4-06": 0.30,
	"R5-01": 0.32, "R5-02": 0.43, "R5-04": 0.54, "R5-08": 0.48
}
var _layout: Dictionary = {}
var _rooms: Array[Dictionary] = []
var _room_nodes: Array[Node] = []
var _whale: Sprite2D
var _font: Font
var _signature := 0
var _elapsed := 0.0

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_layout = _build_anatomy_preview(_load_layout())
	_install_whale_background()
	_rebuild_rooms()
	_signature = _scene_signature()
	queue_redraw()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_elapsed += delta
		if _elapsed >= 1.0:
			_elapsed = 0.0
			var current := _scene_signature()
			if current != _signature:
				_signature = current
				_rebuild_rooms()
			queue_redraw()

func _load_layout() -> Dictionary:
	var file := FileAccess.open(ROOM_DATA, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		return {}
	_rooms.assign(CampaignWorld.load_rooms(parsed))
	return CampaignStreamingLayout.build(_rooms)

func _build_anatomy_preview(_runtime_layout: Dictionary) -> Dictionary:
	## The editor preview is a presentation of the whale cutaway, not the
	## runtime streaming coordinate system. Runtime origins deliberately remain
	## in gameplay units; preview origins use the V5 anatomy bands instead.
	var contract_file := FileAccess.open(ANATOMY_CONTRACT, FileAccess.READ)
	if contract_file == null:
		return _runtime_layout
	var parsed: Variant = JSON.parse_string(contract_file.get_as_text())
	if not parsed is Dictionary:
		return _runtime_layout
	var contract: Dictionary = parsed
	var texture := load(WHALE_OVERVIEW) as Texture2D
	if texture == null:
		return _runtime_layout
	var origins: Dictionary = {}
	var bounds: Dictionary = {}
	var image_size := Vector2(texture.get_width(), texture.get_height())
	var room_contracts: Dictionary = contract.get("rooms", {})
	for index: int in _rooms.size():
		var room: Dictionary = _rooms[index]
		var id := str(room.id)
		if not room_contracts.has(id):
			continue
		var anatomy: Dictionary = room_contracts[id]
		var size := Vector2(float(room.size[0]), float(room.size[1])) * PREVIEW_SCENE_SCALE
		var center_x := float(anatomy.get("actualX", anatomy.get("expectedX", 0.5))) * image_size.x
		var center_y := float(PREVIEW_Y.get(id, 0.5)) * image_size.y
		var rect := Rect2(Vector2(center_x, center_y) - size * 0.5, size)
		# Keep the preview rectangle inside the source panorama while preserving
		# the anatomical anchor. The room remains a local scene, not a collision
		# measurement of the concept art.
		rect.position.x = clampf(rect.position.x, 0.0, image_size.x - rect.size.x)
		rect.position.y = clampf(rect.position.y, 0.0, image_size.y - rect.size.y)
		origins[index] = rect.position
		bounds[index] = rect
	var links: Array[Dictionary] = []
	for a: int in _rooms.size():
		if not bounds.has(a):
			continue
		for door: Dictionary in _rooms[a].get("doors", []):
			var b := int(door.get("to", -1))
			if b <= a or not bounds.has(b):
				continue
			links.append({"a": a, "b": b, "path": PackedVector2Array([bounds[a].get_center(), bounds[b].get_center()])})
	return {"origins": origins, "links": links, "rooms": _rooms, "room_bounds": bounds,
		"bounds": Rect2(Vector2.ZERO, image_size), "preview_scale": PREVIEW_SCENE_SCALE}

func _install_whale_background() -> void:
	if _layout.is_empty():
		return
	var texture := load(WHALE_OVERVIEW) as Texture2D
	if texture == null:
		return
	_whale = Sprite2D.new()
	_whale.name = "WhaleAnatomyOverview"
	_whale.texture = texture
	_whale.centered = false
	_whale.z_index = -100
	_whale.scale = Vector2.ONE
	_whale.position = Vector2.ZERO
	add_child(_whale)

func _rebuild_rooms() -> void:
	if _layout.is_empty() or not show_room_content:
		return
	for node: Node in _room_nodes:
		if is_instance_valid(node):
			node.free()
	_room_nodes.clear()
	for index_variant: Variant in _layout.origins.keys():
		var index := int(index_variant)
		if index < 0 or index >= _rooms.size():
			continue
		var room_id := str(_rooms[index].id)
		var packed := load(CampaignWorld.scene_path(room_id)) as PackedScene
		if packed == null:
			continue
		var room := packed.instantiate() as Node2D
		if room == null:
			continue
		room.name = "Preview_" + room_id
		room.position = Vector2(_layout.origins[index])
		room.scale = Vector2.ONE * float(_layout.get("preview_scale", 1.0))
		add_child(room)
		if Engine.is_editor_hint():
			room.owner = self
		room.set_meta("runtime_source_scene", CampaignWorld.scene_path(room_id))
		_room_nodes.append(room)

func _scene_signature() -> int:
	var result := 17
	for room: Dictionary in _rooms:
		var path := CampaignWorld.scene_path(str(room.id))
		if FileAccess.file_exists(path):
			result = result * 31 + int(FileAccess.get_modified_time(path) % 2147483647)
	return result

func _draw() -> void:
	if _layout.is_empty():
		return
	var font := _font if _font else ThemeDB.fallback_font
	for index_variant: Variant in _layout.room_bounds.keys():
		var index := int(index_variant)
		if index < 0 or index >= _rooms.size():
			continue
		var rect: Rect2 = _layout.room_bounds[index]
		if show_room_bounds:
			draw_rect(rect, Color(0.3, 0.8, 0.9, 0.08), true)
			draw_rect(rect, Color(0.4, 0.9, 1.0, 0.8), false, 6.0)
		if show_room_labels:
			draw_string(font, rect.position + Vector2(24, 42), str(_rooms[index].id), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#e8fbff"))
	for link: Dictionary in _layout.links:
		var points := PackedVector2Array(link.path)
		if points.size() > 1:
			draw_polyline(points, Color(0.95, 0.75, 0.25, 0.9), 7.0, true)

