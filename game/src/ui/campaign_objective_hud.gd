class_name WhaleCampaignObjectiveHUD
extends PanelContainer
## 只读目标横排：菱形任务标记与白字，不持有任务状态或拦截输入。
var objective: RichTextLabel
var location_terms: Array[String]=[]
var last_value: String=""
const LOCATION_COLOR := Color("ffda70")

func configure_locations(rooms: Array) -> void:
	# 只用于显示高亮，不参与目标识别、任务条件或存档判断。
	location_terms.assign(["右侧骨路","中央须槽","对壁","主路","右侧出口","下层","上层","奖励台","左门","右门","右上方","断口","骨路","营地","出口"])
	for room: Dictionary in rooms:
		for term: String in [str(room.name),CampaignWorld.region_name(str(room.id))]:
			if not term.is_empty() and not location_terms.has(term): location_terms.append(term)
	location_terms.sort_custom(func(a: String,b: String) -> bool: return a.length()>b.length())

func render_objective(value: String) -> void:
	objective.clear()
	var cursor: int=0
	while cursor<value.length():
		var matched: String=""
		for term: String in location_terms:
			if value.substr(cursor,term.length())==term:
				matched=term
				break
		if not matched.is_empty():
			objective.push_color(LOCATION_COLOR)
			objective.add_text(matched)
			objective.pop()
			cursor+=matched.length()
		else:
			# add_text保留原文，不把任务里的方括号当作BBCode执行。
			objective.add_text(value.substr(cursor,1))
			cursor+=1

class ObjectiveMark extends Control:
	func _ready() -> void:
		custom_minimum_size=Vector2(22,22)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	const ICON: Texture2D = preload("res://art/action-hud-v1/objective.png")
	func _draw() -> void:
		var dimensions: Vector2 = ICON.get_size()*(22.0/ICON.get_height())
		draw_texture_rect(ICON,Rect2(Vector2(11,11)-dimensions*0.5,dimensions),false)

func _draw() -> void:
	WhaleActionHUDStyle.panel(self,Rect2(-4,-4,size.x+8,size.y+8),0.25)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	# 文本换行改变最小高度后收紧容器，避免残留空白。
	minimum_size_changed.connect(func() -> void: reset_size.call_deferred())
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",8)
	add_child(row)
	var marker := ObjectiveMark.new()
	marker.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	row.add_child(marker)
	objective=RichTextLabel.new()
	objective.fit_content=true
	objective.scroll_active=false
	objective.mouse_filter=Control.MOUSE_FILTER_IGNORE
	objective.add_theme_font_override("normal_font",WhaleUIStyle.FONT)
	objective.add_theme_font_size_override("normal_font_size",18)
	objective.add_theme_color_override("default_color",Color("f5f1e6"))
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	objective.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	objective.add_theme_color_override("font_outline_color",Color(0.015,0.025,0.025,0.95))
	objective.add_theme_constant_override("outline_size",3)
	objective.add_theme_color_override("font_shadow_color",Color(0,0,0,0.75))
	objective.add_theme_constant_override("shadow_offset_y",2)
	row.add_child(objective)

func present(value: String, width: float) -> void:
	visible=not value.is_empty()
	var width_changed: bool=not is_equal_approx(custom_minimum_size.x,width)
	custom_minimum_size.x=width
	size.x=width
	if last_value!=value or width_changed:
		last_value=value
		render_objective(value)
		size.y=0.0
		queue_redraw()
