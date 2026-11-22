class_name CampaignRoomStream
extends Node
## 普通跨界保留主角；读档、死亡和新旅途显式重建驻留窗口。
var host: Node2D
var enabled: bool = true
var layout: Dictionary = {}
var cached: Dictionary = {}
var requests: Dictionary = {}
var failed: Dictionary = {}
var active: int = -1
var changing: bool = false
var actor: WhalebellyCampaignPlayer
var previous_origin: Vector2
var corridors: CampaignStreamingCorridors
var gates: Node2D
var max_instantiate_us: int = 0
var max_resident: int = 0
var threaded_loading: bool = DisplayServer.get_name() != "headless"
const FALL_MARGIN := 140.0

func _ready() -> void:
	layout = CampaignStreamingLayout.build(host.rooms)
	corridors = CampaignStreamingCorridors.new()
	corridors.host = host
	corridors.layout = layout
	host.add_child.call_deferred(corridors)
	corridors.build.call_deferred()
	gates = CampaignStreamingGates.new()
	gates.stream = self
	host.add_child.call_deferred(gates)

func origin(index: int) -> Vector2:
	return layout.get("origins", {}).get(index, Vector2.ZERO)

func is_ready(index: int) -> bool:
	return index == active or cached.has(index)

func neighbors(index: int) -> Array[int]:
	var result: Array[int] = []
	for door: Dictionary in host.rooms[index].get("doors", []):
		var target: int = int(door.to)
		if target >= 0 and not result.has(target): result.append(target)
	return result

func request(index: int) -> void:
	if is_ready(index) or requests.has(index) or failed.has(index): return
	var path: String = CampaignWorld.scene_path(str(host.rooms[index].id))
	# 无显示后端的压缩纹理并发导入会产生空纹理RID；该后端按帧串行准备。
	var error: Error = ResourceLoader.load_threaded_request(path, "PackedScene") if threaded_loading else OK
	if error == OK: requests[index] = path
	else:
		failed[index] = error
		host.record_event("stream_failed", {"room":index,"error":error})

func _process(_dt: float) -> void:
	if not enabled or host.quitting or active < 0: return
	# 只取后台已完成的资源，每帧最多实例化一个邻房。
	for index: int in requests.keys():
		var path: String = requests[index]
		var status: int = ResourceLoader.load_threaded_get_status(path) if threaded_loading else ResourceLoader.THREAD_LOAD_LOADED
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			failed[index] = status
			requests.erase(index)
			host.record_event("stream_failed", {"room":index,"status":status})
			continue
		if status != ResourceLoader.THREAD_LOAD_LOADED: continue
		var packed: PackedScene = ResourceLoader.load_threaded_get(path) if threaded_loading else load(path)
		requests.erase(index)
		if index == active or index not in neighbors(active): continue
		if packed == null:
			failed[index] = ERR_FILE_NOT_FOUND
			continue
		var begin: int = Time.get_ticks_usec()
		var scene: Node2D = packed.instantiate()
		CampaignStreamingCorridors.prepare_scene(index,scene,layout)
		scene.position = origin(index)
		for child: Node in scene.get_node("World").get_children():
			if str(child.name).begins_with("EnemyArt") or child.name == "PlayerArt": child.hide()
		host.add_child(scene)
		var entry: Dictionary = _prepare_room(index,scene)
		CampaignStreamPresentation.apply(scene,origin(index),host.point(host.rooms[index].size))
		cached[index] = entry
		var elapsed: int = Time.get_ticks_usec()-begin
		max_instantiate_us = maxi(max_instantiate_us,elapsed)
		max_resident = maxi(max_resident,cached.size()+1)
		host.record_event("stream_ready", {"room":index,"instantiate_us":elapsed})
		break
	for index: int in cached: _preview(cached[index], index)

func _prepare_room(index: int, scene: Node2D) -> Dictionary:
	# 准备阶段不跨帧：房内构造沿用原接口，恢复活动别名后邻房全部冻结。
	# 连动态加载的敌人动作也提前准备，跨界不再同步加载Boss图集。
	var previous: Array = [host.room_index,host.room,host.scenery,host.enemies]
	host.room_index=index
	host.room=host.rooms[index]
	host.scenery=scene
	host._create_room_enemies()
	host._create_room_support()
	var entry := {"scene":scene,"enemies":host.enemies,"initialized":true,"modes":{},"collisions":{},"preview":_preview_nodes(scene)}
	_sleep(entry)
	host.room_index=previous[0]
	host.room=previous[1]
	host.scenery=previous[2]
	host.enemies=previous[3]
	return entry

