@warning_ignore_start("untyped_declaration")
class_name WhalebellyFishSchoolV01
extends Node2D
## Baked bitmap swim + editable school choreography, one clock for pause/replay.
@export_range(0, 2) var species: int = 0
@export var reference_layout: bool = true
@export var autoplay: bool = true
@export var speed: float = 1.0
var elapsed: float = 0.0
var members: Array = []
var sprites: Array[Sprite2D] = []
const IDS = ["silverfin", "tealback", "lantern"]

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/fish_schools/manifest.json"))
	members = data.members[species]
	var texture: Texture2D = load("res://art/whalebelly/fish_schools/%s/swim_atlas.png" % IDS[species])
	for member: Dictionary in members:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.hframes = 8
		sprite.vframes = 4
		sprite.name = "Fish%02d" % int(member.i)
		add_child(sprite)
		sprites.append(sprite)
	update_at(0.0)

func _process(delta: float) -> void:
	if autoplay:
		elapsed += delta * speed
		update_at(elapsed)

func update_at(time: float, pan: Vector2 = Vector2.ZERO) -> void:
	elapsed = time
	var q: float = time / 16.0 * TAU
	for i in sprites.size():
		var m: Dictionary = members[i]
		var x: float
		var y: float
		var vx: float
		var vy: float
		if species == 0:
			x = -390.0 + 2060.0 * fposmod(time / 16.0, 1.0) + float(m.ox)
			y = 360.0 + float(m.oy) + 12.0 * sin(q * 2.0 + float(m.phase) * TAU)
			vx = 129.0
			vy = 9.0 * cos(q * 2.0 + float(m.phase) * TAU)
		elif species == 1:
			var pulse: float = 1.0 + 0.12 * sin(q * 2.0)
			x = 640.0 + 155.0 * sin(q) + float(m.ox) * pulse
			y = 360.0 + 40.0 * sin(q * 2.0) + float(m.oy) * pulse
			vx = 61.0 * cos(q) + float(m.ox) * 0.12 * 2.0 * TAU / 16.0 * cos(q * 2.0)
			vy = 31.0 * cos(q * 2.0)
		else:
			var a: float = q - float(m.i) * 0.105
			var lane: float = float(int(m.i) % 3 - 1) * 17.0
			x = 640.0 + (320.0 + lane) * sin(a)
			y = 360.0 + (110.0 + lane * 0.45) * cos(a)
			vx = (320.0 + lane) * cos(a)
			vy = -(110.0 + lane * 0.45) * sin(a)
		var fish_size: float = float(m.size)
		if reference_layout:
			x = 640.0 + (x - 640.0) * 0.58
			y = [295.0, 543.0, 460.0][species] + (y - 360.0) * 0.38
			if species == 2:
				x += 300.0
				y -= 110.0
			fish_size *= 0.65
		else:
			y = [175.0, 370.0, 575.0][species] + (y - 360.0) * 0.65
		var yaw: float = vx / sqrt(vx * vx + vy * vy + 1.0)
		var sprite: Sprite2D = sprites[i]
		sprite.position = Vector2(x, y) + pan * 0.045
		sprite.rotation = atan2(vy, absf(vx) + 1.0) * 0.30
		sprite.scale = Vector2((-1.0 if vx < 0.0 else 1.0) * (0.12 + 0.88 * absf(yaw)), 1.0) * fish_size / 272.0
		sprite.frame = int(floor(fposmod(time * float(m.cycles) / 16.0 + float(m.phase), 1.0) * 32.0))
		var edge_fade: float = 1.0
		if species == 0 and reference_layout:
			var loop_time: float = fposmod(time, 16.0)
			edge_fade = smoothstep(0.0, 1.5, minf(loop_time, 16.0 - loop_time))
		sprite.modulate = Color(0.83, 0.93, 1.0, float(m.depth) * (0.68 if reference_layout else 1.0) * edge_fade)
