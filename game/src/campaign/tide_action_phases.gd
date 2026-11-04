class_name TideActionPhases
extends RefCounted
## Presentation-only phase selection. Never changes movement or skill lifetime.
var crystal_exit_left: float = 0.0

func on_animation_tag(tag: String) -> void:
	if tag == "crystal_dash:end": crystal_exit_left = 0.10
	elif tag.ends_with(":start"): crystal_exit_left = 0.0

func tick(dt: float, actor: TidePlayer) -> void:
	crystal_exit_left = maxf(0.0, crystal_exit_left-dt)
	if not actor.controls_enabled or actor.health<=0 or actor.skill_controller.active or actor.state_duration>0 or not is_zero_approx(actor.movement_axis()):
		crystal_exit_left = 0.0

func crystal_fraction(spec: Dictionary, controller: TideSkillController) -> float:
	var phases: Dictionary = spec.get("phases", {})
	var stage: String = "flight" if controller.active else ("exit" if crystal_exit_left>0.0 else "charge")
	var defaults: Dictionary = {"charge":[0.0,14.0/24.0],"flight":[14.0/24.0,23.0/24.0],"exit":[23.0/24.0,1.0]}
	var ends: Array = phases.get(stage, defaults[stage])
	var progress: float = controller.elapsed/maxf(controller.duration,0.01) if controller.active else controller.input.long_hold/0.6
	if stage == "exit": progress = 1.0-crystal_exit_left/0.10
	# Segment ends are exclusive frame boundaries, not the first frame of the next phase.
	var last: float = maxf(float(ends[0]), float(ends[1])-1.0/maxi(int(spec.frame_count),1))
	return lerpf(float(ends[0]),last,clampf(progress,0.0,1.0))