func _physics_process(_dt: float) -> void:
	if not enabled or changing or active < 0 or not is_instance_valid(host.player): return
	if host.quitting or get_tree().paused or not host.player.controls_enabled or host.player.health <= 0: return
	host.player.world_bounds.end.y = fall_limit(host.player.global_position) - origin(active).y
	for index: int in neighbors(active):
		if not is_ready(index): continue
		var rect := Rect2(origin(index),host.point(host.rooms[index].size)).grow(-10)
		if rect.has_point(host.player.global_position):
			var blocked: String = crossing_reason(index)
			if not blocked.is_empty():
				host.player.position = host.player.last_safe
				host.player.velocity = Vector2.ZERO
				host.notify(blocked)
				return
			changing = true
			_cross.call_deferred(index)
			return

func crossing_reason(index: int) -> String:
	for door: Dictionary in host.room.get("doors", []):
		if int(door.to) == index: return gates.reason(active,index,door)
	return "通路尚未开放"

func _cross(index: int) -> void:
	if not is_instance_valid(host.player) or host.player.health <= 0:
		changing = false
		return
	var outgoing: int = active
	actor = host.player
	previous_origin = host.actor_frame.global_position
	var entry := {"scene":host.scenery,"enemies":host.enemies,"initialized":true,"modes":{},"collisions":{},"preview":_preview_nodes(host.scenery)}
	_sleep(entry)
	cached[outgoing] = entry
	host.record_event("stream_cross", {"from":outgoing,"to":index,"player":actor.get_instance_id()})
	for door: Dictionary in host.room.get("doors", []):
		if int(door.to) == index and door.get("completes",false):
			host.completed = true
			host.record_event("level_complete", {"room":str(host.room.id)})
	host.load_room(index, [], true, true)
	actor = null
	changing = false

func take(index: int) -> Dictionary:
	var entry: Dictionary = cached.get(index, {})
	cached.erase(index)
	if not entry.is_empty(): _wake(entry)
	return entry

func explicit_scene(index: int) -> PackedScene:
	# 重生/读档允许等待，但必须接管同一路径的待完成请求，不能重复并发加载。
	if requests.has(index):
		var path: String = requests[index]
		requests.erase(index)
		return ResourceLoader.load_threaded_get(path) if threaded_loading else load(path)
	return load(CampaignWorld.scene_path(str(host.rooms[index].id)))

func activated(index: int) -> void:
	active = index
	host.player.world_bounds = Rect2(-origin(index), Vector2(1000000,1000000))
	for target: int in neighbors(index): request(target)
	var keep: Array[int] = neighbors(index)
	for target: int in cached.keys():
		if target in keep: continue
		var scene: Node2D = cached[target].scene
		if scene.global_position.distance_to(host.player.global_position) < 2200: continue
		scene.queue_free()
		cached.erase(target)
		host.record_event("stream_evict", {"room":target})

func reset() -> void:
	for entry: Dictionary in cached.values():
		if is_instance_valid(entry.scene): entry.scene.queue_free()
	cached.clear()
	failed.clear()
	active = -1

func shutdown() -> void:
	enabled = false
	reset()
	# 显式退出才允许等待未完成资源；正常跨界从不在这里阻塞。
	for path: String in requests.values() if threaded_loading else []:
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS,ResourceLoader.THREAD_LOAD_LOADED]:
			ResourceLoader.load_threaded_get(path)
	requests.clear()

func _exit_tree() -> void:
	shutdown()

func transform_actor() -> void:
	var p: WhalebellyCampaignPlayer = host.player
	# ActorFrame本身始终在树内，避免重挂主角触发_exit_tree销毁技能控制器。
	var delta: Vector2 = previous_origin - p.get_parent().global_position
	p.last_safe += delta
	p.spawn_point += delta
	p.jump_start_y += delta.y
	if p.grapple_target != Vector2.INF: p.grapple_target += delta
	p.spawn_lock_left = 0.0

