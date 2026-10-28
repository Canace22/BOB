extends Node2D
## Independent far layer. Coordinates use the actual smoothed/clamped camera,
## so edge coverage is valid in both 1.0 and 0.68 combat zoom.
var level: Node2D
var texture: Texture2D

func setup(owner_level: Node2D) -> void:
	level=owner_level
	z_index=-20
	var file="res://assets/runtime/throat.png" if level.game.room_index==4 else "res://assets/runtime/background.png"
	if ResourceLoader.exists(file): texture=load(file)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(level) or not is_instance_valid(level.camera): return
	var center: Vector2=level.camera.get_screen_center_position()
	# At room edges the 8% offset is <200 px. Fixed 2800x1575 covers
	# 1280x720 / 0.68 with ample margin and does not cancel camera zoom.
	var rect=Rect2(center*Vector2(0.92,0.94)-Vector2(1400,747),Vector2(2800,1575))
	draw_rect(Rect2(center-Vector2(2500,1700),Vector2(5000,3400)),Color("081d29"))
	if texture:
		var tint=Color(0.60,0.70,0.76) if level.game.room_index!=4 else Color(0.64,0.64,0.73)
		draw_texture_rect(texture,rect,false,tint)

func get_effect_state() -> Dictionary:
	return {"layer":"far","scroll_scale":[0.92,0.94],"texture_loaded":texture!=null,"world_size":[2800,1575]}
