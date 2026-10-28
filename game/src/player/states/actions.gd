class_name PlayerActions
extends Node
## Action state: idle / attack / heal / dash / hurt. Movement stays in locomotion.gd.

var mode: String = "idle"
var elapsed: float = 0.0
var attack_kind: String = "short1"
var combo: bool = false
var activated: bool = false
var air_dash: bool = false
var cooldown: float = 0.0
var queued_input: StringName = &""


func is_free() -> bool:
	return mode == "idle"


func can_jump(player: Player) -> bool:
	if not player.tuning.prototype_controls:
		return mode in ["idle", "attack"]
	return is_free() or can_cancel_attack(player)


func attack_duration() -> float:
	return 0.82 if attack_kind == "heavy" else (0.50 if attack_kind == "short2" else 0.40)


func can_cancel_attack(player: Player) -> bool:
	var active_end := 0.42 if attack_kind == "heavy" else (0.24 if attack_kind == "short2" else 0.20)
	return mode == "attack" and elapsed >= maxf(active_end, attack_duration() - player.tuning.action_buffer)


func cancel_attack(player: Player) -> void:
	player.hitbox.deactivate()
	change("idle")
	combo = false
	activated = false


func reset() -> void:
	change("idle")
	attack_kind = "short1"
	combo = false
	activated = false
	air_dash = false
	cooldown = 0.0
	queued_input = &""


func buffer_input(action: StringName) -> void:
	if queued_input.is_empty() and action in [&"attack", &"heavy", &"heal", &"dash"]:
		queued_input = action


func dash_available() -> bool:
	return GameState.has_ability("ability.dash") and cooldown <= 0 and not air_dash


func pressed(action: StringName, buffered: StringName) -> bool:
	return buffered == action if not buffered.is_empty() else Input.is_action_just_pressed(action)


func step(player: Player, delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	var buffered := queued_input
	queued_input = &""
	var attack_pressed := pressed(&"attack", buffered)
	var dash_pressed := pressed(&"dash", buffered)
	if attack_pressed:
		if is_free():
			begin_attack(player, "short1")
		elif mode == "attack" and attack_kind == "short1" and elapsed >= (attack_duration() - player.tuning.action_buffer if player.tuning.prototype_controls else 0.30):
			combo = true
	if player.tuning.prototype_controls and can_cancel_attack(player) and dash_pressed and dash_available():
		cancel_attack(player)
		start_dash(player)
	if is_free():
		if pressed(&"heavy", buffered) and GameState.spend_energy(2):
			begin_attack(player, "heavy")
		elif pressed(&"heal", buffered) and player.is_on_floor() and GameState.hp < GameState.MAX_HP and GameState.spend_energy(2):
			change("heal")
		elif dash_pressed and dash_available():
			start_dash(player)
	if mode == "idle":
		return
	elapsed += delta
	match mode:
		"attack":
			update_attack(player)
		"heal":
			if elapsed >= player.tuning.heal_duration:
				GameState.heal(1)
				player.health.restore(GameState.hp)
				EventBus.sfx.emit("heal")
				change("idle")
		"dash":
			if elapsed >= player.tuning.dash_duration:
				change("idle")
		"hurt":
			if elapsed >= 0.18:
				change("idle")


func change(next: String) -> void:
	mode = next
	elapsed = 0
	if next != "attack":
		combo = false


func start_dash(player: Player) -> void:
	change("dash")
	air_dash = true
	cooldown = player.tuning.dash_cooldown
	EventBus.sfx.emit("dash")


func begin_attack(player: Player, kind: String) -> void:
	change("attack")
	attack_kind = kind
	combo = false
	activated = false
	player.hitbox.deactivate()
	EventBus.sfx.emit("heavy" if kind == "heavy" else "strike")


func update_attack(player: Player) -> void:
	var heavy := attack_kind == "heavy"
	var start := 0.30 if heavy else (0.16 if attack_kind == "short2" else 0.12)
	var active := 0.12 if heavy else 0.08
	var duration := attack_duration()
	if elapsed >= start and elapsed < start + active and not activated:
		activated = true
		var reach := 153.6 if heavy else 83.2
		var shape := player.hitbox.get_node("Shape") as CollisionShape2D
		(shape.shape as RectangleShape2D).size = Vector2(reach + 15, 96)
		shape.position = Vector2(player.facing * (reach - 15) / 2, -32)
		var damage := 24 if heavy else (14 if attack_kind == "short2" else 10)
		player.hitbox.activate(HitData.create(damage, player.global_position, heavy))
	if elapsed >= start + active:
		player.hitbox.deactivate()
	if elapsed >= duration:
		if attack_kind == "short1" and combo:
			begin_attack(player, "short2")
		else:
			change("idle")
