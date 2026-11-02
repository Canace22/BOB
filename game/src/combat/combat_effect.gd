class_name CombatEffect
extends Sprite2D
## Authored four-pose strips. A finite one-shot clock inherits world pause/hitstop.

const ROOT := "res://art/fx/combo-v1/"
static var strips: Dictionary[String, Texture2D] = {}
var age := 0.0
var duration := 0.24
var effect_id := ""
var opacity := 0.7


func _init() -> void:
	hframes = 4
	visible = false
	z_as_relative = false
	z_index = 1


static func warm() -> void:
	if strips.is_empty():
		for id: String in ["short1", "short2", "heavy", "hit", "sweep", "slam", "charge", "resonance"]:
			strips[id] = load(ROOT + id + ".png") as Texture2D


func play(id: String, at: Vector2, width: float, seconds: float, alpha: float = 0.7, facing: float = 1) -> void:
	effect_id = id
	warm()
	texture = strips[id]
	duration = maxf(seconds, 0.01)
	age = 0
	frame = 0
	opacity = alpha
	modulate.a = alpha
	scale = Vector2.ONE * width / (texture.get_width() / 4.0)
	flip_h = facing < 0
	global_position = at
	show()


func advance(delta: float) -> void:
	if not visible:
		return
	age += delta
	frame = mini(3, int(age / duration * 4))
	modulate.a = opacity * clampf((duration - age) / (duration * 0.3), 0, 1)
	if age >= duration:
		hide()


func reset() -> void:
	hide()
	age = 0
	effect_id = ""


func snapshot() -> Dictionary:
	return {"id": effect_id, "visible": visible, "frame": frame, "age": age,
		"alpha": modulate.a, "x": global_position.x, "y": global_position.y,
		"file": texture.resource_path if texture != null else "", "z": z_index}


static func contact_point(target: Hurtbox, from: Vector2) -> Vector2:
	var collision := target.get_node_or_null("Shape") as CollisionShape2D
	if collision == null or collision.shape == null:
		return target.global_position
	var rect := collision.shape.get_rect()
	var local := collision.to_local(from)
	return collision.to_global(Vector2(clampf(local.x, rect.position.x, rect.end.x),
		clampf(local.y, rect.position.y, rect.end.y)))
