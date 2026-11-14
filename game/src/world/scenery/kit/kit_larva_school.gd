class_name KitLarvaSchool
extends Node2D
## Authored swimming poses plus a separate, bounded environmental route.
## No collision, health or quest state: ending is read from the real host.
@export var texture: Texture2D
@export var columns: int = 4
@export var rows: int = 2
@export_range(1, 32) var population: int = 6
@export var bounds: Rect2 = Rect2(0, -90, 720, 180)
@export var seed_id: int = 1
@export var body_width: float = 90.0
@export var frame_seconds: float = 0.12
var elapsed: float = 0.0
var released: bool = false
var mode_started: float = 0.0
var members: Array[Dictionary] = []
var progress_host: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if texture == null: return
	var random := RandomNumberGenerator.new()
	random.seed = seed_id * 4513 + 19
	var cell_width: float = float(texture.get_width()) / maxi(columns, 1)
	for i: int in population:
		var sprite := Sprite2D.new()
		sprite.name = "Larva" + str(i + 1)
		sprite.texture = texture
		sprite.hframes = maxi(columns, 1)
		sprite.vframes = maxi(rows, 1)
		sprite.scale = Vector2.ONE * body_width / cell_width * random.randf_range(0.72, 1.04)
		add_child(sprite)
		var phase: float = random.randf() * TAU
		var home := bounds.position + Vector2(bounds.size.x * random.randf_range(0.16, 0.22), bounds.size.y * random.randf_range(0.35, 0.65))
		var member: Dictionary = {"node":sprite, "home":home, "center":home, "phase":phase,
			"radius":Vector2(minf(bounds.size.x * 0.075, 38.0), minf(bounds.size.y * 0.14, 22.0)),
			"pace":random.randf_range(0.75, 1.15), "frame_phase":random.randi_range(0, sprite.hframes * sprite.vframes - 1),
			"lane":bounds.position.y + bounds.size.y * random.randf_range(0.32, 0.68)}
		sprite.position = home + orbit_offset(member, 0.0)
		member.origin = sprite.position
		members.append(member)
	released = ending_unlocked()
	update_at(0.0)

func _process(delta: float) -> void:
	update_at(elapsed + delta)

func orbit_offset(member: Dictionary, time: float) -> Vector2:
	var phase: float = float(member.phase)
	var angle: float = time * 0.45 * float(member.pace) + phase
	return Vector2(cos(angle), sin(angle * 0.8 + phase)) * Vector2(member.radius)

func update_at(time: float) -> void:
	var next_time: float = maxf(time, 0.0)
	if next_time < elapsed:
		mode_started = 0.0
		for member: Dictionary in members:
			member.center = member.home
			member.origin = Vector2(member.home) + orbit_offset(member, 0.0)
	var next_mode: bool = ending_unlocked()
	if next_mode != released:
		mode_started = elapsed
		for member: Dictionary in members:
			member.origin = member.node.position
			member.center = Vector2(member.node.position) - orbit_offset(member, elapsed)
		released = next_mode
	elapsed = next_time
	var age: float = maxf(0.0, elapsed - mode_started)
	for member: Dictionary in members:
		var sprite: Sprite2D = member.node
		var before: Vector2 = sprite.position
		var alpha: float = 0.8
		if released:
			# Integrate a smooth acceleration from the current position. A flag
			# change at zero elapsed time cannot teleport any visible individual.
			var speed: float = maxf(20.0, body_width * 0.48) * float(member.pace)
			var distance: float = speed * (age - 0.8 * (1.0 - exp(-age / 0.8)))
			var x: float = fposmod(float(member.origin.x) - bounds.position.x + distance, maxf(bounds.size.x, 1.0))
			var y: float = lerpf(float(member.origin.y), float(member.lane), smoothstep(0.0, 2.0, age))
			y += (sin(age * 1.2 + float(member.phase)) - sin(float(member.phase))) * 3.0
			sprite.position = Vector2(bounds.position.x + x, y)
			var margin: float = minf(maxf(bounds.size.x * 0.12, 1.0), 60.0)
			var edge_alpha: float = smoothstep(0.0, margin, minf(x, bounds.size.x - x))
			alpha *= lerpf(1.0, edge_alpha, smoothstep(0.0, 0.8, age))
		else:
			sprite.position = Vector2(member.center) + orbit_offset(member, elapsed)
		# Body action cycles are independent of global path speed and progress.
		sprite.frame = (int(elapsed / maxf(frame_seconds, 0.01)) + int(member.frame_phase)) % (sprite.hframes * sprite.vframes)
		var dx: float = sprite.position.x - before.x
		if released: sprite.flip_h = false # right-facing authored source, even on an invisible wrap
		elif absf(dx) > 0.001: sprite.flip_h = dx < 0.0
		sprite.modulate.a = alpha

func ending_unlocked() -> bool:
	if not is_instance_valid(progress_host):
		var candidate: Node = get_parent()
		while candidate != null:
			if "abilities" in candidate:
				progress_host = candidate
				break
			candidate = candidate.get_parent()
	if not is_instance_valid(progress_host): return false
	var flags: Variant = progress_host.get("abilities")
	return flags is Dictionary and bool(flags.get("ending", false))

func snapshot() -> Dictionary:
	return {"population":members.size(), "released":released, "elapsed":elapsed, "bounds":bounds}
