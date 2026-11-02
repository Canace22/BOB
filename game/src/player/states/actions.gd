class_name PlayerActions
extends Node
## Action state: idle / attack / heal / dash / hurt. Movement stays in locomotion.gd.

signal ranged_fired

var mode: String = "idle"
var elapsed: float = 0.0
var attack_kind: String = "short1"
var combo: bool = false
var activated: bool = false
var air_dash: bool = false
var cooldown: float = 0.0
var queued_input: StringName = &""
var pending_input: StringName = &""
var pending_left: float = 0.0


func is_free() -> bool:
	return mode == "idle"


func can_jump(player: Player) -> bool:
	if not player.tuning.prototype_controls:
		return mode in ["idle", "attack"]
	return mode == "aim" or is_free() or can_cancel_attack(player)


func attack_duration() -> float:
	return 0.82 if attack_kind == "heavy" else (0.50 if attack_kind == "short2" else 0.40)


func attack_active_start() -> float:
	if attack_kind == "ranged":
		return 0.06
	return 0.30 if attack_kind == "heavy" else (0.16 if attack_kind == "short2" else 0.12)


func attack_active_end() -> float:
	return attack_active_start() + (0.12 if attack_kind == "heavy" else 0.08)


func can_cancel_attack(player: Player) -> bool:
	var recovery := attack_duration() - player.tuning.action_buffer
	if player.tuning.prototype_controls:
		recovery = attack_active_end() + (0.12 if attack_kind == "heavy" else 0.0)
	return mode == "attack" and elapsed >= maxf(attack_active_end(), recovery)


func can_link_hit(player: Player) -> bool:
	return mode == "attack" and attack_kind in ["short1", "short2"] and activated \
		and elapsed >= attack_active_end() and player.hitbox.has_landed()


func cancel_attack(player: Player) -> void:
	player.hitbox.deactivate()
	change("idle")
	combo = false
	activated = false
	consume_input()


func reset() -> void:
	change("idle")
	attack_kind = "short1"
	combo = false
	activated = false
	air_dash = false
	cooldown = 0.0
	queued_input = &""
	consume_input()


func buffer_input(action: StringName) -> void:
	if queued_input.is_empty() and action in [&"attack", &"heavy", &"heal", &"dash"]:
		queued_input = action


func dash_available() -> bool:
	return GameState.has_ability("ability.dash") and cooldown <= 0 and not air_dash


func pressed(action: StringName, buffered: StringName) -> bool:
	return buffered == action if not buffered.is_empty() else Input.is_action_just_pressed(action)


func read_input(player: Player, delta: float) -> StringName:
	var buffered := queued_input
	queued_input = &""
	if not player.tuning.prototype_controls:
		return buffered
	pending_left = maxf(0, pending_left - delta)
	if pending_left <= 0:
		pending_input = &""
	for action: StringName in [&"attack", &"heavy", &"heal", &"dash"]:
		if pressed(action, buffered):
			pending_input = action
			pending_left = player.tuning.action_buffer
			break
	return pending_input


func consume_input() -> void:
	pending_input = &""
	pending_left = 0.0


func step(player: Player, delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	var buffered := read_input(player, delta)
	if mode == "aim" and not buffered.is_empty():
		change("idle")
	var attack_pressed := pressed(&"attack", buffered)
	var dash_pressed := pressed(&"dash", buffered)
	if attack_pressed:
		if is_free():
			begin_attack(player, "short1")
		elif mode == "attack" and attack_kind == "short1" and elapsed >= (attack_active_start() if player.tuning.prototype_controls else 0.30):
			combo = true
			consume_input()
	if player.tuning.prototype_controls and can_link_hit(player):
		if pressed(&"heavy", buffered) and GameState.spend_energy(2):
			begin_attack(player, "heavy")
		elif combo:
			begin_attack(player, "short2")
	if player.tuning.prototype_controls and can_cancel_attack(player) and dash_pressed and dash_available():
		cancel_attack(player)
		start_dash(player)
	if is_free():
		if pressed(&"heavy", buffered) and GameState.spend_energy(2):
			begin_attack(player, "heavy")
		elif pressed(&"heal", buffered) and player.is_on_floor() and GameState.hp < player.health.maximum and GameState.spend_energy(2):
			change("heal")
			consume_input()
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
				GameState.heal(1, player.health.maximum)
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
	if next == "hurt":
		queued_input = &""
		consume_input()


func start_dash(player: Player) -> void:
	change("dash")
	consume_input()
	air_dash = true
	cooldown = player.tuning.dash_cooldown
	EventBus.sfx.emit("dash")


func begin_attack(player: Player, kind: String) -> void:
	change("attack")
	consume_input()
	attack_kind = kind
	combo = false
	activated = false
	player.hitbox.deactivate()
	EventBus.sfx.emit("heavy" if kind == "heavy" else "strike")


func update_attack(player: Player) -> void:
	var heavy := attack_kind == "heavy"
	var start := attack_active_start()
	var active_end := attack_active_end()
	var duration := attack_duration()
	if elapsed >= start and elapsed < active_end and not activated:
		activated = true
		if attack_kind == "ranged":
			ranged_fired.emit()
		else:
			var reach := 153.6 if heavy else 83.2
			var shape := player.hitbox.get_node("Shape") as CollisionShape2D
			(shape.shape as RectangleShape2D).size = Vector2(reach + 15, 96)
			shape.position = Vector2(player.facing * (reach - 15) / 2, -32)
			var damage := 24 if heavy else (14 if attack_kind == "short2" else 10)
			player.hitbox.activate(HitData.create(damage, player.global_position, heavy))
	if elapsed >= active_end:
		player.hitbox.deactivate()
	if elapsed >= duration:
		if attack_kind == "short1" and combo:
			begin_attack(player, "short2")
		else:
			change("idle")
