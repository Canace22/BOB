class_name ChapterRoomEnvironment
extends Control
## One pausable room clock; children do not advance themselves.
@export var room_id: String = "R1-02"
@export var animate_environment: bool = true
@export var motion_strength: float = 1.0
var elapsed: float = 0.0
var flex_parts: Array[ChapterPinnedBitmap] = []
var schools: Array[ChapterFishGroup] = []
var emitters: Array[EnvironmentBubbleEmitter] = []
var pulse_parts: Array[Sprite2D] = []
var home: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for child: Node in find_children("*","Node",true,false):
		if child is ChapterPinnedBitmap: flex_parts.append(child)
		elif child is ChapterFishGroup: schools.append(child)
		elif child is EnvironmentBubbleEmitter: emitters.append(child)
		elif child is Sprite2D and child.has_meta("pulse_period"): pulse_parts.append(child)
	for part: Node2D in [get_node("Far"),get_node("Middle"),get_node("Foreground")]:
		home[part.name] = part.position
	update_at(0)

func _process(delta: float) -> void:
	if animate_environment:
		elapsed += delta * motion_strength
	update_at(elapsed)

func update_at(time: float) -> void:
	elapsed = time
	var water_material := $Far/Surface.material as ShaderMaterial
	if water_material != null: water_material.set_shader_parameter("clock",time)
	for part: ChapterPinnedBitmap in flex_parts: part.update_at(time)
	for school: ChapterFishGroup in schools: school.update_at(time)
	for emitter: EnvironmentBubbleEmitter in emitters: emitter.update_at(time)
	for part: Sprite2D in pulse_parts:
		var period: float = part.get_meta("pulse_period")
		var amplitude: float = part.get_meta("pulse_amplitude")
		var brightness := 1.0 + sin(time*TAU/period)*amplitude
		part.modulate = Color(brightness,brightness,brightness,1)

func set_camera_offset(offset: Vector2) -> void:
	# Small displacement only, within the prepared underpaint margin. No player binding.
	var shift := offset.clamp(Vector2(-6,-4),Vector2(6,4))
	$Far.position = shift
	$Middle.position = shift*.38
	$Foreground.position = -shift*.6

func set_view_layer(selected: int) -> void:
	var names: Array[String] = ["Far","Middle","World","Foreground"]
	for i in names.size():
		get_node(names[i]).visible = selected < 0 or selected == i

func content_counts() -> Dictionary:
	var fish_count := 0
	var bubble_count := 0
	for school: ChapterFishGroup in schools: fish_count += school.sprites.size()
	for emitter: EnvironmentBubbleEmitter in emitters: bubble_count += emitter.bubbles.size()
	return {"flex":flex_parts.size(),"schools":schools.size(),"fish":fish_count,"bubble_emitters":emitters.size(),"bubbles":bubble_count,"pulses":pulse_parts.size()}
