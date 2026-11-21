class_name WhaleCombatComboHUD
extends Control
## 面板只读实际选招页和可用性；方向仅改变派生亮度，不发技能。
var controller: WhaleCampaignUI
var rows: Array[Dictionary] = []
var page: int = 0
var derived: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	var p := controller.player as TideCombatPlayer
	visible = is_instance_valid(p) and p.controls_enabled and p.health>0 and controller.page_id.is_empty()
	if not visible: return
	var dock: Rect2 = WhaleActionHUDStyle.dock_rect(get_viewport_rect().size)
	position = dock.position
	size = dock.size
	page = p.pad_input.effective_page()
	rows = TideCombatHints.rows(p)
	derived = [
		{"key":"W+J","action":"wb_rise","active":Input.is_action_pressed("tp_up")},
		{"key":"S+J","action":"wb_draw","active":Input.is_action_pressed("tp_down") and p.is_on_floor()},
		{"key":"A/D+K","action":"wb_drive","active":not is_zero_approx(p.movement_axis())},
		{"key":"A/D+L","action":"wb_charge","active":not is_zero_approx(p.movement_axis())}]
	queue_redraw()

func _slot(at: Vector2, width: float, key: String, action: String, title: String, active: bool, status: String = "可用") -> void:
	var alpha: float = 1.0 if active else 0.5
	if status=="未解锁": alpha*=0.5
	WhaleActionHUDStyle.icon(self,WhaleActionHUDStyle.action_icon(action),Rect2(at+Vector2(width*0.5-19,0),Vector2(38,26)),Color(1,1,1,alpha))
	var caption: String = key+" "+title
	var font_size: int = 11 if caption.length()>9 else 12
	var key_width: float = WhaleUIStyle.FONT.get_string_size(key+" ",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var x: float = at.x+(width-WhaleUIStyle.FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)*0.5
	WhaleActionHUDStyle.text(self,Vector2(x,at.y+40),key+" ",font_size,Color(WhaleUIStyle.AMBER,alpha))
	WhaleActionHUDStyle.text(self,Vector2(x+key_width,at.y+40),title,font_size,Color(WhaleUIStyle.BONE,alpha))
	# 锁定和冷却不只依靠颜色，保留简短可读的真实状态。
	if status not in ["可用","等待后摇","动作中","后跳中"] and active:
		var hint: String = "未解锁" if status=="未解锁" else status.trim_prefix("冷却 ").trim_suffix("秒")
		WhaleActionHUDStyle.text(self,at+Vector2(2,53),hint,10,WhaleUIStyle.MUTED)

func _draw() -> void:
	var p := controller.player as TideCombatPlayer
	if not is_instance_valid(p): return
	WhaleActionHUDStyle.panel(self,Rect2(Vector2.ZERO,size),0.74)
	var label: String = "普通技能" if page==0 else ("Q+E 辅助页" if page==3 else ("Q 技能页" if page==1 else "E 技能页"))
	WhaleActionHUDStyle.text(self,Vector2(6,15),label,14)
	for i: int in 2:
		var selected: bool = (page & (1<<i))!=0
		var rect := Rect2(size.x-66+i*34,0,27,19)
		var frame := WhaleUIStyle.box(WhaleUIStyle.AMBER if selected else Color(0.02,0.06,0.08,0.5),Color(WhaleUIStyle.BONE,0.4))
		frame.set_corner_radius_all(4)
		draw_style_box(frame,rect)
		WhaleActionHUDStyle.text(self,rect.position+Vector2(8,14),"Q" if i==0 else "E",12,WhaleUIStyle.INK if selected else WhaleUIStyle.BONE)
	draw_line(Vector2(0,25),Vector2(size.x,25),Color(WhaleUIStyle.AMBER,0.55),1,true)
	if page==0:
		var base: Array[Array] = [["J","strike_01","普攻"],["I","parry","格挡"],["K","wb_drive","三段斩"],["L","A1_dash","冲刺"],["Z","backstep","后跳"]]
		for i: int in base.size():
			var cell: Array = base[i]
			_slot(Vector2(i*size.x/5,32),size.x/5,cell[0],cell[1],cell[2],true,TideCombatHints.status(p,cell[1]))
			if i>0: _divider(i*size.x/5,36)
		for i: int in derived.size():
			var cell: Dictionary = derived[i]
			_slot(Vector2(i*size.x/4,87),size.x/4,cell.key,cell.action,WhaleActionHUDStyle.short_name(cell.action),cell.active,TideCombatHints.status(p,cell.action))
			if i>0: _divider(i*size.x/4,91)
	else:
		for i: int in rows.size():
			var row: Dictionary = rows[i]
			_slot(Vector2(i*size.x/4,41),size.x/4,row.key,row.action,WhaleActionHUDStyle.short_name(row.action,row.title),true,row.status)
			if i>0: _divider(i*size.x/4,44)
		WhaleActionHUDStyle.text(self,Vector2(6,123),"按住释放" if rows.any(func(row: Dictionary) -> bool: return row.hold) else "点按面键释放",11,WhaleUIStyle.MUTED)

func _divider(x: float, y: float) -> void:
	draw_line(Vector2(x,y),Vector2(x,y+32),Color(WhaleUIStyle.AMBER,0.3),1,true)
