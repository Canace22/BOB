class_name StoryText
extends RefCounted
## Short playable adaptation of chapter one; resonance conveys meanings, not mind reading.

const INTRO: Array[String] = [
	"菌灯下，居民把碎壳缀进巢壁。\n拾潮者：我是从外面来的。这里……有人在唱歌。",
	"补巢者停下手里的活：再等一轮巡视。里面的食腐甲还没有清理。",
	"须板深处又传来一小段低鸣。你想再靠近一些。"
]
const ROUTE: Array[String] = [
	"食腐甲缩回聚食处。补巢者提着菌灯，沿维护窄缝走到了内侧。",
	"补巢者：再往里，沿支架下去，就是折井。",
	"你又问起那段低鸣。对方只重新传来清脆的问候，似乎以为你没听清。",
	"滤缝旁，一团浑水绕了几圈，又退回原位。"
]
const WAIT: Array[String] = ["补巢者仍在补巢。里面的食腐甲还没有退回去。"]
const AGAIN: Array[String] = ["补巢者指向内侧的支架：沿那条路下去，就是折井。"]

static func objective(progress: StoryProgress) -> String:
	if progress.has_flag("c01.completed"): return "须庭 · 已获知折井方向，可继续探索"
	if progress.has_flag("c01.route_known"): return "沿内侧支架前往折井方向"
	if progress.has_flag("c01.foragers_retreated"): return "跟随菌灯，到内侧安全台与补巢者共鸣"
	if progress.has_flag("c01.met_mender"): return "循着低鸣穿过须板间的聚食区"
	return "靠近菌灯，与修补住巢的居民共鸣"
