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


func is_free() -> bool:
	return mode == "idle"


func can_jump() -> bool:
	return mode in ["idle", "attack"]


func step(player: Player, delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	if Input.is_action_just_pressed("attack"):
		if is_free():
			begin_attack(player, "short1")
		elif mode == "attack" and attack_kind == "short1" and elapsed >= 0.30:
			combo = true
	if is_free():
		if Input.is_action_just_pressed("heavy") and GameState.spend_energy(2):
			begin_attack(player, "heavy")
		elif Input.is_action_just_pressed("heal") and player.is_on_floor() and GameState.hp < GameState.MAX_HP and GameState.spend_energy(2):
			change("heal")
		elif Input.is_action_just_pressed("dash") and GameState.has_ability("ability.dash") and cooldown <= 0 and not air_dash:
			change("dash")
			air_dash = true
			cooldown = player.tuning.dash_cooldown
			EventBus.sfx.emit("dash")
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
	var duration := 0.82 if heavy else (0.50 if attack_kind == "short2" else 0.40)
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
