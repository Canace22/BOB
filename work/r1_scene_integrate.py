from pathlib import Path
p=Path('G:/鲸落万物生/BOB/godot/first-level')
f=p/'scripts/level.gd';s=f.read_text('utf8')
s=s.replace('var environment_layers: Array=[]','var environment_layers: Array=[]\nvar scenery: Node2D')
a=s.index('\tplatforms=room.platforms.filter');b=s.index('\tplayer=CharacterBody2D.new()',a)
s=s[:a]+'''\tplatforms=room.platforms.duplicate(true)
\tscenery=load("res://scenes/r1/"+str(room.id)+".tscn").instantiate()
\tadd_child(scenery)
\tfor child in scenery.find_children("*", "Node2D", true, false):
\t\tif child.has_method("bind"): child.bind(self)
'''+s[b:]
a=s.index('\tvar far=Node2D.new()');b=s.index('\tfor mode in [0,1]:',a)
s=s[:a]+'''\tvar far=scenery.get_node("Far/FarDrift")
\tenvironment_layers.append(far)
'''+s[b:]
s=s.replace('\ttime+=delta','''\ttime+=delta
\tif main.scenery_preview:
\t\tcamera.position=main.preview_camera
\t\tcamera.zoom=Vector2(0.80,0.80)
\t\tcamera.position_smoothing_enabled=false
\t\treturn''',1)
a=s.index('\tfor p in platforms:',s.index('func _draw()'));b=s.index('\tif game.room_index in [0,3]: draw_camp',a)
s=s[:a]+s[b:]
s=s.replace('\tdraw_door(Vector2(room_width-60,right_y),game.room_index==3 and not game.data.dash)','\tif game.room_index<5: draw_door(Vector2(room_width-60,right_y),game.room_index==3 and not game.data.dash)')
s=s.replace('func interact() -> void:\n','func interact() -> void:\n\tif main.scenery_preview: return\n')
s=s.replace('func interaction_hint() -> String:\n','func interaction_hint() -> String:\n\tif main.scenery_preview: return "巡览镜头 · WASD 平移 · 数字 1–7 切房 · Tab 全景位置 · F6 返回游戏"\n')
f.write_text(s,encoding='utf8')
# Retain actual water/fog/organism dynamics and event integration, remove superseded props.
f=p/'scripts/atmosphere.gd';s=f.read_text('utf8')
a=s.index('\tif textures.has("gate"):',s.index('func draw_middle'));b=s.index('\tfor i in range(3):',a);s=s[:a]+s[b:]
a=s.index('\tif level.game.room_index<4 and textures.has("baleen"):');b=s.index('\tfor i in range(dots.size()):',a);s=s[:a]+s[b:]
a=s.index('\tif textures.has("gate"):',s.index('func draw_foreground'));b=s.index('\tif level.game.room_index==2 and textures.has("cargo"):',a);s=s[:a]+s[b:]
f.write_text(s,encoding='utf8')
f=p/'scripts/main.gd';s=f.read_text('utf8')
s=s.replace('var effect_counts: Dictionary={}','''var effect_counts: Dictionary={}
var scenery_preview:=false
var preview_camera:=Vector2.ZERO
var preview_return_room:=0
var preview_return_position:=Vector2.ZERO
var atlas_panel: Control
var atlas_buttons: Array[Button]=[]''')
s=s.replace('\tsetup_ui()','\tsetup_ui()\n\tsetup_atlas()',1)
s=s.replace('\tif qa_mode=="--qa-load":','\tif qa_mode=="--qa-scenery": call_deferred("verify_scenery")\n\tif qa_mode=="--qa-load":',1)
s=s.replace('"camp":[KEY_C]}','"camp":[KEY_C],"preview":[KEY_F6],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN]}')
s=s.replace(' Esc 暂停"',' Esc 暂停   F6 场景巡览"',1)
s=s.replace('"Shift 贴流冲 · 跳起后跨过宽沟"][index]','"Shift 贴流冲 · 跳起后跨过宽沟","颅侧旧伤 · 鼻道外侧，通向肺侧的闩仍关闭","须根记忆袋 · 四环两沟，右岸封闭，原路返回"][index]')
s=s.replace('\tqa_jump_time=-1\n\tqa_stuck=0','''\tif scenery_preview:
\t\tlevel.player.set_physics_process(false)
\t\tlevel.player.visible=false
\t\tfor e in level.enemies: e.set_physics_process(false)
\t\tpreview_camera=Vector2(760,float(rooms[index].platforms[0].y)*64-250)
\tqa_jump_time=-1
\tqa_stuck=0''',1)
s=s.replace('鲸落万物生 v0.2','鲸落万物生 v0.3')
s=s.replace('\thint.text=level.interaction_hint()','''\thint.text=level.interaction_hint()
\tif scenery_preview and overlay=="":
\t\tpreview_camera+=Vector2(Input.get_axis("left","right"),Input.get_axis("up","down"))*delta*650
\t\tpreview_camera.x=clampf(preview_camera.x,640, maxf(640,level.room_width-640))
\t\tpreview_camera.y=clampf(preview_camera.y,360, maxf(360,level.death_y-360))''')
s=s.replace('\tif game.room_index==3 and not game.data.boss and level.boss_started','\tif scenery_preview: hud.text="须门遗港 · 场景巡览   /   "+str(rooms[game.room_index].name)+"\\n"+str(rooms[game.room_index].anatomy.part)+" · 不写入存档"\n\tif game.room_index==3 and not game.data.boss and level.boss_started',1)
s=s.replace('func handle_overlay_inputs() -> void:\n','''func handle_overlay_inputs() -> void:
\tif Input.is_action_just_pressed("preview") and not changing:
\t\tset_overlay("")
\t\tif not scenery_preview:
\t\t\tpreview_return_room=game.room_index
\t\t\tpreview_return_position=level.player.position
\t\t\tscenery_preview=true
\t\t\tchange_room(game.room_index)
\t\telse:
\t\t\tscenery_preview=false
\t\t\tchange_room(preview_return_room)
\t\t\tget_tree().create_timer(0.12).timeout.connect(func():
\t\t\t\tif is_instance_valid(level): level.player.position=preview_return_position)
''')
s=s.replace('\tmenu.visible=mode!=""','''\tmenu.visible=mode!="" and mode!="map"
\tatlas_panel.visible=mode=="map"
\tfor button in atlas_buttons: button.disabled=not scenery_preview''')
s+='''
func _unhandled_key_input(event: InputEvent) -> void:
\tif event is InputEventKey and event.pressed and not event.echo and scenery_preview:
\t\tif event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_7:
\t\t\tset_overlay("")
\t\t\tchange_room(event.physical_keycode-KEY_1)

func setup_atlas() -> void:
\tatlas_panel=Control.new()
\tatlas_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tui.add_child(atlas_panel)
\tvar bg=ColorRect.new()
\tbg.color=Color("071823")
\tbg.size=Vector2(1280,720)
\tatlas_panel.add_child(bg)
\tvar art=TextureRect.new()
\tart.texture=load("res://assets/runtime/v03/panorama.png")
\tart.position=Vector2(28,88)
\tart.size=Vector2(1224,612)
\tart.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
\tart.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\tatlas_panel.add_child(art)
\tvar title=Label.new()
\ttitle.text="须门遗港  /  巨鲸头部 · 七房位置\\nTab / Esc 返回    F6 切换场景巡览后，可点房间查看实景；首通按原路线解锁"
\ttitle.position=Vector2(28,16)
\ttitle.add_theme_font_size_override("font_size",20)
\tatlas_panel.add_child(title)
\tvar points=[Vector2(70,417),Vector2(330,425),Vector2(550,460),Vector2(830,470),Vector2(1070,430),Vector2(1010,250),Vector2(570,230)]
\tfor i in range(7):
\t\tvar button=Button.new()
\t\tbutton.position=points[i]
\t\tbutton.text=str(i+1)+" · "+str(rooms[i].name)
\t\tbutton.pressed.connect(func():
\t\t\tset_overlay("")
\t\t\tchange_room(i))
\t\tatlas_panel.add_child(button)
\t\tatlas_buttons.append(button)
\tatlas_panel.hide()

func verify_scenery() -> void:
\tvar tester=load("res://scripts/scenery_checks.gd").new()
\tadd_child(tester)
\tvar result=await tester.run(self)
\tvar f=FileAccess.open(evidence_dir+"/scenery.json",FileAccess.WRITE)
\tf.store_string(JSON.stringify(result,"\\t"))
\tf.close()
\tget_tree().quit(0 if result.passed else 2)
'''
f.write_text(s,encoding='utf8')
print('Integrated seven scenery scenes, retained five-room gameplay, added isolated inspection camera')
