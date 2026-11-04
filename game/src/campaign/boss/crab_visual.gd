class_name CampaignCrabVisual
extends Sprite2D
## Redrawn video key poses. Contact frames follow the damage clock.

const ROOT := "res://art/enemies/crab_video/"
const REFINED := "res://art/enemies/crab_video_v4/"
const ACTION_PATHS := {"01_idle": ROOT + "01_idle.png", "02_claw_slam": ROOT + "02_claw_slam.png",
	"04_sweep": REFINED + "sweep.png", "06_shell_shake": REFINED + "phase.png",
	"11_charge": REFINED + "charge.png", "10_walk": REFINED + "walk.png",
	"09_sink_fade": ROOT + "09_sink_fade.png"}
var sheets: Dictionary[String, Texture2D] = {}
var death_clock := 0.0
var action_id := "01_idle"
var frame_index := 0
var walk_distance := 0.0
var last_x := 0.0
var moving := false
@onready var boss: Node2D = get_parent() as Node2D


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
	var distance := absf(boss.global_position.x - last_x)
	last_x = boss.global_position.x
	moving = boss.state == "observe" and distance > 0.01 and distance < 40
	if moving:
		walk_distance += distance
	death_clock = death_clock + delta if boss.state == "dead" else 0.0
	present(boss)


func reset() -> void:
	death_clock = 0
	walk_distance = 0
	last_x = boss.global_position.x
	moving = false
	modulate = Color.WHITE


func present(actor: Node2D) -> void:
	if sheets.is_empty():
		return
	action_id = "01_idle"
	# Current idle redraws change anatomy/texture between cells; hold the accepted pose.
	frame_index = 0
	if actor.state in ["tell", "active", "recover"]:
		action_id = "04_sweep" if actor.kind in ["sweep", "second"] else "02_claw_slam"
		if actor.kind == "charge":
			action_id = "11_charge"
		frame_index = attack_frame(actor)
	elif actor.state == "phase":
		action_id = "06_shell_shake"
		frame_index = mini(11, int(actor.timer / CampaignCrabMoves.PHASE_TIME * 12))
	elif actor.state == "stagger":
		action_id = "02_claw_slam"
		frame_index = 8
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
	if actor.hurtbox != null and actor.hurtbox.counter_window():
		modulate = Color(1.38, 1.22, 0.85)
	elif actor.flash > 0 and actor.hurtbox.last_result == "shell":
		modulate = Color(0.65, 0.85, 1.3)
	elif actor.state == "recover" and actor.flash <= 0:
		modulate = Color(1.18, 1.12, 0.96)
	elif actor.hurtbox != null and actor.hurtbox.braced() and actor.flash <= 0:
		modulate = Color(0.76, 0.86, 0.94)
	if actor.state == "dead":
		modulate.a = clampf(1.0 - death_clock / 1.5, 0, 1)


func attack_frame(actor: Node2D) -> int:
	if actor.state == "recover" and actor.kind in ["sweep", "second"]:
		# Retract for 0.18s, then hold the authored open-claw pose until recovery ends.
		return 8 + mini(2, int(actor.timer / 0.09))
	var contact := 7 if actor.kind == "charge" else (4 if actor.kind in ["sweep", "second"] else 5)
	var elapsed := clampf(actor.timer / CampaignCrabMoves.value(actor.kind, actor.state), 0, 0.999)
	match actor.state:
		"tell": return mini(contact - 1, int(elapsed * contact))
		"active": return mini(7, contact + int(elapsed * (8 - contact)))
		_: return mini(11, 8 + int(elapsed * 4))
