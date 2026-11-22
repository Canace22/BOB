extends TestSuite
## 使用实际入库位图和共享对话框，核对身份、连续换人及小窗口正文空间。

func test_portrait_regions_load_and_named_roles_keep_distinct_images() -> void:
	var portraits:=WhaleDialoguePortraits.new()
	var source_paths: Dictionary={}
	for id: String in WhaleDialoguePortraits.PORTRAITS:
		var texture: Texture2D=portraits.texture_for(id)
		check(texture is AtlasTexture,"known identity loads real bitmap crop: "+id)
		if not texture is AtlasTexture: continue
		var atlas: AtlasTexture=texture as AtlasTexture
		check(Rect2(Vector2.ZERO,atlas.atlas.get_size()).encloses(atlas.region),"portrait crop is inside source: "+id)
		check(atlas.region.size.x>0 and atlas.region.size.y>0,"portrait has a nonempty region")
		check(portraits.texture_for(id)==texture,"portrait crop is cached per identity")
		source_paths[id]=atlas.atlas.resource_path
	eq(source_paths.size(),14,"all authored/reused identities have portraits")
	check(source_paths.nest_mender!=source_paths.resident_migrant,"mender is not an unnamed resident")
	check(source_paths.beam_guard!=source_paths.elder_guardian,"two armed humanoids retain distinct bodies")
	eq(WhaleDialoguePortraits.identity("负壳守卫（上层）"),"shell_guard","upper guard label is an explicit alias")
	eq(WhaleDialoguePortraits.identity("拾潮者"),"player","player display name resolves to stable identity")

func test_all_chapter_person_speakers_have_portraits_without_assigning_faces_to_echoes() -> void:
	var labels: Dictionary={}
	for number: int in range(4,13):
		var path: String="res://content/prototypes/chapters/ch%02d.json"%number
		collect_lines(JSON.parse_string(FileAccess.get_file_as_string(path)),labels)
	for table: Dictionary in [ChapterTwoDialogue.LINES,ChapterThreeDialogue.LINES]:
		for lines: Array in table.values():
			for line: Array in lines: labels[str(line[0])]=true
	for speaker: String in labels:
		check(not WhaleDialoguePortraits.identity(speaker).is_empty() or speaker in WhaleDialoguePortraits.NON_PERSON,"each speaker is a known identity or explicitly nonperson: "+speaker)
	var portraits:=WhaleDialoguePortraits.new()
	for speaker: String in ["旁白","记录","鲸的残留回声","封城回声","未登记角色"]:
		eq(portraits.texture_for(speaker),null,"no fabricated or previous face for nonperson/unknown: "+speaker)

func test_shared_panel_changes_portrait_and_preserves_reveal_and_skip_intents() -> void:
	var panel:=WhaleDialoguePanel.new()
	add(panel)
	panel.show()
	panel.present("补巢者","巢片已经扎好了。")
	check(panel.portrait_frame.visible and panel.portrait_view.texture!=null,"first speaker has a portrait")
	var first: Texture2D=panel.portrait_view.texture
	panel.present("老守护者","先把绳索递给我。")
	check(panel.portrait_view.texture!=first,"new speaker replaces portrait")
	eq(panel.portrait_view.get_meta("speaker_id"),"elder_guardian","view exposes identity for visual QA")
	panel.present("旁白","水慢慢退了下去。")
	check(not panel.portrait_frame.visible and panel.portrait_view.texture==null,"narration removes previous face and occupied space")
	panel.present("拾潮者","我来扶住这一边。")
	eq(panel.text_label.visible_characters,0,"present resets typewriter")
	var advances: Array[bool]=[]
	var skips: Array[bool]=[]
	panel.advance_requested.connect(func() -> void: advances.append(true))
	panel.skip_requested.connect(func() -> void: skips.append(true))
	panel.input_lock=0
	panel.advance()
	eq(advances.size(),0,"first advance only reveals the line")
	panel.advance()
	eq(advances.size(),1,"second advance sends an intent")
	panel.request_skip()
	eq(skips.size(),0,"first skip requires confirmation")
	panel.request_skip()
	eq(skips.size(),1,"second skip sends an intent")
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size=Vector2(640,360)
	panel._layout()
	check(panel.panel.size.x<=592 and panel.panel.position.y>=0,"small viewport keeps panel within frame")
	check(panel.portrait_frame.custom_minimum_size.x<=112,"portrait remains compact")

func collect_lines(value: Variant, speakers: Dictionary) -> void:
	if value is Dictionary:
		for key: String in value:
			if key=="lines":
				for line: Array in value[key]: speakers[str(line[0])]=true
			else: collect_lines(value[key],speakers)
	elif value is Array:
		for child: Variant in value: collect_lines(child,speakers)
