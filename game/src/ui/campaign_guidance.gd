class_name CampaignGuidance
extends RefCounted
## Read-only route hints derived from existing room IDs and permanent progress.

static func route_kind(id: String) -> String:
	return "可选支路" if id in ["R1-06", "R1-07"] else "主线"

static func next_room(host: Node2D) -> String:
	if host.completed: return ""
	match str(host.room.id):
		"R1-01": return "R1-02"
		"R1-02": return "R1-03"
		"R1-03": return "R1-04"
		"R1-04": return "R1-05" if host.defeated.get("R1-04:0", false) else ""
		"R1-06": return "R1-02"
		"R1-07": return "R1-02" if host.collected.get("R1-07", false) else ""
	return ""

static func hint(host: Node2D) -> String:
	match str(host.room.id):
		"R1-07":
			return "← 左门返回须筛 · 下高台后沿下层向右" if host.collected.get("R1-07", false) else "可选支路 → 越过断口，拾取记忆与浮游"
		"R1-06":
			return "← 沿台阶下行返回须筛 · 远侧通路未开放" if host.collected.get("R1-06", false) else "可选支路 → 右上方补给 · 探索后原路返回"
	if host.completed: return "首关完成 · 后续区域未开放，可回访支路"
	match str(host.room.id):
		"R1-01": return "主线 → 沿骨路前往须筛"
		"R1-02": return "主线 → 下层右门：舌台"
		"R1-03": return "主线 → 右侧洞门：负壳蟹"
		"R1-04": return "主线 → 右门：流膜育窝" if host.defeated.get("R1-04:0", false) else "主线 · 击败负壳守卫，打开右门"
		"R1-05": return "主线 → 越过流膜，抵达右侧出口"
	return ""

static func description(host: Node2D, id: String) -> String:
	match id:
		"R1-02":
			var optional := "可选：左上方使用浮游，探索喷气孔上层后原路返回。" if host.has_ability("float") else "可选：右上方牵引圆环，前往记忆袋获得浮游。"
			return "主线：下层向右前往舌台。\n" + optional
		"R1-07":
			if host.collected.get(id, false):
				return "支路已完成 · 左门返回须筛，从高台左缘落回下层，再向右去舌台。"
			return "可选支路 · 取得浮游后原路返回，没有右侧出口。"
		"R1-06": return "可选补给支路 · 远侧连接后续区域，目前未开放；探索后原路返回须筛。"
		"R1-05": return "首关终点 · 抵达右侧出口后完成本关；后续区域尚未开放。"
	return "主线通路"

static func door_label(host: Node2D, door: Dictionary) -> String:
	var target: int = int(door.to)
	if target == -2: return "后续区域未开放 · 原路返回"
	if target == -1: return "首关终点" if not host.completed else "后续区域未开放"
	if target < 0 or target >= host.rooms.size(): return ""
	var id: String = str(host.rooms[target].id)
	var prefix: String = "返回" if str(host.room.id) in ["R1-06", "R1-07"] else route_kind(id)
	return prefix + " · " + str(host.rooms[target].name)
