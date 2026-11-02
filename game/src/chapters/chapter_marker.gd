class_name ChapterMarker
extends Interactable

@export var title: String = ""
@export var pages: Array[String] = []
@export var flag_id: String = ""
@export var prerequisites: Array[String] = []
@export var automatic: bool = false


func available() -> bool:
	return not GameState.arena_active and GameState.meets([], PackedStringArray(prerequisites)) and not GameState.has_flag(flag_id)


func _process(_delta: float) -> void:
	$Prompt.visible = available()
	if automatic:
		$Sprite.visible = not GameState.has_flag(flag_id)
	if not automatic or not available() or GameState.has_flag(flag_id):
		return
	var actor := get_tree().get_first_node_in_group("player") as Player
	if actor != null and actor.global_position.distance_to(global_position) < radius:
		use()


func use() -> void:
	if available():
		EventBus.chapter_story_requested.emit(title, PackedStringArray(pages), flag_id)
