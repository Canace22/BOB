class_name Pickup
extends Interactable

@export var flag_id: String = ""
@export var ability_id: String = ""
@export var required_flags: PackedStringArray = []
@export var collected_texture: Texture2D


func _ready() -> void:
	super._ready()
	EventBus.flag_set.connect(_refresh.unbind(1))
	EventBus.ability_granted.connect(_refresh.unbind(1))
	_refresh()


func available() -> bool:
	return not GameState.has_flag(flag_id) and (ability_id.is_empty() or not GameState.has_ability(ability_id))


func use() -> void:
	if not GameState.meets([], required_flags):
		EventBus.toast.emit("先击败负壳蟹，再承接贴流冲")
		return
	GameState.set_flag(flag_id)
	if not ability_id.is_empty():
		GameState.grant_ability(ability_id)
	GameState.save_progress()
	EventBus.sfx.emit("collect")
	EventBus.toast.emit(prompt.trim_prefix("E ") + " · 已保存")
	_refresh()


func _refresh() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite != null:
		if not available() and collected_texture != null:
			sprite.texture = collected_texture
		else:
			sprite.visible = available()
	var label := get_node_or_null("Prompt") as Label
	if label != null:
		label.visible = available()
