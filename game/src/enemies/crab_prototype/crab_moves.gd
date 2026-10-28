class_name CrabMoves
extends RefCounted
## Seconds and world pixels. Cooldowns start after the whole recovery window.

const BODY_RADIUS := 150.0
const BODY_HEIGHT := 240.0
const PLAYER_RADIUS := 17.0
const CHARGE_SPEED := 280.0
const CHARGE_DISTANCE := 168.0
const RETREAT_SPACE := 180.0
const MOVES := {
	"sweep": {"tell": 0.85, "active": 0.18, "recover": 0.85, "reach": 265.0, "height": 85.0, "cooldown": 0.0},
	"second": {"tell": 0.65, "active": 0.18, "recover": 0.85, "reach": 265.0, "height": 85.0, "cooldown": 0.0},
	"slam": {"tell": 1.25, "active": 0.18, "recover": 1.5, "reach": 280.0, "height": 280.0, "cooldown": 4.0},
	"charge": {"tell": 1.35, "active": 0.6, "recover": 1.5, "reach": 174.0, "height": 240.0, "cooldown": 5.0},
}


static func value(kind: String, key: String) -> float:
	return float(MOVES[kind][key])


static func configure(box: Hitbox, kind: String, facing: float) -> void:
	var shape := box.get_node("Shape") as CollisionShape2D
	var reach := value(kind, "reach")
	var height := value(kind, "height")
	# Low claw and slam extend out from the front of the solid shell.
	var inside := BODY_RADIUS - 25
	var width := reach - inside
	(shape.shape as RectangleShape2D).size = Vector2(width, height)
	shape.position = Vector2(facing * (reach + inside) / 2, -height / 2)
	if kind == "charge":
		# Full-height shell: never let the player jump through the painted shell.
		(shape.shape as RectangleShape2D).size.x = BODY_RADIUS * 2 + 24
		shape.position.x = facing * 12


static func can_repeat(kind: String, previous: String, streak: int) -> bool:
	return kind != previous or streak < 2


static func select(distance: float, free_space: float, cooldowns: Dictionary,
		previous: String, streak: int, rng: RandomNumberGenerator, retreat_space: float = INF) -> String:
	if distance >= 120 and distance <= 350 and free_space >= RETREAT_SPACE and retreat_space >= RETREAT_SPACE:
		if float(cooldowns.get("charge", 0)) <= 0 and can_repeat("charge", previous, streak):
			return "charge"
	if distance > 100:
		return ""
	# A cornered player must always retain the stationary-jump counterplay.
	if retreat_space < RETREAT_SPACE:
		return "sweep"
	var sweep := can_repeat("sweep", previous, streak)
	var slam := float(cooldowns.get("slam", 0)) <= 0 and can_repeat("slam", previous, streak)
	if sweep and slam:
		return "sweep" if rng.randf() < 0.65 else "slam"
	if slam:
		return "slam"
	return "sweep" if sweep else ""
