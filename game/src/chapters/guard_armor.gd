class_name GuardArmor
extends Hurtbox

var last_blocked: bool = false


func allows_combo_link() -> bool:
	return not last_blocked


func receive(hit: HitData) -> bool:
	var actor := get_parent() as BurdenGuard
	last_blocked = false
	if immune or health.current <= 0 or hit.damage <= 0:
		return false
	if not GameState.has_flag("chapter.challenge"):
		return false
	var frontal := (hit.origin.x - actor.global_position.x) * actor.facing > -24.0
	if frontal and actor.state not in ["recover", "stagger"]:
		last_blocked = true
		actor.block_flash = 0.18
		blocked.emit(hit)
		EventBus.sfx.emit("sweep")
		return true
	return super.receive(hit)
