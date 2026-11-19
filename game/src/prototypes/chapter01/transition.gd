class_name Chapter01Transition
extends Control
## 旧房间用视口快照，下一房间保持真实渲染，输入在整个转场中冻结。

var frame: TextureRect
var curtain: ColorRect
var active := false
var last_kind := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame = TextureRect.new()
	frame.size = Vector2(1280, 720)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = false
	add_child(frame)
	curtain = ColorRect.new()
	curtain.size = Vector2(1280, 720)
	curtain.color = Color("07141b")
	curtain.modulate.a = 0.0
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(curtain)


func play(view: SubViewportContainer, change: Callable, direction: String) -> void:
	active = true
	last_kind = "推镜" if direction in ["left", "right"] else "井道暗场"
	if DisplayServer.get_name() == "headless":
		change.call()
		await get_tree().process_frame
	elif direction in ["left", "right"]:
		await RenderingServer.frame_post_draw
		var viewport := view.get_child(0) as SubViewport
		frame.texture = ImageTexture.create_from_image(viewport.get_texture().get_image())
		frame.position = Vector2.ZERO
		frame.visible = true
		var distance := Vector2(1280 if direction == "right" else -1280, 0)
		view.position = distance
		change.call()
		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(frame, "position", -distance, 0.62)
		tween.tween_property(view, "position", Vector2.ZERO, 0.62)
		await tween.finished
		frame.visible = false
		frame.texture = null
	else:
		var close := create_tween()
		close.tween_property(curtain, "modulate:a", 1.0, 0.24)
		await close.finished
		change.call()
		await get_tree().create_timer(0.12).timeout
		var open := create_tween()
		open.tween_property(curtain, "modulate:a", 0.0, 0.34)
		await open.finished
	active = false
