class_name Hurtbox
extends Area2D

signal blocked(hit: HitData)

@export var health: Health
var immune: bool = false
var guard: int = 0


func allows_combo_link() -> bool:
	return true


func receive(hit: HitData) -> bool:
	if immune or health == null or health.current <= 0 or hit.damage <= 0:
		return false
	if guard > 0:
		guard -= 1
		blocked.emit(hit)
		return true
	return health.apply_hit(hit)
