extends CanvasLayer
@export var guide_enabled: bool = true
@export var campaign_mode: bool = false
@export var edge_margin: float = 20
@export var header_text: String = "潮汐试炼 / 3C与技能验证场   ·   H 操作说明"
var player: TidePlayer
var panel: Control
var status: Control
var notice: Label
var death: Label
var guide: PanelContainer
var hp_display: float = 100
var notice_left: float = 0
var guide_path: String = "user://tide_3c_guide.cfg"
var health_value: int = 100
var soul_value: int = 99
var cd_values: Dictionary = {}
var double_ready: bool = true
var dash_ready: bool = true

func _ready() -> void:
	layer=100
	panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
	var theme:=Theme.new()
	var font:=SystemFont.new();font.font_names=PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC"]);font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
	theme.default_font=ThemeDB.fallback_font if campaign_mode else font;theme.default_font_size=17 if campaign_mode else 18;panel.theme=theme
	status=Control.new();status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);status.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(status);status.draw.connect(_draw_status)
	notice=Label.new();notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);notice.position=Vector2(-370,-160);notice.size=Vector2(350,60);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;panel.add_child(notice)
	death=Label.new();death.set_anchors_and_offsets_preset(Control.PRESET_CENTER);death.position=Vector2(-270,-65);death.size=Vector2(540,130);death.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;death.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;death.add_theme_font_size_override("font_size",27);death.text="你已归零\n按 R 重生";death.hide();panel.add_child(death)
	bind_player(player)
	var config:=ConfigFile.new()
	if guide_enabled and (config.load(guide_path)!=OK or not config.get_value("guide","read",false)): _show_guide()

func bind_player(next_player:TidePlayer) -> void:
	if is_instance_valid(player):
		for event in ["stats_changed","cooldowns_changed","availability_changed","notification","died"]:
			for connection in player.get_signal_connection_list(event):
				if connection.callable.get_object()==self:player.disconnect(event,connection.callable)
	player=next_player
	health_value=player.health;soul_value=player.soul;hp_display=health_value
	if is_instance_valid(death):death.hide()
	player.stats_changed.connect(func(h,s):
		health_value=h
		soul_value=s
		if h>0:death.hide())
	player.cooldowns_changed.connect(func(values):cd_values=values)
	player.availability_changed.connect(func(j,d):double_ready=j;dash_ready=d)
	player.notification.connect(show_notice)
	player.died.connect(func():death.show())

func _show_guide() -> void:
	player.controls_enabled=false
	guide=PanelContainer.new();guide.set_anchors_and_offsets_preset(Control.PRESET_CENTER);guide.position=Vector2(-440,-230);guide.size=Vector2(880,460);panel.add_child(guide)
	var style:=StyleBoxFlat.new();style.bg_color=Color(.015,.035,.05,.96);style.border_color=Color(.3,.62,.64);style.set_border_width_all(1);style.set_content_margin_all(28);guide.add_theme_stylebox_override("panel",style)
	var text:=Label.new();text.text="拾潮者 · 潮汐试炼\n\nA / D、← / → 移动　 W / ↑ 向上　 S / ↓ 向下\nK / 空格 跳跃 · 轻按短跳 / 按住高跳 · 再按二段跳\n贴墙下落滑行，按 K 蹬墙跳\nJ / Q 短击　 空中 S + J 下劈反弹\nL / Shift 贴流冲　 O 潜隙冲刺\nU 迎珠　 I 重鸣　 P 调息（地面引导）\nE 与潮灯交互　 R 死亡后重生　 H 重看本说明\n\n灰壳练习靶可受击；红色标记靶会造成接触伤害。\n按任意键继续";text.add_theme_font_size_override("font_size",21);guide.add_child(text)
	if campaign_mode:
		text.text="鲸腹遗城 · 拾潮者\n\nA/D、方向键 移动　 K/空格 跳跃、二段跳、蹬墙\nJ/Q 短击　 空中 S+J 下劈反弹\nL/Shift 冲刺　 O 潜隙　 U 迎珠　 I 重鸣　 P 调息\nE 拾取/存档；走入门口过门，A/D+E也可过门\nW 浮游　 G 锚环牵引　 舌膜处 S+K/空格 下潜\nF5 存档　 F6 读取　 Esc 暂停　 M 静音　 H 帮助\n\n沿用已有能力解锁：Boss后获得冲刺；F9临时练习。\n死亡动画结束后返回原检查点，R可手动返回。\n\n按任意键继续"

func _input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if is_instance_valid(guide):
		guide.queue_free();guide=null
		var config:=ConfigFile.new();config.set_value("guide","read",true);config.save(guide_path)
		_resume_after_guide()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode==KEY_H: _show_guide()
	elif event.physical_keycode==KEY_R and player.health<=0:
		player.respawn();death.hide()
		get_viewport().set_input_as_handled()

func show_notice(text:String) -> void:
	# Repeated buffered attempts must not continuously restart the fade.
	if text==notice.text and notice_left>0:return
	notice.text=text;notice_left=1.0

