class_name EnemyLabHUD
extends Control
## 输入控件只请求试验场调度；调试数据只读，不改敌人的阶段或命中结果。
var lab: EnemyLab
var enemy_menu: OptionButton
var move_menu: OptionButton
var formation_menu: OptionButton
var terrain_menu: OptionButton
var auto_box: CheckBox
var kill_box: CheckBox
var range_box: CheckBox
var god_box: CheckBox
var open_menus: Dictionary={}
var paused_before_menus: bool=false
var font: Font=preload("res://art/fonts/WhalefallUI.ttf")
const PHASES: Dictionary={"vault":"撑杆越身","settle":"落地换握","reground":"收柄回稳","guarding":"弧刃格挡","guard_contact":"挡中收劲","brace":"架叉守势","idle":"待机","tell":"起手","active":"有效段","recover":"收招/破绽","hurt":"受控","ended":"结束","return":"回挂","escape_tell":"收伞脱身","evade":"喷水闪避","dive":"钻地","tunnel":"潜行","emerge":"露头蓄势","link":"卵后衔接","coil":"连咬蓄势","wash":"水遁","reform":"凝形蓄势"}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font=font
	theme.default_font_size=14
	self.theme=theme
	var row := HBoxContainer.new()
	row.position=Vector2(14,34)
	row.add_theme_constant_override("separation",7)
	add_child(row)
	var titles: Array=[]
	for profile: Dictionary in EnemyLabCatalog.PROFILES: titles.append(str(profile.title))
	enemy_menu=_choice(row,titles,func(i: int) -> void:
		lab.select_profile(i))
	formation_menu=_choice(row,["单怪","选中敌人＋食腐甲","双食腐甲"],func(i: int) -> void: lab.formation=i; lab.reset_round())
	terrain_menu=_choice(row,["平地","左宽处 / 右窄槽","挂膜 / 遮蔽位","右侧撤离窄道","膜泵关卡样板"],func(i: int) -> void: lab.select_terrain(i))
	move_menu=_choice(row,["自然选招","固定招式1","固定招式2","固定招式3"],func(i: int) -> void: lab.fixed_move=i; lab.apply_settings())
	var auto := CheckBox.new()
	auto.text="自动起手"
	auto.button_pressed=true
	auto.focus_mode=Control.FOCUS_NONE
	auto.toggled.connect(func(on: bool) -> void: lab.auto_attack=on; lab.apply_settings())
	row.add_child(auto)
	auto_box=auto
	range_box=_toggle(row,"判定",true,func(on: bool) -> void: lab.ranges=on; lab.apply_settings())
	god_box=_toggle(row,"无敌",false,func(on: bool) -> void: lab.invincible=on; lab.apply_settings())
	kill_box=_toggle(row,"击杀对照",false,func(on: bool) -> void: lab.kill_comparison=on; lab.reset_round())
	_button(row,"重置 R",lab.reset_round)
	var tools := HBoxContainer.new()
	tools.position=Vector2(14,77)
	tools.add_theme_constant_override("separation",8)
	add_child(tools)
	_button(tools,"强制起手 Enter",lab.force_attack)
	_button(tools,"暂停 / 继续 P",lab.toggle_pause)
	_button(tools,"逐物理帧 .",func() -> void:
		if get_tree().paused: lab.step_requested=true)
	sync()

func _choice(row: HBoxContainer, options: Array, callback: Callable) -> OptionButton:
	var menu := OptionButton.new()
	for value: String in options: menu.add_item(value)
	menu.focus_mode=Control.FOCUS_NONE
	menu.item_selected.connect(callback)
	menu.get_popup().about_to_popup.connect(_open_menu.bind(menu.get_instance_id()))
	menu.get_popup().popup_hide.connect(_close_menu.bind(menu.get_instance_id()))
	row.add_child(menu)
	return menu
func _open_menu(id: int) -> void:
	# 同一个弹窗可能重复请求显示，只在首个菜单打开时保存游玩暂停状态。
	if open_menus.has(id): return
	if open_menus.is_empty(): paused_before_menus=get_tree().paused
	open_menus[id]=true
	get_tree().paused=true

func _close_menu(id: int) -> void:
	if not open_menus.has(id): return
	open_menus.erase(id)
	# 最后一个菜单关闭才归还暂停状态，避免弹窗切换相互覆盖快照。
	if open_menus.is_empty(): get_tree().paused=paused_before_menus

