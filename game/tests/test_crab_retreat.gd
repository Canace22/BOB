extends TestSuite


func make_boss() -> CrabPrototype:
	var arena := add((load("res://src/prototype/crab_arena.tscn") as PackedScene).instantiate()) as CrabArena
	var boss := arena.boss
	boss.set_physics_process(false)
	boss.begin()
	boss.phase = 2
	boss.target.position.x = 1200
	return boss


func test_first_retreat_has_two_full_tells_and_is_spent_once() -> void:
	var boss := make_boss()
	boss.cooldowns.charge = 5.0
	boss.target.velocity.x = -100
	boss.step_ai(0.4)
	eq(boss.sequence, ["charge", "sweep"], "first retreat takes priority over inherited cooldown")
	eq(boss.state, "tell", "charge starts with its normal warning")
	boss.step_ai(1.36)
	eq(boss.kind, "charge", "the shell moves first")
	boss.step_ai(0.61)
	eq(boss.kind, "sweep", "the low claw follows the shell")
	eq(boss.state, "tell", "the follow-up gives its full warning")
	boss.step_ai(0.80)
	check(not boss.hitbox.active, "no sweep damage before its contact pose")
	boss.step_ai(0.06)
	check(boss.hitbox.active, "the low claw can land")
	boss.step_ai(0.19)
	boss.step_ai(CrabMoves.value("sweep", "recover") + 0.01)
	boss.step_ai(5.1)
	eq(boss.sequence, ["charge"], "later phase-two charges are single attacks")


func test_retreat_requires_player_movement_and_room_to_escape() -> void:
	var boss := make_boss()
	boss.cooldowns.charge = 5.0
	boss.step_ai(0.4)
	eq(boss.state, "observe", "approaching a stationary player does not arm the combo")
	boss.target.actions.change("hurt")
	boss.target.velocity.x = -100
	boss.step_ai(0.4)
	eq(boss.state, "observe", "knockback is not a voluntary retreat")
	boss.target.actions.change("idle")
	boss.position.x = 1230
	boss.target.position.x = 910
	boss.step_ai(0.4)
	eq(boss.state, "observe", "corner has too little escape space")
	boss.reset_at(Vector2(1520, 893))
	boss.begin()
	boss.target.position.x = 1200
	boss.step_ai(0.4)
	eq(boss.sequence, ["charge"], "phase one still uses a single charge")
	boss.phase = 2
	boss.change("recover")
	boss.step_ai(0.5)
	boss.target.velocity.x = 0
	boss.step_ai(1.01)
	boss.step_ai(0.4)
	eq(boss.sequence, ["charge", "sweep"], "retreat during recovery is remembered when the player stops")
	boss.reset_at(Vector2(1520, 893))
	eq(boss.retreat_combo, CrabMoves.RetreatCombo.WAITING, "retry restores the one-time opportunity")
