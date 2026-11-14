class_name KitStateArt
extends Node2D
## Registered before/after paintings. Progress changes the picture, never the footing.
@export var required_flags: PackedStringArray = []
@export var fade_seconds: float = 0.45
@export var scan_reveal: bool = false
var host: Node
var mix: float = 0.0
var scan_left: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var candidate: Node = get_parent()
	while candidate != null:
		if "abilities" in candidate:
			host = candidate
			break
		candidate = candidate.get_parent()
	if scan_reveal: add_to_group("tide_scannable")
	mix = 1.0 if unlocked() else 0.0
	apply_mix()

func unlocked() -> bool:
	if not is_instance_valid(host) or required_flags.is_empty(): return false
	var flags: Dictionary = host.get("abilities")
	for flag: String in required_flags:
		if not bool(flags.get(flag, false)): return false
	return true

func reveal(_actor: Node2D) -> void:
	if scan_reveal: scan_left = 4.0

func _process(delta: float) -> void:
	scan_left = maxf(0.0, scan_left - delta)
	var target: float = 1.0 if unlocked() or scan_left > 0.0 else 0.0
	mix = move_toward(mix, target, delta / maxf(fade_seconds, 0.001))
	apply_mix()

func apply_mix() -> void:
	var before: CanvasItem = get_node_or_null("Before") as CanvasItem
	var after: CanvasItem = get_node_or_null("After") as CanvasItem
	if before != null: before.modulate.a = 1.0 - mix
	if after != null: after.modulate.a = mix
