class_name Health
extends Node

signal damaged(hit: HitData)
signal died

@export var maximum: int = 4
var current: int = 4


func _ready() -> void:
	current = maximum


func apply_hit(hit: HitData) -> bool:
	if current <= 0 or hit.damage <= 0:
		return false
	current = maxi(0, current - hit.damage)
	damaged.emit(hit)
	if current == 0:
		died.emit()
	return true


func restore(amount: int = -1) -> void:
	current = maximum if amount < 0 else clampi(amount, 0, maximum)
