class_name TideLocomotionVisual
extends RefCounted
## Select authored jump poses from actual motion, without delaying player control.
var air_time: float = 0.0
var fall_time: float = 0.0
var landing_left: float = 0.0
var airborne: bool = false
var previous_y: float = 0.0

func update(actor: TidePlayer, delta: float) -> void:
	var in_air: bool = not actor.is_on_floor()
	var locomotion: bool = actor.state_duration <= 0 and actor.animation_state in ["idle", "run", "jump_land"]
	if in_air:
		if not airborne or actor.velocity.y < previous_y - 100.0:
			air_time = 0.0
			fall_time = 0.0
		air_time += delta
		if actor.velocity.y > 20.0: fall_time += delta
		landing_left = 0.0
	elif airborne and previous_y > 80.0 and locomotion:
		landing_left = 0.20
	airborne = in_air
	previous_y = actor.velocity.y
	if not locomotion:
		landing_left = 0.0
		return
	if in_air:
		actor.display_action = "jump_land"
		# Rise extends the legs; the apex gathers them; descent opens for contact.
		actor.visual_frame = mini(16, 9 + int(air_time * 30.0)) if actor.velocity.y <= 20.0 else mini(24, 18 + int(fall_time * 24.0))
	elif landing_left > 0.0:
		actor.display_action = "jump_land"
		actor.visual_frame = mini(35, 26 + int((0.20 - landing_left) * 50.0))
		landing_left = maxf(0.0, landing_left - delta * (1.6 if absf(actor.velocity.x) > 20.0 else 1.0))
	elif actor.display_action == "jump_land":
		# The animation state may already be idle/run after the landing overlay.
		actor.display_action = actor.animation_state

func reset() -> void:
	air_time = 0.0
	fall_time = 0.0
	landing_left = 0.0
	airborne = false
	previous_y = 0.0
