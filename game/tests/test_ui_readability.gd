extends TestSuite

func test_skipping_needs_confirmation_and_continuing_cancels_it() -> void:
	var panel := WhaleDialoguePanel.new()
	add(panel)
	panel.show()
	panel.present("拾潮者","潮水会记得来路。")
	panel.input_lock = 0.0
	var skips: Array[bool] = []
	panel.skip_requested.connect(func() -> void: skips.append(true))
	panel.request_skip()
	check(panel.skip_pending and skips.is_empty(),"First skip intent preserves unread story")
	panel.advance()
	check(not panel.skip_pending and skips.is_empty(),"Continuing cancels the pending skip and reveals the line")
	panel.request_skip()
	panel.request_skip()
	eq(skips.size(),1,"Only a second deliberate confirmation skips")
	panel.present("拾潮者","下一句。")
	check(not panel.skip_pending,"A new line never inherits a skip confirmation")

func test_dialogue_buttons_support_focus_and_panel_stays_inside_small_viewport() -> void:
	var panel := WhaleDialoguePanel.new()
	add(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(960,540)
	panel.show()
	await tree.process_frame
	check(panel.next_button.focus_mode==Control.FOCUS_ALL and panel.skip_button.focus_mode==Control.FOCUS_ALL,"Both actions are reachable by keyboard focus")
	check(Rect2(Vector2.ZERO,panel.size).encloses(panel.panel.get_rect()),"Dialogue stays inside a 960x540 viewport")
	panel.apply_style(true)
	var style := panel.panel.get_theme_stylebox("panel") as StyleBoxFlat
	eq(style.bg_color.a,1.0,"High contrast makes the dialogue surface opaque")

func test_short_dialogue_shrinks_and_long_dialogue_stays_bounded() -> void:
	var panel := WhaleDialoguePanel.new()
	add(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size=Vector2(1280,720)
	panel.show()
	panel.present("旁白","鲸歌忽然断了，骨路旁却亮着一盏菌灯。")
	await tree.process_frame
	await tree.process_frame
	var compact: Rect2=panel.panel.get_rect()
	check(compact.size.x<=760 and compact.size.y<=180,"Short dialogue uses a compact panel")
	panel.text_label.visible_characters=1
	await tree.process_frame
	eq(panel.panel.get_rect(),compact,"Typewriter reveal never resizes the panel")
	panel.present("旁白","鲸歌忽然断了，骨路旁却亮着一盏菌灯。".repeat(30))
	await tree.process_frame
	await tree.process_frame
	var expanded: Rect2=panel.panel.get_rect()
	check(expanded.size.y>compact.size.y and expanded.size.y<=224,"Long text expands within a bounded height")
	check(panel.text_label.scroll_active,"Overflow remains scrollable")
