class_name WorldGraph
extends RefCounted

const ROOMS: Dictionary[String, String] = {
	"R1-01": "外伤坡", "R1-02": "须筛", "R1-03": "舌台", "R1-04": "负壳蟹",
	"R1-05": "流膜育窝", "R1-06": "喷气孔上层", "R1-07": "鲸须记忆袋",
}
const ABILITIES: Dictionary[String, String] = {
	"ability.dash": "贴流冲", "ability.float": "浮升（后续区域）", "ability.anchor": "挂环（后续区域）",
}


static func room_path(id: String) -> String:
	return "res://content/rooms/R1/%s.tscn" % id if ROOMS.has(id) else ""
