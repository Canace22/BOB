class_name CrabShell
extends Hurtbox
## The shell braces throughout an attack. The raised claw is briefly vulnerable.

signal resolved(result: String, hit: HitData)

var last_result := ""
var last_damage := 0
var feedback_left := 0.0
@onready var crab: CrabPrototype = get_parent() as CrabPrototype


func _ready() -> void:
	health.damaged.connect(_on_damage)


func _on_damage(hit: HitData) -> void:
	crab.flash = 0.12
	var counter := counters(hit)
	last_damage = hit.damage
	feedback_left = 0.6
	if braced() and not counter:
		last_result = "shell"
		EventBus.sfx.emit("strike")
	else:
		var was_staggered := crab.state == "stagger"
		crab.register_exposed_hit(hit, counter)
		last_result = "break" if crab.state == "stagger" and not was_staggered else "exposed"
		EventBus.sfx.emit("heavy" if last_result == "break" else "hit")
	resolved.emit(last_result, hit)


func _physics_process(delta: float) -> void:
	feedback_left = maxf(0, feedback_left - delta)


func braced() -> bool:
	return crab.state in ["observe", "phase", "tell", "active"]


func allows_combo_link() -> bool:
	return last_result != "shell"


func reset_feedback() -> void:
	last_result = ""
	last_damage = 0
	feedback_left = 0


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
	return super.receive(glance)
