class_name TideSkillCatalog
extends RefCounted
## Video keys map to gameplay actions, never to the five-second showcase duration.
const ACTIONS: Dictionary = {
	"strike2": {"proxy":"strike_01", "duration":0.32, "release":0.06, "damage":1, "shape":"front", "reach":125.0, "gain":true, "motion":"free"},
	"upper": {"proxy":"strike_01", "duration":0.34, "release":0.06, "damage":1, "shape":"up", "reach":120.0, "gain":true, "motion":"free"},
	"shadow_dash": {"proxy":"A1_dash", "duration":0.24, "release":0.0, "cooldown":0.85, "unlock":"chapter", "motion":"dash", "speed":850.0, "immune":true},
	"great_slash": {"proxy":"heavy", "duration":0.50, "release":0.17, "damage":3, "shape":"front", "reach":180.0, "cooldown":0.5, "unlock":"dash", "gain":true},
	"dash_slash": {"proxy":"strike_01", "duration":0.38, "release":0.16, "damage":2, "shape":"front", "reach":165.0, "cooldown":0.7, "unlock":"dash", "motion":"lunge", "speed":620.0, "gain":true},
	"cyclone": {"proxy":"heavy", "duration":0.8, "release":0.12, "damage":1, "shape":"radial", "reach":105.0, "pulses":[0.12,0.32,0.52], "cooldown":1.0, "unlock":"dash", "gain":true},
	"crystal_dash": {"proxy":"A1_dash", "duration":1.5, "release":0.0, "damage":2, "shape":"front", "reach":60.0, "cooldown":1.5, "unlock":"dash", "motion":"dash", "speed":920.0},
	"up_spell": {"proxy":"heavy", "duration":0.52, "release":0.16, "damage":2, "shape":"up", "reach":165.0, "cost":33, "cooldown":0.7, "unlock":"R1-03"},
	"abyss_scream": {"proxy":"heavy", "duration":0.66, "release":0.16, "damage":2, "shape":"up", "reach":190.0, "pulses":[0.16,0.30,0.44], "cost":33, "cooldown":0.85, "unlock":"chapter"},
	"shadow_orb": {"proxy":"A4_parry", "duration":0.42, "release":0.14, "damage":3, "cost":33, "cooldown":0.8, "unlock":"chapter", "projectile":true},
	"dive": {"proxy":"heavy", "duration":2.0, "release":0.14, "damage":2, "shape":"radial", "reach":115.0, "cost":33, "cooldown":0.9, "air_only":true, "motion":"dive", "unlock":"R1-03"},
	"dark_dive": {"proxy":"heavy", "duration":2.0, "release":0.14, "damage":3, "shape":"radial", "reach":155.0, "cost":33, "cooldown":1.1, "air_only":true, "motion":"dive", "unlock":"chapter"},
	"parry": {"proxy":"A4_parry", "duration":0.4, "release":0.06, "cooldown":0.6, "parry_end":0.21},
	"scan": {"proxy":"interact", "duration":0.6, "release":0.22, "cooldown":1.0},
	"tram": {"proxy":"interact", "duration":0.5, "release":0.3, "unlock":"chapter", "interaction":true}
}
const TITLES: Dictionary = {
	"strike2":"回拨·斜击", "upper":"挑潮·上挑", "shadow_dash":"影潮穿行",
	"great_slash":"蓄潮·重劈", "dash_slash":"奔潮·冲刺劈砍", "cyclone":"旋潮·回旋斩",
	"crystal_dash":"凝流·蓄力长冲", "up_spell":"潮声·上涌", "abyss_scream":"深潮·共鸣啸",
	"shadow_orb":"深鸣·穿潮弹", "dive":"坠潮·沉钟", "dark_dive":"坠潮·深钟",
	"parry":"迎珠·偏转", "scan":"照见·骨音探潮", "tram":"通行凭证·启门"
}

static func definition(key: String) -> Dictionary:
	var result: Dictionary = ACTIONS.get(key, {}).duplicate(true)
	if result.is_empty(): return result
	result.merge({"id":key, "cost":0, "cooldown":0.0, "unlock":"always", "cancel":0.65, "lock_facing":true, "knockback":80.0}, false)
	result["cooldown_group"]="orb" if key in ["up_spell","abyss_scream","shadow_orb","dive","dark_dive"] else ("dash" if key=="shadow_dash" else key)
	return result

static func unlock_hint(rule: String) -> String:
	return {"dash":"击败负壳守卫获得冲刺后解锁", "R1-03":"取得舌台奖励后解锁", "chapter":"完成本章后解锁", "float":"获得浮游能力后解锁"}.get(rule,"尚未解锁")