func _sleep(entry: Dictionary) -> void:
	for node: Node in entry.scene.find_children("*", "Node", true, false):
		entry.modes[node] = node.process_mode
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is CollisionObject2D and (not node is StaticBody2D or node.collision_layer & 4):
			entry.collisions[node] = [node.collision_layer,node.collision_mask]
			node.collision_layer = 0
			node.collision_mask = 0
		if node is AudioStreamPlayer: node.stream_paused = true

func _wake(entry: Dictionary) -> void:
	for node: Node in entry.get("modes", {}):
		if is_instance_valid(node): node.process_mode = entry.modes[node]
	# Enemy bodies are created while the neighbor is dormant. Restore their
	# visibility on wake so a stream crossing cannot leave the crab invisible.
	for node: Node in entry.scene.find_children("*", "Node2D", true, false):
		if str(node.name).begins_with("CorpseCrab") or str(node.name).begins_with("MotherCrab"):
			node.show()
	for node: CollisionObject2D in entry.get("collisions", {}):
		if is_instance_valid(node):
			node.collision_layer = entry.collisions[node][0]
			node.collision_mask = entry.collisions[node][1]
	for node: Node in entry.scene.find_children("*", "AudioStreamPlayer", true, false): node.stream_paused = false
	for part: String in ["EnvironmentMotion","VisualMechanisms"]:
		var node: Node = entry.scene.get_node_or_null(part)
		if node != null: node.last_event_sequence = host.event_sequence

func _preview_nodes(scene: Node2D) -> Array[Node]:
	var result: Array[Node] = []
	for node: Node in scene.find_children("*", "Node", true, false):
		if node is KitParallaxLayer or node is XumenPaintedLayer or node is ChapterRoomEnvironment: result.append(node)
	return result

func _preview(entry: Dictionary, index: int) -> void:
	var scene: Node2D = entry.scene
	var shift: Vector2=((scene.to_local(host.camera.global_position)-host.point(host.rooms[index].size)*0.5)*0.009).clamp(Vector2(-6,-4),Vector2(6,4))
	for node: Node in entry.preview:
		if node is KitParallaxLayer or node is XumenPaintedLayer:
			node.position = node.offset_for(node.get_parent().to_local(host.camera.get_screen_center_position()))
		elif node is ChapterRoomEnvironment and node.process_mode == Node.PROCESS_MODE_DISABLED:
			node.update_at(host.clock)
			node.set_camera_offset(shift)
	if scene.get_node_or_null("ChapterEnvironment")==null and scene.get_node_or_null("ReferenceEnvironment")==null and scene.get_node_or_null("LayoutEnvironment")==null:
		for layer: String in ["Far","Middle","Foreground"]:
			var node: Node2D=scene.get_node_or_null(layer)
			if node!=null: node.position=shift*({"Far":1.0,"Middle":0.38,"Foreground":-0.6}[layer])
	var environment: Node = scene.get_node_or_null("ReferenceEnvironment")
	if environment != null and environment.has_method("update_visuals"):
		var local: Vector2 = scene.to_local(host.camera.global_position)
		environment.level_camera_offset = ((local-host.point(host.rooms[index].size)*0.5)/1.30546875).clamp(Vector2(-128,-18),Vector2(128,18))
		environment.update_visuals()

func fall_limit(world: Vector2) -> float:
	if active < 0: return 10000.0
	var room_bounds: Rect2 = layout.room_bounds[active]
	var limit: float = room_bounds.end.y + FALL_MARGIN
	if world.y <= limit: return limit
	# 竖井可向下延伸。离开台边仍给一次落差余量，远处经过的其它房间不能接管跌落。
	var safe: Vector2 = host.actor_frame.to_global(host.player.last_safe)
	if safe.y > room_bounds.end.y and not corridors.corridor_segment_near(safe,active,CampaignStreamingCorridors.WIDTH).is_empty():
		limit = maxf(limit,safe.y + FALL_MARGIN)
	var passage: Dictionary = corridors.corridor_segment_near(world,active,CampaignStreamingCorridors.WIDTH)
	if not passage.is_empty(): limit = maxf(limit,passage.point.y + FALL_MARGIN)
	return limit

func snapshot() -> Dictionary:
	return {"active":active,"resident":cached.keys(),"pending":requests.keys(),"failed":failed,"origin":origin(active),"changing":changing,"max_resident":max_resident,"max_instantiate_us":max_instantiate_us}
