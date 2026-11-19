class_name WhaleDialogueTrigger
extends Node2D
## 关卡作者在房内放置触发范围，剧情以稳定ID和条件驱动，不依赖节点显示名。
@export var dialogue_id: String = ""
@export_enum("自动对话", "按键交流", "行进字幕") var activation: int = 0
@export var room_id: String = ""
@export var area: Rect2 = Rect2(-80,-100,160,150)
@export var once: bool = true
@export var priority: int = 0
@export var required_seen: PackedStringArray = []
@export var blocked_seen: PackedStringArray = []
@export var required_collected: PackedStringArray = []
@export var required_abilities: PackedStringArray = []
@export var speakers: PackedStringArray = []
@export_multiline var lines: PackedStringArray = []
@export var prompt: String = "交流"
@export var objective_id: String = ""
@export var objective_text: String = ""
@export var subtitle_seconds: float = 5.0

func _ready() -> void:
	add_to_group("campaign_dialogue_triggers")

func contains(player: Node2D) -> bool:
	return area.has_point(to_local(player.global_position))

func eligible(host: Node2D, seen: Dictionary) -> bool:
	if dialogue_id.is_empty() or lines.is_empty(): return false
	if room_id != str(host.room.id) or not host.scenery.is_ancestor_of(self): return false
	if once and seen.get(dialogue_id,false): return false
	for flag: String in required_seen:
		if not seen.get(flag,false): return false
	for flag: String in blocked_seen:
		if seen.get(flag,false): return false
	for flag: String in required_collected:
		if not host.collected.get(flag,false): return false
	for ability: String in required_abilities:
		if not host.has_ability(ability): return false
	return true

func specification() -> Dictionary:
	return {"id":dialogue_id,"room":room_id,"lines":lines,"speakers":speakers,
		"objective_id":objective_id,"objective":objective_text,"subtitle":activation==2,"seconds":subtitle_seconds}
