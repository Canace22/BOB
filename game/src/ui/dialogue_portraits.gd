class_name WhaleDialoguePortraits
extends RefCounted
## 头像只读角色身份与已入库位图；裁片不另造人物，也不依赖对白正文识别角色。

const SPEAKERS: Dictionary={
	"拾潮者":"player", "补巢者":"nest_mender", "脂库看守":"fat_store_keeper",
	"环居看守":"ring_keeper", "肺缘看守":"lung_keeper",
	"住户":"resident_settled", "住巢居民":"resident_settled", "留居居民":"resident_settled",
	"迁居居民":"resident_migrant", "搬运居民":"resident_carrier",
	"负壳守卫":"shell_guard", "负壳守卫（上层）":"shell_guard", "守卫":"shell_guard",
	"泵庭执卫":"pump_warden", "封梁卫":"beam_guard", "老守护者":"elder_guardian",
	"余索":"yusuo", "贝驮":"beituo"
}
const NON_PERSON: PackedStringArray=["", "旁白", "叙述", "记录", "鲸的残留回声", "鲸声", "封城回声", "记忆片旁的刻字", "灯旁刻痕", "操作提示", "白盒验证结束"]
const PORTRAITS: Dictionary={
	"player":{"path":"tide-picker-action36/idle-body.png", "rect":Rect2(15,0,125,130)},
	"nest_mender":{"path":"chapter-characters-v1/nest_mender.png", "rect":Rect2(0,0,496,360)},
	"fat_store_keeper":{"path":"chapter-characters-v1/fat_store_keeper.png", "rect":Rect2(0,0,264,300)},
	"ring_keeper":{"path":"chapter-characters-v1/ring_keeper.png", "rect":Rect2(0,0,640,289)},
	"lung_keeper":{"path":"chapter-characters-v1/lung_keeper.png", "rect":Rect2(0,0,444,310)},
	"resident_settled":{"path":"chapter-characters-v1/resident_settled.png", "rect":Rect2(0,0,443,340)},
	"resident_migrant":{"path":"chapter-characters-v1/resident_migrant.png", "rect":Rect2(0,0,259,300)},
	"resident_carrier":{"path":"chapter-characters-v1/resident_carrier.png", "rect":Rect2(0,0,640,259)},
	"shell_guard":{"path":"enemy-lab-readability-v1/shell_guard.png", "rect":Rect2(41,2,280,246)},
	"pump_warden":{"path":"enemy-lab-warden-v1/pump_warden.png", "rect":Rect2(152,10,112,130)},
	"beam_guard":{"path":"enemy-lab-beam-guard-v1/beam_guard.png", "rect":Rect2(101,20,230,145)},
	"elder_guardian":{"path":"enemy-lab-elder-idle-fix-v1/elder_idle_fixed.png", "rect":Rect2(65,0,170,140)},
	"yusuo":{"path":"world-kit/yusuo.png", "rect":Rect2(75,0,450,350)},
	"beituo":{"path":"world-kit/beituo.png", "rect":Rect2(60,0,540,450)}
}

var textures: Dictionary={}

static func identity(speaker: String) -> String:
	if speaker in NON_PERSON: return ""
	# 显式身份ID供正式内容使用；兼容既有白盒和主线的说话人标签。
	return speaker if PORTRAITS.has(speaker) else str(SPEAKERS.get(speaker,""))

static func specification(speaker: String) -> Dictionary:
	return PORTRAITS.get(identity(speaker),{})

func texture_for(speaker: String) -> Texture2D:
	var id: String=identity(speaker)
	if id.is_empty(): return null
	if textures.has(id): return textures[id]
	var spec: Dictionary=PORTRAITS[id]
	var path: String="res://art/"+str(spec.path)
	if not ResourceLoader.exists(path):
		push_warning("Dialogue portrait missing: "+id+" / "+path)
		textures[id]=null
		return null
	var bitmap: Texture2D=load(path) as Texture2D
	if bitmap==null: return null
	var crop: Rect2=spec.rect
	if not Rect2(Vector2.ZERO,bitmap.get_size()).encloses(crop):
		push_warning("Dialogue portrait outside bitmap: "+id)
		textures[id]=null
		return null
	var atlas:=AtlasTexture.new()
	atlas.atlas=bitmap
	atlas.region=crop
	atlas.filter_clip=true
	textures[id]=atlas
	return atlas
