class_name EnemyLabCatalog
extends RefCounted
## 试验参数快照，不覆盖主线敌人、奖励或存档。
const PROFILES: Array[Dictionary] = [
	{"id":"forager","title":"食腐甲","hp":6,"height":72.0,"radius":24.0,"speed":145.0,"ending":"retreat","moves":["sweep","rush","double"]},
	{"id":"mudback","title":"栖污大甲","hp":12,"height":110.0,"radius":43.0,"speed":95.0,"ending":"retreat","moves":["ambush","press","flip"]},
	{"id":"shell_guard","title":"负壳守卫","hp":12,"height":100.0,"radius":36.0,"speed":85.0,"ending":"surrender","moves":["poke","shell_push","realign"]},
	{"id":"membrane_hunter","title":"膜上捕食者","hp":10,"height":85.0,"radius":28.0,"speed":130.0,"ending":"surrender","moves":["hunter_pounce","hunter_glide","hunter_drop"]},
	{"id":"nest_eel","title":"缠巢鳗","hp":18,"height":68.0,"radius":132.0,"speed":65.0,"ending":"kill","moves":["eel_bite","eel_tail","eel_burrow","eel_brood"]},
	{"id":"pump_warden","title":"泵庭执卫","hp":18,"height":108.0,"radius":23.0,"speed":120.0,"ending":"surrender","moves":["warden_barrage","warden_vortex","warden_waterstep","warden_thrust","warden_push","warden_double"]},
	{"id":"beam_guard","title":"封梁卫","hp":18,"height":102.0,"radius":32.0,"speed":100.0,"ending":"kill","moves":["beam_press","beam_return","beam_brace","beam_guard"]},
	{"id":"elder_guardian","title":"老守护者","hp":24,"height":135.0,"radius":36.0,"speed":90.0,"ending":"surrender","moves":["elder_sweep","elder_thrust","elder_grip","elder_vault","elder_mimic"]}
]
const MOVES: Dictionary = {
	"elder_mimic":{"title":"观招复现","tell":0.95,"active":0.65,"recover":1.25,"lock":0.0,"width":130.0,"height":100.0,"speed":0.0},
	"elder_sweep":{"title":"长柄扫闸","tell":0.90,"active":0.24,"recover":0.85,"lock":0.60,"width":170.0,"height":34.0,"speed":0.0},
	"elder_thrust":{"title":"撑柄贯刺","tell":1.10,"active":0.25,"recover":1.20,"lock":0.65,"width":170.0,"height":85.0,"speed":360.0,"unblockable":true},
	"elder_grip":{"title":"换握反压","tell":0.70,"active":0.18,"recover":1.20,"lock":0.35,"second":0.55,"width":155.0,"height":95.0,"speed":100.0},
	"elder_vault":{"title":"撑杆越身","tell":0.85,"active":0.18,"recover":1.15,"lock":0.35,"width":130.0,"height":85.0,"speed":0.0},
	"beam_guard":{"title":"弧刃格挡","tell":0.22,"active":0.75,"recover":0.65,"lock":0.0,"width":0.0,"height":0.0,"speed":0.0},
	"beam_riposte":{"title":"防御回刃","tell":0.55,"active":0.20,"recover":1.05,"lock":0.0,"width":125.0,"height":100.0,"speed":200.0},
	"beam_press":{"title":"弧刃压梁","tell":0.90,"active":0.22,"recover":0.85,"lock":0.55,"width":120.0,"height":108.0,"speed":150.0},
	"beam_return":{"title":"退步回刃","tell":0.70,"active":0.24,"recover":1.05,"lock":0.0,"width":135.0,"height":34.0,"speed":180.0},
	"beam_brace":{"title":"架叉重推","tell":0.80,"active":0.18,"recover":1.20,"lock":0.45,"width":120.0,"height":90.0,"speed":280.0,"unblockable":true},
	"warden_barrage":{"title":"三连水弹","tell":0.95,"active":0.65,"recover":1.15,"lock":0.0,"width":0.0,"height":0.0,"speed":0.0},
	"warden_vortex":{"title":"转柄水龙卷","tell":1.0,"active":0.55,"recover":1.25,"lock":0.0,"width":0.0,"height":0.0,"speed":0.0},
	"warden_waterstep":{"title":"水遁回刺","tell":0.65,"active":0.20,"recover":1.25,"lock":0.0,"width":115.0,"height":75.0,"speed":300.0},
	"warden_thrust":{"title":"长刺封道","tell":0.75,"active":0.16,"recover":0.80,"lock":0.50,"width":115.0,"height":75.0,"speed":250.0},
	"warden_push":{"title":"横柄推位","tell":0.85,"active":0.25,"recover":0.95,"lock":0.50,"width":125.0,"height":100.0,"speed":150.0,"guard_pressure":42.0},
	"warden_double":{"title":"跟进二刺","tell":0.65,"active":0.14,"recover":1.05,"lock":0.40,"second":0.50,"width":125.0,"height":75.0,"speed":220.0},
	"eel_burrow":{"title":"潜地突击","tell":0.75,"active":0.28,"recover":1.25,"lock":0.75,"width":120.0,"height":75.0,"speed":200.0},
	"eel_brood":{"title":"吐卵围猎","tell":0.90,"active":0.65,"recover":1.30,"lock":0.0,"width":110.0,"height":65.0,"speed":180.0},
	"eel_bite":{"title":"颚部扑咬","tell":0.80,"active":0.25,"recover":0.95,"lock":0.50,"width":110.0,"height":65.0,"speed":260.0},
	"eel_tail":{"title":"回身扫尾","tell":0.75,"active":0.25,"recover":1.0,"lock":0.45,"width":110.0,"height":34.0,"speed":0.0},
	"hunter_pounce":{"title":"斜向扑击","tell":0.90,"active":0.35,"recover":0.95,"lock":0.50,"width":100.0,"height":70.0,"speed":0.0},
	"hunter_glide":{"title":"贴膜掠过","tell":0.75,"active":0.40,"recover":0.75,"lock":0.35,"width":100.0,"height":65.0,"speed":0.0},
	"hunter_drop":{"title":"收肢重坠","tell":1.15,"active":0.35,"recover":1.35,"lock":0.65,"width":120.0,"height":70.0,"speed":0.0,"unblockable":true},
	"sweep":{"title":"低扫","tell":0.62,"active":0.20,"recover":0.85,"lock":0.0,"width":150.0,"height":34.0,"speed":0.0},
	"rush":{"title":"冲撞","tell":0.80,"active":0.38,"recover":1.10,"lock":0.0,"width":100.0,"height":76.0,"speed":390.0},
	"double":{"title":"二连钳","tell":0.48,"active":0.18,"recover":0.95,"lock":0.0,"width":120.0,"height":65.0,"speed":60.0,"second":0.30},
	"ambush":{"title":"污絮冲出","tell":0.85,"active":0.35,"recover":1.0,"lock":0.50,"width":120.0,"height":95.0,"speed":330.0},
	"press":{"title":"顶甲推进","tell":1.0,"active":0.55,"recover":1.2,"lock":0.65,"width":130.0,"height":110.0,"speed":165.0,"guard_pressure":42.0},
	"flip":{"title":"抬甲翻压","tell":0.90,"active":0.20,"recover":1.3,"lock":0.45,"width":150.0,"height":115.0,"speed":0.0,"interrupt":true,"unblockable":true},
	"poke":{"title":"探钳","tell":0.55,"active":0.16,"recover":0.65,"lock":0.35,"width":115.0,"height":64.0,"speed":0.0},
	"shell_push":{"title":"重壳前压","tell":0.95,"active":0.40,"recover":1.1,"lock":0.60,"width":130.0,"height":100.0,"speed":255.0,"guard_pressure":45.0},
	"realign":{"title":"拖壳回正","tell":0.60,"active":0.22,"recover":0.90,"lock":0.15,"width":110.0,"height":75.0,"speed":-70.0}
}
static func profile(index: int) -> Dictionary:
	return PROFILES[clampi(index,0,PROFILES.size()-1)].duplicate(true)
static func action(key: String) -> Dictionary:
	return MOVES.get(key,MOVES.sweep).duplicate(true)
