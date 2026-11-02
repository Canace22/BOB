class_name CrabShell
extends Hurtbox
## The shell braces throughout an attack. The raised claw is briefly vulnerable.

var glances := 0
var connected := false
@onready var crab: CrabPrototype = get_parent() as CrabPrototype


func _ready() -> void:
	health.damaged.connect(_on_damage)


func _on_damage(hit: HitData) -> void:
	crab.flash = 0.12
	var counter := counters(hit)
	if braced() and not counter:
		EventBus.sfx.emit("strike")
		return
	EventBus.sfx.emit("heavy" if counter else "hit")
	crab.register_exposed_hit(hit, counter)


func braced() -> bool:
	return crab.state in ["observe", "phase", "tell", "active"] or (crab.state == "recover" and connected)


func begin_round() -> void:
	glances = 0
	connected = false


func mark_contact(_target: Hurtbox, _hit: HitData) -> void:
	connected = true


func counter_window() -> bool:
	return crab.state == "tell" and crab.kind == "slam" and crab.stagger_cooldown <= 0 and crab.timer >= CrabMoves.value("slam", "tell") - 0.62


func counters(hit: HitData) -> bool:
	return hit.heavy and not hit.ranged and counter_window()


func receive(hit: HitData) -> bool:
	if not braced() or counters(hit) or hit.damage <= 0:
		return super.receive(hit)
	var glance := hit.duplicate() as HitData
	glance.origin = hit.origin
	glance.damage = maxi(1, floori(hit.damage * (0.5 if hit.heavy else 0.25)))
	var landed := super.receive(glance)
	if landed and crab.state in ["tell", "active"] and not hit.ranged and crab.sequence.size() == 1:
		glances += 1
		if glances == 2:
			crab.sequence.append("second")
			crab.combo_planned = true
	return landed
