class_name ShellLever
extends Interactable

@export var flag_id: String = "latch.r1_tongue"
@export var bridge: StaticBody2D
@export var open_texture: Texture2D


func _ready() -> void:
	super._ready()
	_refresh()


func available() -> bool:
	return not GameState.has_flag(flag_id)


func use() -> void:
	GameState.set_flag(flag_id)
	GameState.save_progress()
	_refresh()
	EventBus.toast.emit("壳闩已开 · 短桥接回主路 · 永久保存")


func _refresh() -> void:
	var opened := GameState.has_flag(flag_id)
	bridge.visible = opened
	(bridge.get_node("Shape") as CollisionShape2D).set_deferred("disabled", not opened)
	if opened:
		($Sprite as Sprite2D).texture = open_texture
	$Prompt.visible = not opened
