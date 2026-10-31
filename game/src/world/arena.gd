class_name BossArena
extends Node2D

@export var trigger_x: float = 448.0
@export var limits: Vector2 = Vector2(460.8, 2259.2)
@export var victory_flag: String = "boss.r1_shell_crab"


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var active := player.position.x > trigger_x and not GameState.has_flag(victory_flag)
	if active and not GameState.arena_active:
		GameState.arena_active = true
		player.arena_bounds = limits
		EventBus.arena_changed.emit(true)
	$Curtain.visible = GameState.arena_active
