class_name CorpseCrabVisual
extends Sprite2D
## Authored bitmap poses; the actor owns timing and world movement.

const CONFIG := "res://art/enemies/corpse_crab/animations.json"
const SHEETS := {"attack":preload("res://art/enemies/corpse_crab/attack.png"),
	"walk":preload("res://art/enemies/corpse_crab/walk.png"),
	"life":preload("res://art/enemies/corpse_crab/life.png")}
var clips: Dictionary = {}
var action_id := "idle"
var frame_index := 0

func _ready() -> void:
	clips = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)).clips
	centered = false
	offset = Vector2(-144,-224)
	hframes = 4
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	present(get_parent())

func present(actor: Node2D) -> void:
	if clips.is_empty(): return
	action_id = actor.state
	if action_id == "idle" and actor.moving: action_id = "walk"
	var spec: Dictionary = clips[action_id]
	var ids: Array = spec.frames
	var cursor := 0
	if action_id == "walk":
		cursor = int(actor.walk_distance / float(spec.stride_pixels) * ids.size()) % ids.size()
	elif action_id == "idle":
		cursor = int(actor.idle_clock * float(spec.fps)) % ids.size()
	elif action_id == "recover":
		cursor = 0 if actor.timer < 0.14 else 1
	else:
		cursor = mini(ids.size()-1,int(actor.timer / float(spec.duration) * ids.size()))
	frame_index = int(ids[cursor])
	texture = SHEETS[spec.sheet]
	frame = frame_index
	scale = Vector2(-actor.facing*.82,.82)
	modulate = Color(1.18,1.08,1) if actor.flash > 0 else Color.WHITE
	if actor.state == "dead": modulate.a = clampf((1.8-actor.timer)/.6,0,1)
