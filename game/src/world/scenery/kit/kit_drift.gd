class_name KitDriftField
extends Node2D
## Bounded pool of one library bitmap drifting with wrap-around: fat motes,
## current streaks. Deterministic per seed; pauses with its room.
@export var texture: Texture2D
@export var bounds: Rect2 = Rect2(0, 0, 400, 300)
@export var population: int = 24
@export var velocity: Vector2 = Vector2(6, 10)
@export var sway: float = 8.0
@export var size_range: Vector2 = Vector2(6, 16) # longest side in pixels
@export_range(0.0, 1.0) var opacity: float = 0.4
@export var tint: Color = Color.WHITE
@export var turn_degrees: float = 0.0
@export var seed_id: int = 1
var time: float = 0.0
var motes: Array[Dictionary] = []

func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_id * 7919 + 13
	for i: int in population:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * random.randf_range(size_range.x, size_range.y) / maxf(float(texture.get_width()), 1.0)
		sprite.rotation_degrees = turn_degrees
		add_child(sprite)
		motes.append({"node":sprite, "origin":Vector2(random.randf() * bounds.size.x, random.randf() * bounds.size.y), "speed":random.randf_range(0.6, 1.4), "phase":random.randf() * TAU, "alpha":random.randf_range(0.5, 1.0)})
	update_at(0.0)

func _process(delta: float) -> void:
	update_at(time + delta)

func update_at(t: float) -> void:
	time = t
	for mote: Dictionary in motes:
		var travelled: Vector2 = mote.origin + velocity * float(mote.speed) * t
		var local := Vector2(fposmod(travelled.x, bounds.size.x) + sin(t * 0.5 + float(mote.phase)) * sway, fposmod(travelled.y, bounds.size.y))
		# Fade at the field edge so wrap-around never pops.
		var edge: float = minf(minf(local.x, bounds.size.x - local.x), minf(local.y, bounds.size.y - local.y))
		mote.node.position = bounds.position + local
		mote.node.modulate = Color(tint, smoothstep(0.0, 40.0, edge) * opacity * float(mote.alpha))
