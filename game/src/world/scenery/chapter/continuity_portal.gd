class_name XumenContinuityPortal
extends Node2D
## Source-painted glimpse of the SAME next organ, tied to an existing door.
@export var edge_id: String = "E02"
@export var destination_id: String = "R1-03"
@export var strip: int = 1
@export var side: float = 1.0
@export var portal_y: float = 715.0
@export var ambient_population: int = 8
var elapsed: float = 0.0
var base_position: Vector2
var plates: Array[Sprite2D] = []
var school: ChapterFishGroup
var bubbles: EnvironmentBubbleEmitter
var host: Node2D
var shift: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	base_position = position
	for node: Node in find_children("*","Sprite2D",true,false):
		if str(node.name).begins_with("Plate"): plates.append(node)
	school = get_node_or_null("Far/Fish") as ChapterFishGroup
	bubbles = get_node_or_null("Middle/Bubbles") as EnvironmentBubbleEmitter
	update_at(0.0)

func bind_level(level: Node2D) -> void:
	host = level

func _process(dt: float) -> void:
	if is_instance_valid(host):
		visible = not host.reference_visible and host.layer_solo < 0 and host.capture_path.is_empty()
		if not visible: return
	elapsed += dt
	update_at(elapsed)

func update_at(time: float) -> void:
	elapsed = time
	for plate: Sprite2D in plates:
		(plate.material as ShaderMaterial).set_shader_parameter("clock",elapsed)
	if is_instance_valid(school): school.update_at(time)
	if is_instance_valid(bubbles): bubbles.update_at(time)

func set_camera_offset(offset: Vector2) -> void:
	shift = offset.clamp(Vector2(-6,-4),Vector2(6,4))
	$Far.position = shift * 0.35
	$Middle.position = shift * 0.12

func snapshot() -> Dictionary:
	return {"edge":edge_id,"destination":destination_id,"time":elapsed,
		"fish":school.sprites.size() if is_instance_valid(school) else 0,
		"bubbles":bubbles.bubbles.size() if is_instance_valid(bubbles) else 0}
