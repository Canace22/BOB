class_name WorldGraph
extends RefCounted

const ROOMS: Dictionary[String, String] = {
	"N01-A": "第一章 · 须庭入口", "N01-B": "第一章 · 须庭内侧",
	"N02-A": "第二章 · 折井上层", "N02-B": "第二章 · 封锁口",
	"R1-01": "外伤坡", "R1-02": "须筛", "R1-03": "舌台", "R1-04": "负壳蟹",
	"R1-05": "流膜育窝", "R1-06": "喷气孔上层", "R1-07": "鲸须记忆袋",
}
const ABILITIES: Dictionary[String, String] = {
	"ability.dash": "贴流冲", "ability.float": "浮升（后续区域）", "ability.anchor": "挂环（后续区域）",
}


static func room_path(id: String) -> String:
	if not ROOMS.has(id):
		return ""
	return "res://content/rooms/%s/%s.tscn" % ["chapters" if id.begins_with("N0") else "R1", id]