func _button(row: HBoxContainer, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text=title
	button.focus_mode=Control.FOCUS_NONE
	button.pressed.connect(callback)
	row.add_child(button)
func _toggle(row: HBoxContainer, title: String, initial: bool, callback: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text=title
	box.button_pressed=initial
	box.focus_mode=Control.FOCUS_NONE
	box.toggled.connect(callback)
	row.add_child(box)
	return box
func sync() -> void:
	if enemy_menu==null: return
	var selected: int=0 if lab.formation==2 else lab.profile_index
	enemy_menu.disabled=lab.formation==2
	enemy_menu.select(selected)
	formation_menu.select(lab.formation)
	terrain_menu.get_popup().set_item_disabled(1,str(EnemyLabCatalog.profile(selected).id)=="membrane_hunter")
	terrain_menu.select(lab.terrain)
	auto_box.set_pressed_no_signal(lab.auto_attack)
	kill_box.set_pressed_no_signal(lab.kill_comparison)
	var moves: Array=EnemyLabCatalog.PROFILES[selected].moves
	while move_menu.item_count>moves.size()+1: move_menu.remove_item(move_menu.item_count-1)
	while move_menu.item_count<moves.size()+1: move_menu.add_item("")
	lab.fixed_move=clampi(lab.fixed_move,0,moves.size())
	move_menu.select(lab.fixed_move)
	for i: int in moves.size():
		var key: String=EnemyLabCatalog.PROFILES[selected].moves[i]
		move_menu.set_item_text(i+1,"固定："+str(EnemyLabCatalog.MOVES[key].title))
	range_box.set_pressed_no_signal(lab.ranges)
	god_box.set_pressed_no_signal(lab.invincible)
func _process(_dt: float) -> void: queue_redraw()
func _text(at: Vector2, message: String, color: Color=Color.WHITE, pixels: int=14) -> void:
	draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _draw() -> void:
	if lab==null: return
	draw_rect(Rect2(0,0,1280,158),Color("101823"))
	draw_rect(Rect2(0,577,1280,143),Color("101823"))
	_text(Vector2(14,22),"统一敌人试验场 · 独立动作样板 · 不读写主线存档",Color("8eb7c9"),16)
	var status: String="无敌已开启 · 本轮不用于难度验证" if lab.invincible else "正常受伤"
	if get_tree().paused: status+=" · 已暂停"
	_text(Vector2(510,101),status,Color("ff8e7a") if lab.invincible else Color("a8ddba"))
	if not is_instance_valid(lab.player): return
	var p: EnemyLabPlayer=lab.player
	var guard: EnemyLabSkills=p.skill_controller as EnemyLabSkills
	var guard_color := Color("ff8a70") if guard.guard_meter<30.0 else Color("a8ddba")
	_text(Vector2(710,118),"防御架势 %d / 100%s" % [int(guard.guard_meter)," · 破防" if guard.guard_lock>0.0 else ""],guard_color)
	draw_rect(Rect2(960,109,170,7),Color("344457"))
	draw_rect(Rect2(960,109,170.0*guard.guard_meter/guard.GUARD_MAX,7),guard_color)
	if guard.counter_left>0.0:
		_text(Vector2(850,101),"反击 +%d · %.1fs" % [guard.counter_bonus,guard.counter_left],Color("ffe19b"),18)
	if p.health<=0: _text(Vector2(850,101),"玩家倒地 · R 重置",Color("ff8e7a"))
	_text(Vector2(14,118),"玩家 %d/%d  蓄振 %d  %s  Combo %d" % [p.health,p.max_health,p.soul,p.state,(p.skill_controller as TideCombatSkills).combo_hits])
	var debug: Dictionary=EnemyLabDebug.player(p)
	_text(Vector2(14,138),"%s %.2f/%.2fs 后跳:%s 格挡窗:%s 后摇取消:%s 停顿:%.2f" % [debug.key,debug.time,debug.duration,debug.backstep,debug.guard_open,debug.cancel_open,debug.hitstop],Color("a9c8d5"),13)
	_player_bar(p,debug)
	_text(Vector2(710,138),"组合待定:%s %.2fs  预输入:%s %.2fs" % [debug.chord,debug.chord_time,debug.buffer,debug.buffer_left],Color("a9c8d5"),13)
	_text(Vector2(14,599),"WASD移动 / 方向派生 · J普攻 K三段 I格挡 L冲刺 · S+L或Z后跳 · 空格跳 · Q/E技能页",Color("c4d3df"))
	_text(Vector2(14,619),"I格挡消耗架势 / 松开恢复 · 起手0.30s完美格挡 · 红色预警不可挡 · R重置 F1换敌 F2判定 P暂停",Color("8eb7c9"))
	for i: int in mini(lab.enemies.size(),2):
		var enemy: EnemyLabEnemy=lab.enemies[i]
		_enemy_row(enemy,Vector2(14,643+i*34))
		var point: Vector2=enemy.global_position+Vector2(-65,-float(enemy.profile.height)-27)
		if enemy is EnemyLabEel: point.y=enemy.global_position.y-155.0
		if point.y<180.0: point.y=enemy.global_position.y+25.0
		_text(point,str(enemy.profile.title)+" · "+str(PHASES[enemy.state]),Color("f3d6a0"))
		_text(point+Vector2(0,17),"%.1f / %d" % [float(enemy.health)-enemy.reactions.damage_remainder,enemy.maximum],Color("a8ddba"),13)
	if not lab.events.is_empty(): _text(Vector2(14,711),lab.events[0],Color("8eb7c9"),13)
	if str(EnemyLabCatalog.profile(lab.profile_index).id)=="pump_warden" and lab.formation!=2 and lab.terrain in [3,4]:
		_text(Vector2(885,555),"已脱离 · 执卫停手" if lab.route_passed else "目标：向右通过窄道，越过绿色安全线",Color("a8ddba"),14)
	if str(EnemyLabCatalog.profile(lab.profile_index).id)=="pump_warden" and not is_instance_valid(lab.pump_court):
		_text(Vector2(440,555),"黄亮压囊：背侧两次轻击 / 一次重击打断",Color("ffe08c"),14)
	if is_instance_valid(lab.pump_court):
		var pump: Dictionary=lab.pump_court.snapshot()
		var name: String={"fill":"蓄压","stroke":"泵送","release":"泄压"}[pump.phase]
		_text(Vector2(420,181),"膜泵 %s %.1f/%.1fs · 卸压余%.1fs · 反抽余%.1fs" % [name,pump.time,pump.duration,pump.vent,pump.pull],Color("a4d9da"),14)
		_text(Vector2(450,555),"靠近泄压瓣按 F · 卸压后趁失衡前进",Color("efc591"),14)
	if str(EnemyLabCatalog.profile(lab.profile_index).id)=="beam_guard" and lab.formation!=2:
		_text(Vector2(410,555),"弧刃格挡：停手 / 重击破防 / 绕背 · 挡后回斩可格挡 · 红光反推先撤",Color("ffe08c"),14)
	if str(EnemyLabCatalog.profile(lab.profile_index).id)=="elder_guardian" and lab.formation!=2:
		_text(Vector2(340,555),("F7全技能练习：开" if lab.all_skill_practice else "F7全技能练习：关")+" · 观招："+(lab.enemies[0] as EnemyLabElder).mimic.status_title()+" · 重击 / 背击可打断复现 · 换握尚有后段",Color("ffe08c"),14)
	if lab.terrain==2: _text(Vector2(40,389),"遮蔽位：退到顶盖下方可脱战",Color("a8c5d2"))
	if lab.terrain==1: _text(Vector2(740,391),"窄槽：先把重体引到左侧宽处",Color("a8c5d2"))

func _enemy_row(enemy: EnemyLabEnemy, at: Vector2) -> void:
	var d: Dictionary=enemy.snapshot()
	_text(at,"%s  %s  %s  #%d:%d" % [d.enemy,d.move,PHASES[d.phase],d.serial,d.pulse],Color("e7d1a4"))
	var x: float=390.0
	var width: float=300.0
	var segments: Array[Dictionary]=EnemyLabDebug.segments(enemy)
	var total: float=float(segments.back().end) if not segments.is_empty() else 0.0
	draw_rect(Rect2(x,at.y-13,width,10),Color("344457"))
	if total>0.0:
		for segment: Dictionary in segments:
			var color: Color={"vault":Color("8eb7c9"),"settle":Color("e6c16c"),"reground":Color("bfc9d7"),"guarding":Color("8ed3e5"),"guard_contact":Color("bfc9d7"),"brace":Color("bfc9d7"),"tell":Color("e6c16c"),"active":Color("ef887e"),"recover":Color("84c5a2"),"return":Color("7daaca"),"escape_tell":Color("bfc9d7"),"evade":Color("7daaca"),"dive":Color("8f8aa6"),"tunnel":Color("8f8aa6"),"emerge":Color("e6c16c"),"link":Color("8f8aa6"),"coil":Color("e6c16c"),"wash":Color("7daaca"),"reform":Color("e6c16c")}[segment.phase]
			draw_rect(Rect2(x+float(segment.start)/total*width,at.y-13,(float(segment.end)-float(segment.start))/total*width,10),color)
			for mark: Variant in segment.get("marks",[]):
				var release_x: float=x+(float(segment.start)+float(mark))/total*width
				draw_line(Vector2(release_x,at.y-15),Vector2(release_x,at.y),Color("a9edff"),1.0)
			if segment.phase==enemy.state and int(segment.pulse)==enemy.pulse:
				var cursor: float=x+(float(segment.start)+enemy.timer)/total*width
				draw_line(Vector2(cursor,at.y-17),Vector2(cursor,at.y+1),Color.WHITE,2.0)
	_text(Vector2(710,at.y),"%.2f/%.2fs 锁向:%s 控制:%s 护架:%s %s" % [d.time,d.duration,d.locked,d.controllable,d.shell,d.side],Color("b7c7d4"),13)
	_text(Vector2(710,at.y+14),"命中:%s  收到:%d  %s  结束:%s" % [d.hit,d.received,d.result,d.ending],Color("8eb7c9"),12)
	if d.has("pressure_hits"):
		_text(Vector2(14,at.y+14),"受压 %d/3 %.1f/1.4s · 水弹 发%d 中%d 挡%d" % [d.pressure_hits,d.pressure_time,d.water_shots,d.water_hits,d.water_blocks],Color("8eb7c9"),12)
	if d.has("endpoint"):
		_text(Vector2(14,at.y+14),"%s端 · 破绽余%.2fs · 卵 存%d 发%d 拆%d 裂%d · 换侧%d" % ["尾" if d.endpoint=="tail" else "头",d.opening_left,d.eggs,d.eggs_spawned,d.eggs_broken,d.eggs_burst,d.center_repositions],Color("8eb7c9"),12)
	if d.has("elder_stable"):
		_text(Vector2(14,at.y+14),"立足%s · 已学%d · 复现%d 断%d 挡%d 回%d · 破绽%.2fs" % ["稳" if d.elder_stable else "不稳",d.learned_count,d.mimic_casts,d.mimic_interrupts,d.copied_blocks,d.copied_healing,d.opening_left],Color("8eb7c9"),12)
	if d.has("counters"):
		_text(Vector2(14,at.y+14),"格挡%d 破防%d 回斩%d · 架叉反推%d · 破绽余%.2fs" % [d.defense_blocks,d.defense_breaks,d.ripostes,d.counters,d.opening_left],Color("8eb7c9"),12)
	if d.has("first_gap"):
		_text(Vector2(14,at.y+14),"水术 发%d 中%d 挡%d · 水遁%d · 失压%d · 破绽余%.2fs" % [d.water_shots,d.water_hits,d.water_blocks,d.watersteps,d.overloads,d.opening_left],Color("8eb7c9"),12)
	if bool(enemy.spec.get("interrupt",false)): _text(Vector2(390,at.y+13),"重击打断窗口："+str(d.heavy_window),Color("a8ddba") if d.heavy_window else Color("8eb7c9"),12)
	if enemy.control_left>0.0: _text(Vector2(390,at.y+13),"受控剩余 %.2fs" % enemy.control_left,Color("b7c7d4"),12)

func _player_bar(p: EnemyLabPlayer, value: Dictionary) -> void:
	var total: float=float(value.duration)
	draw_rect(Rect2(14,146,650,5),Color("344457"))
	if total<=0.0: return
	var start: float=clampf(float(value.release),0.0,total)
	var end: float=start+1.0/p.animation_fps
	if p.skill_controller.active:
		var data: Dictionary=p.skill_controller.data
		var hits: Array=data.get("pulses",[start])
		end=float(data.get("parry_end",hits.back() if not hits.is_empty() else start))
	end=clampf(end,start,total)
	for segment: Array in [[0.0,start,Color("e6c16c")],[start,end,Color("ef887e")],[end,total,Color("84c5a2")]]:
		draw_rect(Rect2(14.0+float(segment[0])/total*650.0,146,(float(segment[1])-float(segment[0]))/total*650.0,5),segment[2])
	var cursor: float=14.0+clampf(float(value.time)/total,0.0,1.0)*650.0
	draw_line(Vector2(cursor,143),Vector2(cursor,153),Color.WHITE,2.0)
