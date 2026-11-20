class_name CampaignRoomEcology
extends Node2D
## Decorative, bounded ecology. Owns only its children; never writes game state.
const DATA: String = "res://content/whalebelly/environment/ecology-19.json"
const ATTACHED_SHADER: Shader = preload("res://src/world/scenery/kit/ecology_attached.gdshader")
@export var room_id: String = ""
var room_data: Dictionary = {}
var profile: Dictionary = {}
var animated: Array[Node2D] = []
var attached: Array[Sprite2D] = []
var elapsed: float = 0.0
var enabled: bool = true
var speed: float = 1.0

func configure(room: Dictionary) -> void:
	room_data = room
	room_id = str(room.id)
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	profile = document.get("rooms", {}).get(str(room.id), {})

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if room_data.is_empty() and not room_id.is_empty():
		for path: String in [CampaignWorld.LAYOUT, CampaignWorld.EXTRA]:
			var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			for room: Dictionary in source.get("rooms", []):
				if str(room.id) == room_id:
					configure(room)
					break
	if profile.is_empty(): return
	var seed_id: int = int(profile.seed)
	for vent: Array in profile.get("vents", []): _bubble_vent(vent, seed_id)
	if profile.has("snow"): _nutrients(profile.snow, seed_id)
	if profile.has("fish"): _fish(profile.fish, seed_id)
	if profile.has("near_school"): _fish(profile.near_school, seed_id + 17, true)
	if profile.has("amphipods"): _amphipods(profile.amphipods, seed_id)
	for hint: Array in profile.get("patches", []): _colony(hint, seed_id + attached.size() * 17)
	update_at(0.0)

func _process(delta: float) -> void:
	if enabled: update_at(elapsed + delta * maxf(speed, 0.0))

func update_at(time: float) -> void:
	elapsed = maxf(time, 0.0)
	for node: Node2D in animated: node.call("update_at", elapsed)
	# Streaming clones materials; always use the currently rendered material.
	for sprite: Sprite2D in attached:
		(sprite.material as ShaderMaterial).set_shader_parameter("clock", elapsed)

func area(value: Array) -> Rect2:
	var size_: Vector2 = Vector2(float(room_data.size[0]), float(room_data.size[1]))
	return Rect2(Vector2(float(value[0]), float(value[1])) * size_,
		Vector2(float(value[2]), float(value[3])) * size_)

func _bubble_vent(value: Array, seed_id: int) -> void:
	var node := EnvironmentBubbleEmitter.new()
	node.name = "Fissure%02d" % animated.size()
	node.bounds = area(value)
	node.population = int(profile.get("bubble_population", 3 if profile.get("quiet", false) else 6))
	node.seed_id = seed_id
	var bubble_size: Array = profile.get("bubble_size", [4.0, 9.0])
	node.size_range = Vector2(float(bubble_size[0]), float(bubble_size[1]))
	node.base_speed = float(profile.get("bubble_speed", 9.0 if profile.get("quiet", false) else 13.0))
	node.bubble_opacity = float(profile.get("bubble_opacity", 0.30))
	var bubble_tint: Array = profile.get("bubble_tint", [0.82, 0.94, 1.0, 1.0])
	node.modulate = Color(float(bubble_tint[0]), float(bubble_tint[1]), float(bubble_tint[2]), float(bubble_tint[3]))
	node.external_clock = true
	node.z_index = 2 # Below the player (3), above distant water.
	add_child(node)
	animated.append(node)

func _nutrients(value: Array, seed_id: int) -> void:
	var node := KitDriftField.new()
	node.name = "NutrientDrift"
	node.texture = preload("res://art/world-kit/fx-particle-soft.png")
	node.bounds = area(value)
	node.population = int(value[4])
	node.velocity = Vector2(float(value[5]), float(value[6]))
	node.sway = 3.0
	node.size_range = Vector2(3.0, 7.0)
	node.opacity = float(profile.get("plankton_opacity", 0.26 if profile.get("quiet", false) else 0.40))
	var plankton_tint: Array = profile.get("plankton_tint", [1.0, 0.80, 0.51, 1.0] if profile.get("warm", false) else [0.68, 0.83, 0.91, 1.0])
	node.tint = Color(float(plankton_tint[0]), float(plankton_tint[1]), float(plankton_tint[2]), float(plankton_tint[3]))
	var plankton_size: Array = profile.get("plankton_size", [3.0, 7.0])
	node.size_range = Vector2(float(plankton_size[0]), float(plankton_size[1]))
	node.seed_id = seed_id
	node.external_clock = true
	node.z_index = -10
	add_child(node)
	animated.append(node)

