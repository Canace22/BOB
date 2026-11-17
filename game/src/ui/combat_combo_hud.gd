class_name WhaleCombatComboHUD
extends Control
## 下方技能栏横向四列提示；页面与可用性全部来自实际输入/技能状态。
var controller: WhaleCampaignUI
var rows: Array[Dictionary] = []
var page: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	var p: TideCombatPlayer = controller.player as TideCombatPlayer
	visible = is_instance_valid(p) and p.controls_enabled and p.health > 0 and controller.page_id.is_empty()
	if not visible: return
	position = Vector2(23,get_viewport_rect().size.y-77)
	page = p.pad_input.effective_page()
	rows = TideCombatHints.rows(p)
	queue_redraw()

func text(at: Vector2, value: String, font_size: int = 15, color: Color = WhaleUIStyle.BONE) -> void:
	draw_string_outline(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color(0.01,0.03,0.04,0.95))
	draw_string(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	var p := controller.player as TideCombatPlayer
	if not is_instance_valid(p): return
	if page == 0: return
	var width: float = minf(620.0,maxf(420.0,get_viewport_rect().size.x-70.0))
	var column: float = (width-24.0)/4.0
	draw_style_box(WhaleUIStyle.box(Color(0.02,0.07,0.09,0.91)),Rect2(0,0,width,76))
	var label: String = "Q + E" if page == 3 else ("Q" if page == 1 else "E")
	text(Vector2(12,19),label+" 技能页 · 预选 %.1f秒" % p.pad_input.select_left+(" · W+L 上涌 / 空中 S+L 下潜" if page == 2 else ""),15,WhaleUIStyle.TEAL)
	for i: int in rows.size():
		var row: Dictionary = rows[i]
		var x: float = 12.0+i*column
		var ready: bool = row.status == "可用"
		text(Vector2(x,44),"+ "+str(row.key)+( " 按住" if row.hold else "")+"  "+str(row.title),14,WhaleUIStyle.BONE if ready else WhaleUIStyle.MUTED)
		text(Vector2(x,65),str(row.status),13,WhaleUIStyle.TEAL if ready else WhaleUIStyle.AMBER)
