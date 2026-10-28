class_name CrabPrototypeVisual
extends Sprite2D
## Key poses are authored bitmaps, not procedural animation.

@export var poses: Dictionary[String, Texture2D] = {}
@export var pose_scale := 0.6


func present(boss: CrabPrototype) -> void:
	var key := pose_key(boss)
	if poses.has(key):
		texture = poses[key]
	elif poses.has("idle"):
		texture = poses["idle"]
	scale = Vector2(boss.facing * pose_scale, pose_scale)
	modulate = Color(1.8, 1.3, 0.9) if boss.flash > 0 else Color.WHITE
	if boss.state == "dead":
		modulate = Color(0.55, 0.6, 0.6, 0.65)


func pose_key(boss: CrabPrototype) -> String:
	if boss.state in ["tell", "active"]:
		var attack := "sweep" if boss.kind == "second" else boss.kind
		return attack + "_" + boss.state
	if boss.state in ["phase", "recover", "dead"]:
		return boss.state
	return "idle"
