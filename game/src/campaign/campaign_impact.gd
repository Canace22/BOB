class_name CampaignImpact
extends Node
## Freeze-frame for hits and hurt. Counts physics ticks so fixed-fps tests stay deterministic.
const FROZEN_SCALE: float = 0.01 # Near zero; a true zero would hand delta=0 to every script.
var ticks_left: int = 0

func _init() -> void:
	# Keeps counting under a pause menu so the world never stays frozen.
	process_mode = Node.PROCESS_MODE_ALWAYS

func freeze(ticks: int) -> void:
	if ticks <= 0: return
	ticks_left = maxi(ticks_left, ticks)
	Engine.time_scale = FROZEN_SCALE

func _physics_process(_dt: float) -> void:
	if ticks_left <= 0: return
	ticks_left -= 1
	if ticks_left == 0: Engine.time_scale = 1.0

func _exit_tree() -> void:
	if ticks_left <= 0: return
	ticks_left = 0
	Engine.time_scale = 1.0