func _fish(value: Array, seed_id: int, closer: bool = false) -> void:
	var node := ChapterFishGroup.new()
	node.name = "MiddleMigration" if closer else "DistantMigration"
	node.bounds = area(value)
	node.population = int(value[4])
	node.species = int(value[5])
	node.path_seconds = float(value[6])
	node.fish_widths = Vector2(float(value[7]), float(value[7]) * 1.45)
	node.swim_seconds = 4.5
	node.phase = float(seed_id % 31) * 0.19
	node.migrate = true
	node.reverse = str(room_data.id) in ["R4-03", "R5-02"]
	node.formation_size = Vector2(node.bounds.size.x * 0.18, node.bounds.size.y * 0.65)
	var fish_tint: Array = profile.get("middle_fish_tint" if closer else "far_fish_tint", [0.83, 0.90, 0.93, 0.56] if closer else [0.64, 0.79, 0.87, 0.35])
	node.school_tint = Color(float(fish_tint[0]), float(fish_tint[1]), float(fish_tint[2]), float(fish_tint[3]))
	node.z_index = -12 if closer else -22
	add_child(node)
	animated.append(node)

func _amphipods(value: Array, seed_id: int) -> void:
	var node := KitAmphipodSchool.new()
	node.name = "NurseryAmphipods"
	node.texture = preload("res://art/world-kit/r2-pelagic-amphipod-v4.png")
	node.bounds = area(value)
	node.population = int(value[4])
	node.flow_speed = float(value[5])
	node.body_width = 38.0
	node.opacity = 0.48
	node.seed_id = seed_id
	node.external_clock = true
	node.z_index = -12
	add_child(node)
	animated.append(node)

func attachment_point(hint: Array) -> Vector2:
	var size_: Vector2 = Vector2(float(room_data.size[0]), float(room_data.size[1]))
	var desired: Vector2 = Vector2(float(hint[0]), float(hint[1])) * size_
	var result: Vector2 = Vector2.INF
	var distance: float = INF
	for surface: Array in room_data.get("surfaces", []):
		if surface.size() < 2: continue
		var left: float = float(surface[0][0]) + 65.0
		var right: float = float(surface[-1][0]) - 65.0
		if right - left < 20.0: continue
		var x: float = clampf(desired.x, left, right)
		for i: int in range(1, surface.size()):
			var a := Vector2(float(surface[i-1][0]), float(surface[i-1][1]))
			var b := Vector2(float(surface[i][0]), float(surface[i][1]))
			if b.x <= a.x or x < a.x or x > b.x: continue
			var point_: Vector2 = Vector2(x, lerpf(a.y, b.y, (x-a.x)/(b.x-a.x)))
			var score: float = point_.distance_to(desired)
			if score < distance:
				distance = score
				result = point_
	return result

func _colony(hint: Array, seed_id: int) -> void:
	var anchor: Vector2 = attachment_point(hint)
	if not anchor.is_finite(): return
	# Do not put a second focal prop directly into a camp or existing landmark.
	for key: String in ["camp", "spawn"]:
		var point_data: Array = room_data.get(key, [])
		if point_data.size() >= 2 and anchor.distance_to(Vector2(float(point_data[0]), float(point_data[1]))) < 145.0: return
	var sprite := Sprite2D.new()
	sprite.name = "AttachedColony%02d" % attached.size()
	var warm: bool = profile.get("warm", false)
	var colony: Dictionary = profile.get("colony", {})
	var path: String = str(colony.get("texture", "res://art/world-kit/habitat-fungus-bed.png" if warm else "res://art/world-kit/r2-pearl-stalks-v4.png"))
	sprite.texture = load(path) as Texture2D
	var width: float = float(colony.get("width", 110.0 if profile.get("quiet", false) else 156.0))
	var span: float = float(colony.get("visible_width", sprite.texture.get_width()))
	sprite.scale = Vector2.ONE * width / span
	sprite.centered = false
	# Painted base ends at UV.y ~= .86, hidden a few pixels under the bank.
	var root_: Vector2 = Vector2(float(colony.get("root_x", sprite.texture.get_width()*0.5)),float(colony.get("root_y",sprite.texture.get_height()*0.84)))
	sprite.position = anchor - root_ * sprite.scale
	sprite.z_index = -1
	sprite.modulate = Color(0.86, 0.90, 0.96, 0.86) if not warm else Color(0.96, 0.91, 0.80, 0.9)
	if not colony.is_empty(): sprite.modulate = Color(0.96,0.96,0.98,0.9)
	var material_ := ShaderMaterial.new()
	material_.shader = ATTACHED_SHADER
	material_.set_shader_parameter("phase", float(seed_id % 23) * 0.37)
	material_.set_shader_parameter("amplitude_pixels",clampf(float(colony.get("sway_pixels",0.8))/sprite.scale.x,3.5,18.0))
	material_.set_shader_parameter("glow_strength",float(colony.get("glow",0.07)))
	material_.set_shader_parameter("period", 14.0 if profile.get("quiet", false) else 11.0)
	sprite.material = material_
	add_child(sprite)
	attached.append(sprite)

func snapshot() -> Dictionary:
	return {"room":room_data.get("id", ""), "elapsed":elapsed, "groups":animated.size(),
		"colonies":attached.size(), "nodes":find_children("*", "Node", true, false).size(),
		"enabled":enabled, "speed":speed, "harmful":false,
		"habitat":profile.get("ecology_design", {}).get("habitat", ""),
		"layers":profile.get("ecology_design", {}).get("layers", [])}
