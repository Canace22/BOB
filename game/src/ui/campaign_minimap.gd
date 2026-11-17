class_name WhaleCampaignMinimap
extends Control
## 只读主线发现状态；格子表达房间拓扑，不代表房间内的物理比例。
const CELLS: Dictionary = {
	"R1": {"R1-01":Vector2(0,2),"R1-02":Vector2(1,2),"R1-03":Vector2(2,2),"R1-04":Vector2(3,2),"R1-05":Vector2(4,2),"R1-06":Vector2(1,0),"R1-07":Vector2(2,1),"R3-01":Vector2(5,2)},
	"R2": {"R3-01":Vector2(0,1),"R2-01":Vector2(1,1),"R2-03":Vector2(2,1),"R2-04":Vector2(2,0)},
	"R3": {"R1-05":Vector2(0,1),"R3-01":Vector2(1,1),"R2-01":Vector2(1,0),"R4-01":Vector2(2,1)},
	"R4": {"R3-01":Vector2(0,0),"R4-01":Vector2(1,0),"R4-03":Vector2(2,0),"R4-05":Vector2(3,0),"R4-06":Vector2(4,0),"R5-01":Vector2(5,0),"R5-08":Vector2(4,1)},
	"R5": {"R4-06":Vector2(0,1),"R5-01":Vector2(1,1),"R5-02":Vector2(2,1),"R5-04":Vector2(3,1),"R5-08":Vector2(0,2)},
}
var data: WhaleUICampaignData
var rooms: Array[Dictionary] = []
var positions: Dictionary = {}
var page: String = ""
var signature: int = 0
var refresh_left: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(dt: float) -> void:
	refresh_left -= dt
	if refresh_left > 0.0 or data == null or data.host.room.is_empty(): return
	refresh_left = 0.2
	# 房间、发现、授能和击败均会改变显示，避免每帧重建布局。
	var next_signature: int = hash([data.host.room.id, data.host.visited, data.host.abilities, data.host.defeated])
	if next_signature == signature: return
	signature = next_signature
	refresh()

func refresh() -> void:
	page = CampaignWorld.region(str(data.host.room.id))
	var cells: Dictionary = CELLS.get(page, {})
	rooms = data.map_rooms().filter(func(room: Dictionary) -> bool: return cells.has(str(room.id)))
	positions.clear()
	# 区域布局固定，发现新房间时已有格子不会跳位。
	var extent := Vector2.ONE
	for cell: Vector2 in cells.values(): extent = extent.max(cell + Vector2.ONE)
	var spacing := Vector2(minf(35.0, 228.0 / extent.x), minf(32.0, 84.0 / extent.y))
	var origin := Vector2(130, 83) - (extent - Vector2.ONE) * spacing * 0.5
	for room: Dictionary in rooms:
		positions[int(room.index)] = origin + Vector2(cells[str(room.id)]) * spacing
	queue_redraw()

func _draw() -> void:
	if rooms.is_empty(): return
	draw_style_box(WhaleUIStyle.box(Color(0.02,0.05,0.08,0.78), Color(0.4,0.55,0.6,0.45)), Rect2(Vector2.ZERO,size))
	_label(Vector2(12,23), CampaignWorld.region_name(str(data.host.room.id)), 15, WhaleUIStyle.BONE)
	_label(Vector2(210,23), WhaleUIStyle.key("ui_region_map"), 14, WhaleUIStyle.AMBER)
	for room: Dictionary in rooms:
		for door: Dictionary in room.doors:
			var target: int = int(door.to)
			if not positions.has(target) or target < int(room.index): continue
			# 未走过的一侧不泄露机关条件；反向已探索门也参与判定。
			var blocked: bool = room.visited and _blocked(str(room.id), door)
			if data.host.visited.get(str(data.host.rooms[target].id), false):
				for reverse: Dictionary in data.host.rooms[target].get("doors", []):
					if int(reverse.to) == int(room.index): blocked = blocked or _blocked(str(data.host.rooms[target].id), reverse)
			var a: Vector2 = positions[int(room.index)]
			var b: Vector2 = positions[target]
			draw_line(a,b,Color("a67c53") if blocked else Color("577b89"),2.0,true)
			if blocked: draw_rect(Rect2((a+b)*0.5-Vector2(2,3),Vector2(4,6)),WhaleUIStyle.AMBER)
	for room: Dictionary in rooms:
		var center: Vector2 = positions[int(room.index)]
		var rect := Rect2(center-Vector2(12,8),Vector2(24,16))
		var color := Color("365564") if room.visited else Color("172934")
		if room.current: color = WhaleUIStyle.AMBER
		draw_rect(rect,color)
		draw_rect(rect,WhaleUIStyle.AMBER if room.current else Color("6d909e"),false,1.0)
		if room.current:
			draw_circle(center,2.5,WhaleUIStyle.INK)
		elif room.camp and room.visited:
			draw_circle(center,2.5,WhaleUIStyle.TEAL)
		elif _is_boss(str(room.id)):
			_label(center+Vector2(-4,5),"B",12,WhaleUIStyle.AMBER)
	_label(Vector2(12,size.y-12),str(data.host.room.name),14,WhaleUIStyle.MUTED)

func _is_boss(id: String) -> bool:
	return id in ["R1-04","R2-04","R4-05","R5-04"] and not data.host.defeated.get(id+":0",false)

func _blocked(source_id: String, door: Dictionary) -> bool:
	# 远处门的 Boss 状态必须查所属房间，不能误用当前房间的敌人列表。
	for need: String in CampaignWorld.requirements(door):
		if need == "boss":
			if not data.host.defeated.get(source_id+":0",false): return true
		elif not data.host.has_ability(need): return true
	return door.has("locked") and not data.host.has_ability(str(door.locked))

func _label(at: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