func _resume_after_guide() -> void:
	await get_tree().create_timer(.10).timeout
	player.controls_enabled=true

func _process(dt:float) -> void:
	if not is_instance_valid(player):return
	hp_display=move_toward(hp_display,health_value,90*dt)
	notice_left=maxf(0,notice_left-dt)
	notice.modulate.a=minf(1,notice_left*5)*minf(1,(1-notice_left)*10)
	status.queue_redraw()

func _draw_status() -> void:
	if not is_instance_valid(player):return
	status.position.x=edge_margin-20
	var size:=status.size
	var y:=size.y-94
	var font:=panel.get_theme_default_font()
	status.draw_style_box(_background(),Rect2(12,y-16,950,98))
	status.draw_string(font,Vector2(20,y+3),"生命  %d / %d"%[health_value,player.max_health],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.83,.9,.91))
	status.draw_rect(Rect2(20,y+17,200,16),Color(.12,.18,.21))
	status.draw_rect(Rect2(20,y+17,200*hp_display/player.max_health,16),Color(.65,.43,.32))
	status.draw_rect(Rect2(20,y+17,200.0*health_value/player.max_health,16),Color(.5,.85,.77))
	for i in range(5):
		var x:=27+i*38
		var pts:=PackedVector2Array([Vector2(x,y+44),Vector2(x+5,y+39),Vector2(x+10,y+44),Vector2(x+15,y+39),Vector2(x+20,y+44),Vector2(x+20,y+49),Vector2(x+10,y+59),Vector2(x,y+49)])
		status.draw_colored_polygon(pts,Color(.6,.85,.81) if health_value>i*player.max_health/5.0 else Color(.22,.28,.3))
	for i in range(3):
		var center:=Vector2(260+i*48,y+28)
		var filled:=soul_value>=(i+1)*player.skill_cost
		status.draw_circle(center,17,Color(.25,.65,.8) if filled else Color(.15,.22,.27))
		status.draw_arc(center,18,-PI/2,-PI/2+TAU*clampf((soul_value-i*33)/33.0,0,1),24,Color(.6,.9,1),2)
	status.draw_string(font,Vector2(241,y+65),"魂 %02d / 99"%soul_value,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
	var names:=["短击","贴流冲","迎珠","重鸣"]
	var hotkeys:=["J","L","U","I"]
	var keys:=["","dash","orb","heavy"]
	for i in range(4):
		var rect:=Rect2(410+i*90,y,70,48)
		var locked:bool=i==1 and not player.ability_available("A1_dash")
		var unavailable:bool=(i>=2 and soul_value<33) or locked
		status.draw_rect(rect,Color(.12,.19,.23) if unavailable else Color(.17,.32,.37))
		status.draw_string(font,rect.position+Vector2(8,16),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.5,.55,.55) if unavailable else Color(.85,.93,.92))
		_glyph(i,rect.position+Vector2(35,33),Color(.4,.48,.5) if unavailable else Color(.75,.91,.89))
		if locked:status.draw_string(font,rect.position+Vector2(7,45),"未解锁",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.8,.65,.5))
		var cd:float=cd_values.get(keys[i],0.0)
		if cd>0:
			status.draw_rect(rect,Color(0,0,0,.65));status.draw_string(font,rect.position+Vector2(15,29),"%.1f"%cd,HORIZONTAL_ALIGNMENT_LEFT,-1,19)
		status.draw_string(font,rect.position+Vector2(27,67),hotkeys[i],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.8,.75,.55))
	status.draw_string(font,Vector2(790,y+22),"二段跳 ●" if double_ready else "二段跳 ○",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(.6,.85,.9))
	status.draw_string(font,Vector2(790,y+53),"冲刺 ●" if dash_ready else "冲刺 ○",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(.6,.85,.9))
	if not header_text.is_empty():status.draw_string(font,Vector2(20,32),header_text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(.65,.82,.85))

func _background() -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=Color(.02,.05,.07,.92);return box

func _glyph(index:int,c:Vector2,color:Color) -> void:
	match index:
		0:
			status.draw_line(c+Vector2(0,9),c+Vector2(0,-2),color,2)
			status.draw_polyline(PackedVector2Array([c+Vector2(-7,-7),c+Vector2(-6,-1),c,c+Vector2(6,-1),c+Vector2(7,-7)]),color,2)
		1:
			for x in [-8,2]: status.draw_polyline(PackedVector2Array([c+Vector2(x-4,-7),c+Vector2(x+4,0),c+Vector2(x-4,7)]),color,2)
		2:
			status.draw_circle(c+Vector2(5,0),6,color)
			status.draw_line(c+Vector2(-14,-4),c+Vector2(-4,-4),color,2)
			status.draw_line(c+Vector2(-18,3),c+Vector2(-4,3),color,2)
		3:
			for radius in [4,9,14]:status.draw_arc(c,radius,-.8,3.9,16,color,2)
