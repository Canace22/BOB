class_name CampaignCrabDriver
extends RefCounted
## Read gameplay state; drive ordinary Input actions, never change HP or positions.

static func fight(host: WhalebellyMain, budget: int = 9000) -> bool:
	var enemy: Dictionary = host.enemies[0]
	var initial_player: int = host.player.get_instance_id()
	var jump_left := 0
	for frame: int in range(budget):
		if not enemy.alive:
			release()
			return true
		if host.player.get_instance_id() != initial_player or host.player.health <= 0:
			release()
			return false
		var crab: CampaignCrabBoss = enemy.actor
		var p: WhalebellyCampaignPlayer = host.player
		var direction: float = signf(crab.position.x-p.position.x)
		var gap: float = absf(crab.position.x-p.position.x)
		Input.action_release("tp_left")
		Input.action_release("tp_right")
		var retreat: bool = crab.kind in ["slam","charge"] and crab.state in ["tell","active"]
		var desired: float = 440 if crab.kind == "charge" else 345
		if retreat and gap < desired and p.position.x > 292:
			Input.action_press("tp_left" if direction > 0 else "tp_right")
		elif not retreat and gap > 210:
			Input.action_press("tp_right" if direction > 0 else "tp_left")
		elif p.facing != direction:
			Input.action_press("tp_right" if direction > 0 else "tp_left")
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0: Input.action_release("tp_jump")
		if crab.kind in ["sweep","second"] and crab.state == "tell" and crab.timer > 0.38 and p.is_on_floor() and jump_left == 0:
			Input.action_press("tp_jump")
			jump_left = 35
		var opening: bool = crab.state in ["recover","stagger"]
		if opening and gap < 265 and frame % 25 == 0: Input.action_press("tp_attack")
		if frame % 25 == 2: Input.action_release("tp_attack")
		if opening and gap < 450 and frame % 90 == 4 and p.soul >= 33: Input.action_press("tp_orb")
		if frame % 90 == 6: Input.action_release("tp_orb")
		await host.get_tree().physics_frame
	release()
	return false

static func release() -> void:
	for action: String in ["tp_left","tp_right","tp_jump","tp_attack","tp_orb"]:
		Input.action_release(action)
