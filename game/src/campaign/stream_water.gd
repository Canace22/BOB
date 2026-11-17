class_name CampaignStreamWater
extends RefCounted
## 连续远景包含水体与器官；房间只保留玩法中近景。
const SHADER := preload("res://src/campaign/stream_water.gdshader")
const PATHS: Array[String] = [
	"res://art/world-kit/r3-water-base.png",
	"res://art/world-kit/r2-water-base.png",
	"res://art/world-kit/r4-water-base.png",
	"res://art/world-kit/r5-head-water-base.png",
	"res://art/world-kit/r5-tail-water-base.png",
]

const BACKDROPS: Array[String] = [
	"res://art/continuous-backdrops-v1/mouth.png",
	"res://art/continuous-backdrops-v1/lung.png",
	"res://art/continuous-backdrops-v1/gastric.png",
	"res://art/continuous-backdrops-v1/spine.png",
	"res://art/continuous-backdrops-v1/cranial.png",
	"res://art/continuous-backdrops-v1/tail.png",
]
const ORGAN_NAMES: Array[String] = ["r2-lung-far-layer.png","r3-gastric-far-layer.png","r4-vertebrae-far-layer.png","r5-cranial-far-layer.png","r5-tail-far-layer.png"]

static func owns(texture: Texture2D) -> bool:
	return texture != null and (PATHS.has(texture.resource_path) or ORGAN_NAMES.has(texture.resource_path.get_file()))

static func biome(id: String) -> int:
	if id.begins_with("R2-"): return 1
	if id.begins_with("R3-"): return 2
	if id.begins_with("R4-"): return 3
	if id=="R5-08": return 5
	if id.begins_with("R5-"): return 4
	return 0

static func create(layout: Dictionary) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.set_script(preload("res://src/campaign/stream_backdrop.gd"))
	sprite.name = "ContinuousWater"
	sprite.z_index = -100
	sprite.texture = load(PATHS[0])
	sprite.centered = false
	var bounds: Rect2 = Rect2(layout.bounds).grow(1200)
	sprite.position = bounds.position
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO,bounds.size)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	for i: int in BACKDROPS.size(): material.set_shader_parameter("water_"+str(i),load(BACKDROPS[i]))
	var rectangles := PackedVector4Array()
	var biomes := PackedInt32Array()
	var anchors := PackedVector2Array()
	anchors.resize(6)
	var assigned: Dictionary = {}
	for index: int in layout.room_bounds:
		var rect: Rect2 = layout.room_bounds[index]
		rectangles.append(Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
		var zone: int = biome(str(layout.rooms[index].id))
		biomes.append(zone)
		if not assigned.has(zone):
			anchors[zone] = rect.get_center()
			assigned[zone] = true
	material.set_shader_parameter("rooms",rectangles)
	material.set_shader_parameter("biomes",biomes)
	material.set_shader_parameter("room_count",rectangles.size())
	material.set_shader_parameter("anchors",anchors)
	sprite.material = material
	return sprite
