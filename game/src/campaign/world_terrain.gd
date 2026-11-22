class_name CampaignWorldTerrain
extends Node2D
## 母版统一构图后导出的区块；加载只决定资源驻留，不改变任何像素的透明度。
const DATA := "res://art/world-terrain-v2/chunks.json"
var host: Node2D
var records: Array = []
var resident: Dictionary = {}
var elapsed: float = 0.0

static func repaint_rectangles() -> PackedVector4Array:
	var result:=PackedVector4Array()
	var file: String="res://art/world-seam-repaint-v3/registration.json"
	if not FileAccess.file_exists(file): return result
	for entry: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(file)):
		var rect: Array=entry.world
		result.append(Vector4(rect[0],rect[1],rect[2],rect[3]))
	return result

static func owns(node: Node) -> bool:
	if not node is Sprite2D: return false
	if node.has_meta("stream_master_terrain_source"): return true
	var parent: Node = node.get_parent()
	if parent==null: return false
	if parent.name=="Art" and parent.get_parent()!=null and parent.get_parent().name=="World":
		var name_text: String=str(node.name)
		return name_text.begins_with("Surface") or name_text.begins_with("Bed") or (name_text.length()>2 and name_text.substr(1,1).is_valid_int() and name_text.contains("_"))
	if node.name=="Surface" and parent.name=="World" and parent.get_parent() is ChapterRoomEnvironment:
		# 舌台会按机关状态下垂，保留实时层，不能把静止像素烘焙进碰撞下面。
		return parent.get_parent().room_id!="R1-03"
	return node.name=="ROAD" and parent is WhalebellyReferenceEnvironment

func _ready() -> void:
	z_index=0
	if FileAccess.file_exists(DATA): records=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	update_window()

func _process(dt: float) -> void:
	if not is_instance_valid(host) or host.quitting: return
	# Capture mode must retain the runtime terrain; otherwise the capture only
	# shows the water layers and dynamic decoration after authored art is hidden.
	visible=not host.reference_visible and host.layer_solo<0
	elapsed+=dt
	if elapsed>=0.15:
		elapsed=0.0
		update_window()

func update_window() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.player): return
	var camera: Camera2D=host.get_viewport().get_camera_2d()
	var center: Vector2=host.player.global_position
	var view_size: Vector2=host.get_viewport_rect().size
	if camera!=null: view_size/=camera.zoom
	var view:=Rect2(center-view_size*0.5,view_size).grow(1800)
	for record: Dictionary in records:
		var key: String=str(record.file)
		var rect:=Rect2(float(record.x),float(record.y),float(record.width),float(record.height))
		if view.intersects(rect):
			if resident.has(key): continue
			var tile:=Sprite2D.new()
			var texture_path := "res://art/world-terrain-v2/" + key
			if key == "tile_1_0.png" and str(host.room.get("id", "")) == "R1-02":
				texture_path = "res://art/world-terrain-v2/tile_1_0_r1_02_moved.png"
			tile.texture=load(texture_path)
			tile.centered=false
			tile.region_enabled=true
			tile.region_rect=Rect2(2,2,rect.size.x,rect.size.y)
			tile.region_filter_clip_enabled=false
			tile.position=rect.position
			tile.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(tile)
			resident[key]=tile
		elif resident.has(key) and not view.grow(1500).intersects(rect):
			resident[key].queue_free()
			resident.erase(key)
