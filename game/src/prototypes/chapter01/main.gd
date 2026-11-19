class_name Chapter01Preview
extends Control
## 独立探索场景，不读取或修改正式游戏进度。

const ROOM_SCENE := preload("res://src/prototypes/chapter01/room_view.gd")
var rooms: Array[Dictionary] = []
var current: Dictionary = {}
var visited: Dictionary = {}
var room_view: Chapter01RoomView
var player: Chapter01Explorer
var camera: Camera2D
var world: Node2D
var container: SubViewportContainer
var transition: Chapter01Transition
var hud: Chapter01PreviewHUD
var nearest: Dictionary = {}
var transitions := 0
var last_from := ""
var web_clock := 0.0


func _ready() -> void:
	clip_contents = true
	rooms = Chapter01Layout.rooms()
	container = SubViewportContainer.new()
	container.size = Vector2(1280, 720)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	container.add_child(viewport)
	world = Node2D.new()
	viewport.add_child(world)
	player = Chapter01Explorer.new()
	player.z_index = 20
	world.add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(640, 470)
	world.add_child(camera)
	camera.make_current()
	transition = Chapter01Transition.new()
	add_child(transition)
	hud = Chapter01PreviewHUD.new()
	add_child(hud)
	_enter("mouth-seam", "")
	hud.notify("循着须根向内探索。靠近带文字的通路，按 E 穿过。")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.render_game_to_text=()=>window.chapter01PreviewState||'{}';", true)


func _enter(id: String, from: String) -> void:
	if is_instance_valid(room_view):
		world.remove_child(room_view)
		room_view.queue_free()
	current = Chapter01Layout.by_id(rooms, id)
	visited[id] = true
	room_view = ROOM_SCENE.new() as Chapter01RoomView
	world.add_child(room_view)
	room_view.setup(current)
	var x := 240.0
	for door: Dictionary in current.doors:
		if door.to == from:
			x = door.position.x
			if door.direction == "left":
				x += 100
			elif door.direction == "right":
				x -= 100
	player.position = Vector2(x, Chapter01Layout.ground_y(current, x) - 4)
	player.velocity = Vector2.ZERO
	camera.position = camera_target()
	camera.reset_smoothing()
	camera.force_update_scroll()
	nearest = {}
	hud.show_room(current, visited.size())
	if id == "jaw-arena":
		hud.notify("守口场已抵达。此预览不安排战斗，出口与回程索现可通行。")
	elif id == "foldwell-mouth":
		hud.notify("已抵达折井下行口。可返回上层，继续寻找未走过的支路。")


func camera_target() -> Vector2:
	return Vector2(clampf(player.position.x, 640, maxf(640, current["size"].x - 640)), current["size"].y * 0.5)


func _physics_process(delta: float) -> void:
	if current.is_empty():
		return
	player.position.x = clampf(player.position.x, 35, current["size"].x - 35)
	if player.position.y > current["size"].y + 160:
		player.position = Vector2(240, Chapter01Layout.ground_y(current, 240) - 5)
		player.velocity = Vector2.ZERO
	if not transition.active:
		camera.position = camera.position.lerp(camera_target(), 1.0 - exp(-delta * 8.0))
	room_view.parallax(camera.position)
	nearest = {}
	for door: Dictionary in current.doors:
		if player.position.distance_to(door.position) < 100:
			nearest = door
	room_view.update_doors(visited, str(nearest.get("to", "")))
	hud.prompt.text = ""
	if not nearest.is_empty():
		hud.prompt.text = "[E] " + str(nearest.label) if Chapter01Layout.door_open(nearest, visited) else "回程索尚未接通 · 请先抵达守口场"
	web_clock += delta
	if OS.has_feature("web") and web_clock > 0.1:
		web_clock = 0
		JavaScriptBridge.get_interface("window").chapter01PreviewState = JSON.stringify(snapshot())


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	var code := (event as InputEventKey).physical_keycode
	if transition.active:
		return
	if code == KEY_E and not nearest.is_empty():
		if Chapter01Layout.door_open(nearest, visited):
			travel(nearest)
		else:
			hud.notify("这段返程索需要从守口场一侧接通。")
	elif code == KEY_R:
		visited.clear()
		_enter("mouth-seam", "")
	elif code == KEY_F:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)


func travel(door: Dictionary) -> void:
	player.frozen = true
	last_from = current.id
	var destination := str(door.to)
	var origin := str(current.id)
	await transition.play(container, func() -> void: _enter(destination, origin), str(door.direction))
	transitions += 1
	player.frozen = false


func snapshot() -> Dictionary:
	var doors: Array[Dictionary] = []
	for door: Dictionary in current.get("doors", []):
		doors.append({"to": door.to, "label": door.label, "x": door.position.x, "y": door.position.y, "direction": door.direction, "open": Chapter01Layout.door_open(door, visited)})
	return {"room": current.get("id", ""), "label": current.get("label", ""), "player": {"x": player.position.x, "y": player.position.y, "grounded": player.is_on_floor()}, "doors": doors, "visited": visited.keys(), "transitioning": transition.active, "transitions": transitions, "last_from": last_from, "transition_kind": transition.last_kind, "preview": true}
