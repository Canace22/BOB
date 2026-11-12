class_name CampaignGuidance
extends RefCounted
## Read-only route hints derived from existing room IDs and permanent progress.

static func route_kind(id: String) -> String:
	return "可选支路" if id in ["R1-06", "R1-07"] else "主线"

## True once the first-region exit leads into a built room of the next region.
static func onward(host: Node2D) -> bool:
	return host.rooms.any(func(entry: Dictionary) -> bool: return str(entry.id) == "R3-01")

static func next_room(host: Node2D) -> String:
	if str(host.room.id) == "R1-05" and onward(host): return "R3-01"
	# Later regions list candidates in room data; the first unmet goal with a built room wins.
	for option: Dictionary in host.room.get("next", []):
		if not host.has_ability(str(option.get("unless", ""))) and host.rooms.any(func(entry: Dictionary) -> bool: return str(entry.id) == str(option.to)): return str(option.to)
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
			return "← 沿台阶下行返回须筛 · 远侧通路未开放" if host.collected.get("R1-06", false) else "可选支路 → 右上方厚壳碎片 · 护盾上限 +1，原路返回"
	if host.room.has("hint"): return str(host.room.hint)
	if host.completed:
		if not onward(host): return "首关完成 · 后续区域未开放，可回访支路"
		return "主线 → 右侧出口：胃枢" if str(host.room.id) == "R1-05" else "须门遗港已贯通 · 流膜育窝右侧出口通往胃枢"
	match str(host.room.id):
		"R1-01": return "主线 → 沿骨路前往须筛"
		"R1-02": return "主线 → 下层右门：舌台"
		"R1-03": return "主线 → 右侧洞门：负壳蟹" if host.collected.get("R1-03", false) else "右上平台：护潮壳 · 护盾 +2，再挑战负壳蟹"
		"R1-04": return "主线 → 右门：流膜育窝" if host.defeated.get("R1-04:0", false) else ("主线 · 击败负壳守卫，打开右门" if CampaignRelics.capacity(host.collected) > 0 else "打不过可先返回舌台 · 右上平台收集护潮壳")
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
		"R1-03": return "右上平台可取得护潮壳，增加两点护盾；右门通往负壳蟹。"
		"R1-06":
			if not host.has_ability("float"):
				return "可选护盾支路 · 先沿须筛右侧圆环进入鲸须记忆袋，拾取记忆获得浮游。\n右上方厚壳碎片增加一点护盾；远侧区域未开放，探索后原路返回须筛。"
			return "可选护盾支路 · 从须筛左侧平台逐层上行，右上方厚壳碎片增加一点护盾。\n%s 起跳，空中按住 %s 浮游，松开落台。\n远侧闩尚未开放，探索后沿原路返回须筛。" % [WhaleUIStyle.key("tp_jump"), WhaleUIStyle.key("float")]
		"R1-05": return "须门遗港终点 · 右侧出口通往胃肠沉城的胃枢。" if onward(host) else "首关终点 · 抵达右侧出口后完成本关；后续区域尚未开放。"
	for entry: Dictionary in host.rooms:
		if str(entry.id) == id and entry.has("about"): return str(entry.about)
	return "主线通路"

static func door_label(host: Node2D, door: Dictionary) -> String:
	var target: int = int(door.to)
	if target == -2: return "后续区域未开放 · 原路返回"
	if target == -1: return "首关终点" if not host.completed else "后续区域未开放"
	if target < 0 or target >= host.rooms.size(): return ""
	var id: String = str(host.rooms[target].id)
	var back: bool = str(host.room.id) in ["R1-06", "R1-07"] or (target < host.room_index and CampaignWorld.region(id) != CampaignWorld.region(str(host.room.id)))
	var prefix: String = "返回" if back else route_kind(id)
	return prefix + " · " + str(host.rooms[target].name)

static func float_prompt(host: Node2D) -> String:
	var p: Node2D = host.player
	if not is_instance_valid(p) or p.health <= 0 or host.continuity.travelling: return ""
	var room_id: String = str(host.room.id)
	if room_id != "R1-06" and not (room_id == "R1-02" and p.position.x < 380): return ""
	if not host.has_ability("float"): return ""
	if p.is_on_floor(): return "%s 起跳后按住浮游 · 松开落台" % WhaleUIStyle.key("tp_jump")
	return "按住浮游 · 松开落台" if p.float_left > 0 else "浮游已用完 · 落台恢复"
