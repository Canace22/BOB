class_name CampaignCrabShell
extends RefCounted
## Preserve training damage ratios; campaign base damage 1 maps to training 10.
var crab: Node2D
var last_result := ""
var last_damage := 0
var feedback_left := 0.0

func braced() -> bool:
	return crab.state in ["observe", "phase", "tell", "active"]

func counter_window() -> bool:
	return crab.state == "tell" and crab.kind == "slam" and crab.stagger_cooldown <= 0 and crab.timer >= CampaignCrabMoves.value("slam", "tell")-0.62

func receive(amount: int, heavy: bool, ranged: bool) -> void:
	var counter := heavy and not ranged and counter_window()
	var guarded := braced() and not counter
	last_damage = maxi(1,floori(amount*(0.5 if heavy else 0.25))) if guarded else amount
	last_damage = mini(int(crab.data.hp),last_damage)
	last_result = "shell" if guarded else "exposed"
	feedback_left = 0.6
	crab.flash = 0.12
	crab.host.damage_enemy(crab.data,last_damage)
	if not guarded:
		var previous: String = crab.state
		crab.exposed_hit(heavy,ranged,counter)
		if crab.state == "stagger" and previous != "stagger": last_result = "break"
	crab.host.sfx("strike" if guarded else ("heavy" if last_result == "break" else "hit"))
