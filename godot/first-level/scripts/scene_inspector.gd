extends Node
var host: Node
var panel: Control
var original: TextureRect
var coordinates: TextureRect
var title: Label
var layer_index:=0
var snapshot: Dictionary={}
var room_before:=0
var position_before:=Vector2.ZERO
var hp_before:=4
var energy_before:=4
var graph: Control

func setup(main: Node) -> void:
	host=main
	process_mode=Node.PROCESS_MODE_ALWAYS
	panel=Control.new()
	host.ui.add_child(panel)
	var back=ColorRect.new()
	back.color=Color("081923")
	back.size=Vector2(1280,720)
	panel.add_child(back)
	title=Label.new()
	title.position=Vector2(25,18)
	title.add_theme_font_size_override("font_size",19)
	panel.add_child(title)
	original=TextureRect.new()
	original.position=Vector2(25,115)
	original.size=Vector2(605,470)
	original.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	original.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(original)
	coordinates=TextureRect.new()
	coordinates.position=Vector2(650,115)
	coordinates.size=Vector2(605,470)
	coordinates.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coordinates.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(coordinates)
	var footer=Label.new()
	footer.position=Vector2(25,615)
	footer.text="左：设计原画（材质/构图参考）    右：坐标合同（真实平台/门/路线）\n原图有冲突时以修订坐标为准：07右壁封闭；05/06无鲸须；口鼻以厚骨板隔开。\nF8 / Esc 关闭    F6 巡览    F5 全房镜头    F7 路线坐标    F10 单层查看"
	footer.add_theme_font_size_override("font_size",18)
	panel.add_child(footer)
	panel.hide()
	graph=load("res://scripts/world_graph.gd").new()
	graph.host=host
	host.atlas_panel.add_child(graph)

func show_reference() -> void:
	var r=host.rooms[host.game.room_index]
	original.texture=load("res://assets/reference/r1/"+str(r.id)+".png")
	coordinates.texture=load("res://assets/reference/r1/"+str(r.id)+".svg")
	title.text=str(r.id)+" · "+str(r.name)+"   原图 × 路线坐标 × 元素层级\n"+str(r.anatomy.part)+" | "+str(r.anatomy.position)+"\n"+str(r.width)+" × "+str(r.height)+" U   1 U = 64 px   Far 0.1 / Middle 0.5 / World 1.0 / Foreground 1.2"
	panel.show()

func toggle_sandbox() -> void:
	if host.changing:return
	layer_index=0
	host.set_overlay("")
	if not host.route_sandbox:
		snapshot=host.game.data.duplicate(true)
		room_before=host.preview_return_room if host.scenery_preview else host.game.room_index
		position_before=host.preview_return_position if host.scenery_preview else host.level.player.position
		hp_before=host.game.hp
		energy_before=host.game.energy
		host.game.transient=true
		host.route_sandbox=true
		host.scenery_preview=false
		host.game.data.A2=true
		host.game.data.A3=true
		host.game.data.dash=true
		host.game.data.boss=true
		host.game.hp=4
		host.change_room(1)
	else:
		host.game.data=snapshot.duplicate(true)
		host.game.hp=hp_before
		host.game.energy=energy_before
		host.game.transient=false
		host.route_sandbox=false
		host.scenery_preview=false
		host.finished=false
		host.change_room(room_before)
		await get_tree().create_timer(0.12).timeout
		host.level.player.position=position_before
	host.notify("回访路线验证 · 临时 A2/A3 · 不写存档 · F9 退出" if host.route_sandbox else "已恢复进入验证前的旅程")

func cycle_layers() -> void:
	if not host.scenery_preview:return
	layer_index=(layer_index+1)%5
	apply_layers()

func apply_layers() -> void:
	var names=["Far","Middle","World","Foreground"]
	for i in range(4):host.level.scenery.get_node(names[i]).visible=layer_index==0 or layer_index==i+1
	for layer in host.level.environment_layers:
		if layer!=host.level.scenery.get_node("Far/FarDrift"):layer.visible=layer_index==0
	host.level.route_system.visible=layer_index==0 or layer_index==3
	for e in host.level.enemies:e.visible=layer_index==0 or layer_index==3

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.physical_keycode:
		KEY_F5:
			if host.scenery_preview:host.preview_fit=not host.preview_fit
		KEY_F7:host.route_overlay=not host.route_overlay
		KEY_F8:
			host.set_overlay("" if host.overlay=="reference" else "reference")
		KEY_F9:toggle_sandbox()
		KEY_F10:cycle_layers()

func _process(_delta: float) -> void:
	if is_instance_valid(host) and is_instance_valid(graph):graph.queue_redraw()
