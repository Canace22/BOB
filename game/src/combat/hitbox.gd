class_name Hitbox
extends Area2D
## One damage application per target for each activation, including multi-frame overlaps.

signal landed(target: Hurtbox, hit: HitData)

var active: bool = false
var hit: HitData
var _targets: Array[Hurtbox] = []


func activate(data: HitData) -> void:
	hit = data
	_targets.clear()
	active = true


func deactivate() -> void:
	active = false


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		if area is Hurtbox:
			try_hit(area as Hurtbox)


func try_hit(target: Hurtbox) -> bool:
	if not active or _targets.has(target) or not target.receive(hit):
		return false
	_targets.append(target)
	landed.emit(target, hit)
	EventBus.hit_landed.emit(target.global_position, hit.heavy)
	return true
