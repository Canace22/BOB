class_name CampaignGuidance
extends RefCounted
## Read-only route hints derived from existing room IDs and permanent progress.

static func route_kind(id: String) -> String:
	return "可选支路" if id in ["R1-06", "R1-07"] else "主线"

## True once the first-region exit leads into a built room of the next region.
static func onward(host: Node2D) -> bool:
	return host.rooms.any(func(entry: Dictionary) -> bool: return str(entry.id) == "R3-01")

static func next_room(host: Node2D) -> String:
	if host.abilities.get("ending", false): return ""
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

## Fallback for a room whose local next list has no remaining destination.
## The first-region milestone is not the end of the whole journey.
static func objective(host: Node2D) -> String:
	if host.abilities.get("ending", false): return "已归海 · 可继续探索与回访"
	if not onward(host): return "首关完成" if host.completed else "继续探索"
	if CampaignWorld.region(str(host.room.id)) == "R1":
		return "须门遗港已贯通 · 前往胃枢" if host.completed else "继续探索"
	for entry: Dictionary in host.room.get("enemies", []):
		if entry.get("boss", false) and not host.defeated.get(str(host.room.id) + ":0", false):
			return "击败" + str(entry.get("name", "守关者"))
	if not host.abilities.get("pressure", false): return "前往肺心潮庭 · 取得潮压"
	if not host.abilities.get("bone", false): return "返回胃枢 · 强流门通往断脊"
	if not host.abilities.get("silence", false): return "前往耳海 · 取得静默"
	return "前往归海释放槽 · 推开导流闸"

static func hint(host: Node2D) -> String:
	if host.abilities.get("ending", false): return objective(host)
	match str(host.room.id):
		"R1-07":
			return "奖励台右缘下落 · 沿下层到左门返回须筛" if host.collected.get("R1-07", false) else "可选支路 → 越过断口，拾取记忆与浮游"
		"R1-06":
			return "← 沿台阶下行返回须筛 · 远侧通路未开放" if host.collected.get("R1-06", false) else "可选支路 → 右上方厚壳碎片 · 护盾上限 +1，原路返回"
	if host.completed and CampaignWorld.region(str(host.room.id)) == "R1":
		if not onward(host): return "首关完成 · 后续区域未开放，可回访支路"
		return "主线 → 右侧出口：胃枢" if str(host.room.id) == "R1-05" else "须门遗港已贯通 · 流膜育窝右侧出口通往胃枢"
	if host.room.has("hint"): return str(host.room.hint)
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
				return "支路已完成 · 从奖励台右缘下落，沿下层向左返回须筛；回到须筛后，从门台左缘落回主路，向右前往舌台。"
			return "可选支路 · 取得浮游后原路返回，没有右侧出口。"
		"R1-03": return "右上平台可取得护潮壳，增加两点护盾；右门通往负壳蟹。"
		"R1-06":
			if not host.has_ability("float"):
				return "可选护盾支路 · 先沿须筛右侧圆环进入鲸须记忆袋，拾取记忆获得浮游。\n右上方厚壳碎片增加一点护盾；远侧区域未开放，探索后原路返回须筛。"
			return "可选护盾支路 · 沿左右交替平台浮游上行，右上方厚壳碎片增加一点护盾。\n%s 起跳，空中按住 %s 浮游，松开落台。\n远侧闩尚未开放，探索后沿原路返回须筛。" % [WhaleUIStyle.key("tp_jump"), WhaleUIStyle.key("float")]
		"R1-05": return "须门遗港终点 · 右侧出口通往胃肠沉城的胃枢。" if onward(host) else "首关终点 · 抵达右侧出口后完成本关；后续区域尚未开放。"
	for entry: Dictionary in host.rooms:
		if str(entry.id) == id and entry.has("about"): return str(entry.about)
	return "主线通路"

## 只读当前母蟹的动作，不改变战斗或解锁状态。
static func combat_hint(host: Node2D) -> String:
	if str(host.room.id) != "R1-04": return ""
	for enemy: Dictionary in host.enemies:
		var crab := enemy.get("actor") as CampaignCrabBoss
		if not enemy.get("alive",false) or not is_instance_valid(crab): continue
		if not crab.running: return "骨鸣器开局即可使用 · 靠近后按 J 攻击"
		if crab.state in ["recover","stagger"]: return "收钳破绽 · 靠近按 J 攻击，伤害更高"
		if crab.state in ["tell","active"]:
			if crab.kind in ["sweep","second"]: return "低扫 · 按空格跳起躲开，等收钳后按 J 反击"
			return "下砸 · 后退躲开，等收钳后按 J 反击" if crab.kind == "slam" else "冲撞 · 拉开距离，等整套连招结束再按 J 反击"
		return "护壳中 · J 仍可削血，等收钳后反击伤害更高"
	return ""

static func door_label(host: Node2D, door: Dictionary) -> String:
	var target: int = int(door.to)
	if target == -2: return "后续区域未开放 · 原路返回"
	if target == -1: return "首关终点" if not host.completed else "后续区域未开放"
	if target < 0 or target >= host.rooms.size(): return ""
	var id: String = str(host.rooms[target].id)
	var back: bool = str(host.room.id) in ["R1-06", "R1-07"] or (target < host.room_index and CampaignWorld.region(id) != CampaignWorld.region(str(host.room.id)))
	var prefix: String = "返回" if back else route_kind(id)
	return prefix + " · " + str(host.rooms[target].name)

static func jump_hint(p: TidePlayer) -> String:
	if p.is_on_floor(): return "空格 起跳 · 再按二段跳"
	if p.coyote > 0 or p._wall_direction() != 0:
		return "空格 跳跃"
	if p is WhalebellyCampaignPlayer and p.grapple_target != Vector2.INF:
		return "空格 跳跃"
	if p.jump_count >= 2: return "二段跳已用"
	return "空格 二段跳" if p._can_jump_cancel() else "空格 跳跃"

static func float_prompt(host: Node2D) -> String:
	var p: Node2D = host.player
	if not is_instance_valid(p) or p.health <= 0 or host.continuity.travelling: return ""
	var room_id: String = str(host.room.id)
	if room_id != "R1-06" and not (room_id == "R1-02" and p.position.x < 380): return ""
	if not host.has_ability("float"): return ""
	if p.is_on_floor(): return "%s 起跳后按住浮游 · 松开落台" % WhaleUIStyle.key("tp_jump")
	return "按住浮游 · 松开落台" if p.float_left > 0 else "浮游已用完 · 落台恢复"

static func requirement_hint(host: Node2D, door: Dictionary) -> String:
	for need: String in CampaignWorld.requirements(door):
		if need == "boss" or host.has_ability(need): continue
		if need == "float": return "先到鲸须记忆袋获得浮游"
		if need == "dash": return "击败负壳守卫，获得贴流冲"
		for room: Dictionary in host.rooms:
			for enemy: Dictionary in room.get("enemies", []):
				if str(enemy.get("grants", "")) == need:
					return "前往%s · 击败%s" % [CampaignWorld.region_name(str(room.id)), str(enemy.get("name", room.name))]
	return ""
