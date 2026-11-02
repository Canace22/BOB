class_name ChapterEnemy
extends EnemyBase
## Shared chapter progress: defeated creatures withdraw, guards survive.


func _ready() -> void:
	health.damaged.connect(_on_damage)
	health.died.connect(_on_death)
	if GameState.has_flag(victory_flag):
		_retire()


func _on_death() -> void:
	_retire()
	GameState.set_flag(victory_flag)
	GameState.save_progress()
	if boss:
		GameState.arena_active = false
		EventBus.arena_changed.emit(false)
		EventBus.toast.emit("扣带松开，守卫放下钳子。右侧住巢传来了呼救。")
	else:
		EventBus.toast.emit("食腐甲退回了聚食处 · 通路已经清开")


func _retire() -> void:
	change("dead")
	hurtbox.immune = true
	hitbox.deactivate()
	warning.hide()
	visual.modulate = Color(0.65, 0.75, 0.8, 1.0) if boss else Color(0.45, 0.55, 0.6, 0.5)
	visual.rotation = 0


func _idle(player: Player, delta: float) -> void:
	if boss and not GameState.has_flag("chapter.challenge"):
		return
	super._idle(player, delta)
