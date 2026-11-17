class_name CampaignStreamingGates
extends Node2D
## 连接段的实体门：条件和目标房就绪状态都满足后才开放。
var stream: CampaignRoomStream
var entries: Array[Dictionary] = []
var notice_left: float = 0.0
const DOOR := preload("res://art/doorways/tunnel.png")

func _ready() -> void:
	for link: Dictionary in stream.layout.get("links", []):
		_add(link, true)
		_add(link, false)
	for index: int in stream.host.rooms.size():
		for door: Dictionary in stream.host.rooms[index].get("doors", []):
			if int(door.to)>=0: continue
			var foot: Vector2 = stream.origin(index)+stream.host.point(door.pos)
			_add({"a":index,"b":int(door.to),"from":foot,"to":foot+Vector2.RIGHT,"path":PackedVector2Array([foot,foot+Vector2.RIGHT]),"door_a":door,"door_b":{}},true)

func _add(link: Dictionary, forward: bool) -> void:
	var source: int = int(link.a if forward else link.b)
	var target: int = int(link.b if forward else link.a)
	var foot: Vector2 = link.get("gate_a",link.from) if forward else link.get("gate_b",link.to)
	var door: Dictionary = link.door_a if forward else link.door_b
	var body := StaticBody2D.new()
	body.position = foot
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	var path: PackedVector2Array = link.path
	var slot: int = path.find(foot)
	var tangent: Vector2 = path[mini(path.size()-1,slot+1)]-path[maxi(0,slot-1)] if slot>=0 else link.to-link.from
	var vertical: bool = absf(tangent.y)>absf(tangent.x)
	# 高门栏阻止从画外越过门槛，邻近上下层通路仍走各自的连接段。
	rectangle.size = Vector2(380,22) if vertical else Vector2(22,900)
	shape.shape = rectangle
	shape.position.y = 0 if vertical else -200
	body.add_child(shape)
	var art := Sprite2D.new()
	art.texture = DOOR
	art.scale = Vector2.ONE * 180.0 / DOOR.get_height()
	art.position.y = -90
	if vertical:
		art.rotation = PI*0.5
		art.position.y = 0
	art.modulate = Color(0.55,0.7,0.75,0.9)
	body.add_child(art)
	add_child(body)
	entries.append({"source":source,"target":target,"door":door,"body":body,"shape":shape,"art":art,"blocked":true})

func reason(source: int, target: int, door: Dictionary) -> String:
	var host: Node2D = stream.host
	if target < 0: return CampaignWorld.UNBUILT
	for need: String in CampaignWorld.requirements(door):
		if need == "boss":
			if not host.defeated.get(str(host.rooms[source].id)+":0",false): return "先击败守关者"
		elif not host.has_ability(need): return "需要" + str(CampaignWorld.NAMES.get(need,need))
	if door.has("locked") and not host.has_ability(str(door.locked)): return str(door.get("locked_message","通路从另一侧闩着"))
	if stream.failed.has(target): return "邻房加载失败，请返回标题后重试"
	if not stream.is_ready(target): return "正在准备相邻房间"
	return ""

func _process(dt: float) -> void:
	notice_left = maxf(0.0,notice_left-dt)
	if stream.host.quitting: return
	for entry: Dictionary in entries:
		var message: String = reason(entry.source,entry.target,entry.door)
		# 未激活房的外廊可与别的连接共用路口，不能用未加载的远端门封死当前路线。
		var blocked: bool = entry.source == stream.active and not message.is_empty()
		if blocked != bool(entry.blocked):
			entry.blocked = blocked
			entry.shape.set_deferred("disabled",not blocked)
		entry.art.visible = blocked
		# 只解释玩家所在房的出口，避免相邻房加载提示干扰当前操作。
		if blocked and entry.source == stream.active and notice_left <= 0 and is_instance_valid(stream.host.player):
			if stream.host.player.global_position.distance_to(entry.body.global_position) < 115:
				stream.host.notify(message)
				notice_left = 2.0
