class_name KitClamVisual
extends Sprite2D
## Authored frames follow the existing encounter clock; they never drive combat.

static func frame_for(state: String, timer: float, duration: float) -> int:
	var progress: float = clampf(timer / maxf(duration, 0.001), 0.0, 1.0)
	match state:
		"tell": return 1 + mini(3, int(progress * 4.0))
		"act": return 4
		"recover": return 5 + mini(2, int(progress * 3.0))
	return 0

func update_pose(state: String, timer: float, duration: float) -> void:
	frame = mini(hframes * vframes - 1, frame_for(state, timer, duration))
