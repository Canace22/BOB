class_name Hurtbox
extends Area2D

@export var health: Health
var immune: bool = false


func receive(hit: HitData) -> bool:
	return not immune and health != null and health.apply_hit(hit)
