class_name PlayerLocomotion
extends Node

var grounded_time: float = 0.0
var buffered_jump: float = 0.0


func step(player: Player, delta: float) -> void:
	var tuning := player.tuning
	grounded_time = tuning.coyote_time if player.is_on_floor() else maxf(0, grounded_time - delta)
	buffered_jump = maxf(0, buffered_jump - delta)
	if Input.is_action_just_pressed("jump"):
		buffered_jump = tuning.jump_buffer
	if player.is_on_floor():
		player.actions.air_dash = false
		if player.safe_floor():
			player.last_safe = player.position
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0 and player.actions.is_free():
		player.facing = signf(axis)
	if buffered_jump > 0 and grounded_time > 0 and player.actions.can_jump():
		player.velocity.y = -tuning.jump_speed
		grounded_time = 0
		buffered_jump = 0
		EventBus.sfx.emit("jump")
	if player.actions.mode == "dash":
		player.velocity = Vector2(player.facing * tuning.dash_distance / tuning.dash_duration, 0)
	else:
		player.velocity.y = minf(tuning.terminal_speed, player.velocity.y + tuning.gravity * delta)
		if player.actions.mode != "hurt":
			player.velocity.x = axis * tuning.move_speed
			if player.actions.mode == "heal":
				player.velocity.x = 0
			elif player.actions.mode == "attack":
				player.velocity.x *= 0.55
