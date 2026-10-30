class_name CrabPrototypeVisual
extends Sprite2D
## Redrawn video key poses. Contact frames follow the damage clock.

const ROOT := "res://art/enemies/crab_video/"
const ACTIONS := ["01_idle", "02_claw_slam", "04_sweep", "06_shell_shake",
	"07_body_slam", "08_retreat", "09_sink_fade"]
var sheets: Dictionary[String, Texture2D] = {}
var idle_clock := 0.0
var death_clock := 0.0
var action_id := "01_idle"
var frame_index := 0
@onready var boss: CrabPrototype = get_parent() as CrabPrototype


func _ready() -> void:
	for id: String in ACTIONS:
		sheets[id] = load(ROOT + id + ".png") as Texture2D
	centered = false
	offset = Vector2(-512, -448)
	hframes = 4
	vframes = 3
	present(boss)


func _physics_process(delta: float) -> void:
	idle_clock += delta
	death_clock = death_clock + delta if boss.state == "dead" else 0.0
	present(boss)


func reset() -> void:
	idle_clock = 0
	death_clock = 0
	modulate = Color.WHITE


func present(actor: CrabPrototype) -> void:
	if sheets.is_empty():
		return
	action_id = "01_idle"
	frame_index = int(idle_clock * 8) % 11
	if actor.state in ["tell", "active", "recover"]:
		action_id = "04_sweep" if actor.kind in ["sweep", "second"] else "02_claw_slam"
		if actor.kind == "charge":
			action_id = "07_body_slam"
		frame_index = attack_frame(actor)
	elif actor.state == "phase":
		action_id = "06_shell_shake"
		frame_index = mini(11, int(actor.timer / 0.8 * 12))
	elif actor.state == "dead":
		action_id = "09_sink_fade"
		frame_index = mini(11, int(death_clock * 8))
	elif absf(actor.velocity.x) > 1:
		# Existing stepping poses; not a newly authored forward walk cycle.
		action_id = "08_retreat"
		frame_index = int(idle_clock * 10) % 12
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
