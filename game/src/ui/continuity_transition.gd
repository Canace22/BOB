class_name XumenContinuityTransition
extends CanvasLayer
## Screen fade is UI; scenery remains authored bitmap assets.
var plate: ColorRect
var active: bool = false
const FADE_OUT: float = 0.20
const FADE_IN: float = 0.25
const BLACK_HOLD: float = 0.08

func _ready() -> void:
	layer = 110 # Cover the HUD too, including a paused death menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	plate = ColorRect.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.color = Color.BLACK
	plate.modulate.a = 0.0
	plate.hide()
	add_child(plate)

func fade_out(duration: float = FADE_OUT, hold: float = BLACK_HOLD) -> void:
	active = true
	plate.size = get_viewport().get_visible_rect().size
	plate.show()
	var tween: Tween = create_tween()
	tween.tween_property(plate, "modulate:a", 1.0, duration)
	await tween.finished
	# Let the fully black frame reach the screen before synchronous room loading.
	await get_tree().create_timer(hold, true).timeout

func fade_in(duration: float = FADE_IN) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(plate, "modulate:a", 0.0, duration)
	await tween.finished
	plate.hide()
	active = false

func begin() -> void:
	await fade_out()
	await fade_in()
