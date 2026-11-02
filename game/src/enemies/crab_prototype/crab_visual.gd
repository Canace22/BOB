class_name CrabPrototypeVisual
extends Sprite2D
## Redrawn video key poses. Contact frames follow the damage clock.

const ROOT := "res://art/enemies/crab_video/"
const REFINED := "res://art/enemies/crab_video_v4/"
const ACTION_PATHS := {"01_idle": ROOT + "01_idle.png", "02_claw_slam": ROOT + "02_claw_slam.png",
	"04_sweep": REFINED + "sweep.png", "06_shell_shake": REFINED + "phase.png",
	"11_charge": REFINED + "charge.png", "10_walk": REFINED + "walk.png",
	"09_sink_fade": ROOT + "09_sink_fade.png"}
var sheets: Dictionary[String, Texture2D] = {}
var idle_clock := 0.0
var death_clock := 0.0
var action_id := "01_idle"
var frame_index := 0
var walk_distance := 0.0
var last_x := 0.0
var moving := false
@onready var boss: CrabPrototype = get_parent() as CrabPrototype


func _ready() -> void:
	for id: String in ACTION_PATHS:
		sheets[id] = load(ACTION_PATHS[id]) as Texture2D
	last_x = boss.global_position.x
	centered = false
	offset = Vector2(-512, -448)
	hframes = 4
	vframes = 3
	present(boss)


func _physics_process(delta: float) -> void:
	idle_clock += delta
	var distance := absf(boss.global_position.x - last_x)
	last_x = boss.global_position.x
	moving = boss.state == "observe" and distance > 0.01 and distance < 40
	if moving:
		walk_distance += distance
	death_clock = death_clock + delta if boss.state == "dead" else 0.0
	present(boss)


func reset() -> void:
	idle_clock = 0
	death_clock = 0
	walk_distance = 0
	last_x = boss.global_position.x
	moving = false
	modulate = Color.WHITE


func present(actor: CrabPrototype) -> void:
	if sheets.is_empty():
		return
	action_id = "01_idle"
	frame_index = int(idle_clock * 8) % 11
	if actor.state in ["tell", "active", "recover"]:
		action_id = "04_sweep" if actor.kind in ["sweep", "second"] else "02_claw_slam"
		if actor.kind == "charge":
			action_id = "11_charge"
		frame_index = attack_frame(actor)
	elif actor.state == "phase":
		action_id = "06_shell_shake"
		frame_index = mini(11, int(actor.timer / 0.8 * 12))
	elif actor.state == "dead":
		action_id = "09_sink_fade"
		frame_index = mini(11, int(death_clock * 8))
	elif moving:
		# One 120-world-pixel cycle. Blocked/stationary actors do not advance feet.
		action_id = "10_walk"
		frame_index = int(walk_distance / 10.0) % 12
	texture = sheets[action_id]
	frame = frame_index
	# Source faces left, so negative facing keeps positive scale.
	scale = Vector2(-actor.facing, 1.0)
	modulate = Color(1.35, 1.15, 0.95) if actor.flash > 0 else Color.WHITE
	if actor.state == "dead":
		modulate.a = clampf(1.0 - death_clock / 1.5, 0, 1)


func attack_frame(actor: CrabPrototype) -> int:
	var contact := 7 if actor.kind == "charge" else (4 if actor.kind in ["sweep", "second"] else 5)
	var elapsed := clampf(actor.timer / CrabMoves.value(actor.kind, actor.state), 0, 0.999)
	match actor.state:
		"tell": return mini(contact - 1, int(elapsed * contact))
		"active": return mini(7, contact + int(elapsed * (8 - contact)))
		_: return mini(11, 8 + int(elapsed * 4))
