class_name KitInteractable
extends Node2D
## Stationary authored residents and memory devices. The campaign owns E priority.
@export var interaction_id: String = ""
@export var display_name: String = ""
@export var title: String = ""
@export var prompt_text: String = ""
@export var lines: PackedStringArray = []
@export var radius: float = 105.0
@export var vertical_range: float = 100.0
@export var progress_flag: String = ""
@export var progressed_lines: PackedStringArray = []
@export var required_flags: PackedStringArray = []
@export var locked_lines: PackedStringArray = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("kit_interactables")

func nearby(level: Node2D) -> bool:
	if not is_inside_tree() or not is_visible_in_tree(): return false
	var actor: Node2D = level.get("player") as Node2D
	var scenery: Node = level.get("scenery") as Node
	if not is_instance_valid(actor) or not is_instance_valid(scenery): return false
	if not scenery.is_ancestor_of(self) or int(actor.get("health")) <= 0: return false
	var offset: Vector2 = actor.global_position - global_position
	return absf(offset.x) <= radius and absf(offset.y) <= vertical_range

static func nearest(level: Node2D) -> KitInteractable:
	if not level.is_inside_tree(): return null
	var actor: Node2D = level.get("player") as Node2D
	if not is_instance_valid(actor): return null
	var closest: KitInteractable
	var distance: float = INF
	for item: Node in level.get_tree().get_nodes_in_group("kit_interactables"):
		if not item is KitInteractable or not item.nearby(level): continue
		var candidate: float = actor.global_position.distance_squared_to(item.global_position)
		if candidate < distance:
			closest = item
			distance = candidate
	return closest

func prompt() -> String:
	if not prompt_text.is_empty(): return prompt_text
	return display_name if not display_name.is_empty() else title

func lines_for(level: Node2D) -> PackedStringArray:
	for flag: String in required_flags:
		if not level.has_ability(flag): return locked_lines if not locked_lines.is_empty() else lines
	if not progress_flag.is_empty() and level.has_ability(progress_flag) and not progressed_lines.is_empty():
		return progressed_lines
	return lines

func interact(level: Node2D) -> bool:
	if not nearby(level): return false
	var controller: WhaleCampaignUI = level.get("player_ui") as WhaleCampaignUI
	if not is_instance_valid(controller) or controller.busy or not controller.page_id.is_empty(): return false
	var content: PackedStringArray = lines_for(level)
	if content.is_empty(): return false
	controller.open_conversation(title if not title.is_empty() else display_name, content, interaction_id)
	level.record_event("conversation", {"id":interaction_id})
	return true
