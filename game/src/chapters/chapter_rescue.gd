class_name ChapterRescue
extends ChapterMarker
## Four drawn bracing poses plus independently moving scenery, followed by dialogue.

var elapsed: float = -1.0
var elder_poses: Array[Texture2D] = []


func _ready() -> void:
	super._ready()
	for index in range(4, 8):
		elder_poses.append(load("res://art/chapters/world/resident-%d.png" % index) as Texture2D)
	$Elder.texture = elder_poses[0]
	$Elder.visible = GameState.has_flag(flag_id)
	if GameState.has_flag(flag_id):
		$Elder.texture = elder_poses[3]


func available() -> bool:
	return elapsed < 0 and super.available()


func use() -> void:
	if not available():
		return
	elapsed = 0
	$Elder.show()
	EventBus.toast.emit("支膜裂开了——住巢正在下坠！")
	EventBus.sfx.emit("slam")


func _process(delta: float) -> void:
	super._process(delta)
	if elapsed < 0:
		return
	elapsed += delta
	if elapsed < 0.8:
		$Nest.position.y = lerpf(-180, -70, elapsed / 0.8)
		$Elder.texture = elder_poses[0]
	elif elapsed < 1.5:
		$Elder.texture = elder_poses[1]
	elif elapsed < 3.8:
		$Elder.texture = elder_poses[2]
		$Nest.position.y = lerpf(-70, -165, (elapsed - 1.5) / 2.3)
	elif elapsed < 4.8:
		$Elder.texture = elder_poses[3]
	else:
		elapsed = -1
		EventBus.chapter_story_requested.emit(title, PackedStringArray(pages), flag_id)
