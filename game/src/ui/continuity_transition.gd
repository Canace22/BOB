class_name XumenContinuityTransition
extends CanvasLayer
## Short scene-texture dissolve. It never replaces real room art or physics.
var plate: TextureRect
var elapsed: float = 0.0
var active: bool = false
const DURATION: float = 0.24

func _ready() -> void:
	layer=90
	process_mode=Node.PROCESS_MODE_PAUSABLE
	plate=TextureRect.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.hide()
	add_child(plate)

func _exit_tree() -> void:
	if is_instance_valid(plate):plate.texture=null
	active=false

func begin() -> void:
	if DisplayServer.get_name()=="headless": return
	var image: Image=get_viewport().get_texture().get_image()
	plate.texture=ImageTexture.create_from_image(image)
	plate.size=get_viewport().get_visible_rect().size
	plate.modulate=Color.WHITE
	plate.show()
	elapsed=0.0
	active=true

func _process(dt:float) -> void:
	if not active:return
	elapsed+=dt
	plate.modulate.a=1.0-smoothstep(0.0,DURATION,elapsed)
	if elapsed>=DURATION:
		active=false
		plate.hide()
		plate.texture=null
