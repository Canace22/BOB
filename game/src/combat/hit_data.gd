class_name HitData
extends Resource

@export var damage: int = 1
@export var heavy: bool = false
var origin: Vector2 = Vector2.ZERO


static func create(amount: int, at: Vector2, is_heavy: bool = false) -> HitData:
	var hit := HitData.new()
	hit.damage = amount
	hit.origin = at
	hit.heavy = is_heavy
	return hit
