class_name ResonanceProjectile
extends Hitbox
## Authored resonance sprite; one target per projectile, finite travel, no save state.

const SPEED := 560.0
const RANGE := 650.0
var direction := 1.0
var traveled := 0.0


func _ready() -> void:
	landed.connect(_on_landed)
	var data := HitData.create(12, global_position)
	data.ranged = true
	activate(data)


func _physics_process(delta: float) -> void:
	if not active:
		return
	var movement := Vector2(direction * SPEED * delta, 0)
	var ray := PhysicsRayQueryParameters2D.create(global_position, global_position + movement, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		deactivate()
		queue_free()
		return
	position += movement
	traveled += movement.length()
	if traveled >= RANGE:
		deactivate()
		queue_free()
		return
	super._physics_process(delta)


func _on_landed(_target: Hurtbox, _hit: HitData) -> void:
	deactivate()
	queue_free()
