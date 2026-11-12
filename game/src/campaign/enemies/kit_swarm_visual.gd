class_name KitSwarmVisual
extends Node2D
## A cluster of one library bitmap: every member keeps its own wiggle, the group is moved by its owner.
var texture: Texture2D
var count: int = 16
var spread: Vector2 = Vector2(70, 40)
var member_scale: float = 1.0
var stretch: float = 1.0 # >1 draws the cluster out along its travel
var facing: float = -1.0 # the source bitmap looks left
var time: float = 0.0
var members: Array[Dictionary] = []

func build(seed_id: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_id * 4513 + 7
	for i: int in count:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * member_scale * random.randf_range(0.7, 1.15)
		add_child(sprite)
		var angle: float = random.randf() * TAU
		members.append({"node":sprite, "offset":Vector2(cos(angle), sin(angle)) * sqrt(random.randf()), "phase":random.randf() * TAU})

func _process(dt: float) -> void:
	time += dt
	for member: Dictionary in members:
		var phase: float = member.phase
		var sprite: Sprite2D = member.node
		sprite.position = Vector2(member.offset) * spread * Vector2(stretch, 1.0 / sqrt(stretch)) + Vector2(cos(time * 3.0 + phase) * 6.0, sin(time * 4.3 + phase) * 5.0)
		sprite.flip_h = facing > 0.0
		sprite.rotation = sin(time * 5.0 + phase) * 0.12
