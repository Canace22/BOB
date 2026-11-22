class_name ChapterTwoView
extends Node2D
## 几何只用于明确标注的白盒场地；住巢和救援动作不是正式动画交付。
var host: ChapterTwoWhitebox
var elder: Sprite2D
var elder_regions: Array = []
var characters: ChapterCharacterPresentation
var include_mender: bool=false
const ELDER_SHEET: Texture2D = preload("res://art/enemy-lab-elder-v1/elder_guardian.png")
const ELDER_IDLE: Texture2D = preload("res://art/enemy-lab-elder-idle-fix-v1/elder_idle_fixed.png")

func _ready() -> void:
	z_index = -2
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/enemy-lab-readability-v1/atlas.json"))
	elder_regions = meta.elder_guardian.regions
	elder = Sprite2D.new()
	elder.centered = false
	elder.region_enabled = true
	# 参考标签可置顶，角色仍保持原本的世界层级。
	elder.z_as_relative = false
	elder.z_index = 3
	add_child(elder)
	characters=ChapterCharacterPresentation.new()
	characters.install_residents(include_mender)
	add_child(characters)

func _process(_dt: float) -> void:
	z_index=20 if host.using_reference() else -2
	if not is_instance_valid(host.flow): return
	characters.update_two(host)
	var stage: String = host.flow.stage
	elder.visible = stage in ["rescue","rescued","permitted","complete"]
	var time: float = host.flow.rescue_time
	var pose: int = 22
	elder.position = Vector2(2280,650)
	if stage=="rescue":
		if time<2:
			pose = int(time*6)%4
			elder.position.x = lerpf(2550,2280,clampf(time/2,0,1))
		elif time<3.4: pose = 20
		elif time<6.5: pose = 21
	var cell: Dictionary = elder_regions[pose]
	var rect: Array = cell.rect
	elder.texture = ELDER_IDLE if pose==22 else ELDER_SHEET
	elder.region_rect = Rect2(0,0,rect[2],rect[3]) if pose==22 else Rect2(rect[0],rect[1],rect[2],rect[3])
	elder.offset = -Vector2(cell.pivot[0],cell.pivot[1])
	elder.scale = Vector2.ONE*0.85

func text(at: Vector2, value: String, font_size: int = 17, color: Color = WhaleUIStyle.BONE) -> void:
	WhaleActionHUDStyle.text(self,at,value,font_size,color)

func _draw() -> void:
	if host.using_reference():
		_draw_reference_labels()
		return
	draw_rect(Rect2(-500,-600,4000,1800),Color("102833"))
	for i: int in 12:
		draw_line(Vector2(i*270,-180),Vector2(i*270-150,1050),Color("193a46"),60,true)
	for i: int in ChapterTwoWhitebox.PLATFORMS.size():
		var rect: Rect2 = ChapterTwoWhitebox.PLATFORMS[i]
		draw_rect(rect,Color("3b5358"))
		draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("b7b99a"),4,true)
		for x: int in range(int(rect.position.x)+30,int(rect.end.x),100):
			draw_line(Vector2(x,rect.end.y),Vector2(x+45,rect.position.y+6),Color("526a69"),2,true)
	text(Vector2(65,215),"折井上沿 · 白盒观察台",21,WhaleUIStyle.AMBER)
	text(Vector2(495,335),"沿旧路下降 →",18)
	text(Vector2(760,415),"下方住巢：支架持续落屑",16)
	for x: int in [620,970,1200]:
		draw_line(Vector2(x,235),Vector2(x,268),WhaleUIStyle.AMBER,2,true)
		draw_line(Vector2(x-8,240),Vector2(x-8,265),WhaleUIStyle.AMBER,2,true)
		draw_line(Vector2(x+8,240),Vector2(x+8,265),WhaleUIStyle.AMBER,2,true)
		draw_line(Vector2(x-15,250),Vector2(x+15,250),WhaleUIStyle.AMBER,4,true)
	text(Vector2(1005,575),"安全退路 / 重试点",15,WhaleUIStyle.MUTED)
	draw_line(Vector2(1220,504),Vector2(1220,520),WhaleUIStyle.AMBER,4,true)
	text(Vector2(1150,565),"警戒线",16,WhaleUIStyle.AMBER)
	_draw_blockade()
	_draw_rescue()
	text(Vector2(2610,585),"胃室入口 →",22,WhaleUIStyle.AMBER)
	draw_rect(Rect2(2740,490,30,160),Color("5f8c88"))
	if is_instance_valid(host.guard):
		text(host.guard.position+Vector2(-65,-125),"负壳守卫" if host.guard.outcome.is_empty() else "守卫撑着断壳",16,WhaleUIStyle.AMBER)

func _draw_reference_labels() -> void:
	text(Vector2(1150,565),"警戒线 / 交锋位置",16,WhaleUIStyle.AMBER)
	text(Vector2(2135,390),"住巢与救援（状态参照）",16)
	text(Vector2(2330,695),"居民安全台",16)
	text(Vector2(2610,585),"胃室入口 →",22,WhaleUIStyle.AMBER)

func _draw_blockade() -> void:
	var open: bool = bool(host.facts.get("guard_defeated",false))
	if not open:
		draw_rect(Rect2(1805,65,50,455),Color("6c5a49"))
		draw_rect(Rect2(1805,65,50,455),WhaleUIStyle.AMBER,false,2)
		for y: int in range(85,505,44): draw_line(Vector2(1810,y),Vector2(1850,y+30),Color("ac9871"),3,true)
		text(Vector2(1735,45),"实物封路架 · 守卫护住扣带",15)
	else:
		draw_line(Vector2(1810,520),Vector2(1910,555),Color("8c7960"),15,true)
		text(Vector2(1770,600),"封锁已解除 →",17,WhaleUIStyle.AMBER)

func _draw_rescue() -> void:
	var time: float = host.flow.rescue_time if is_instance_valid(host.flow) else 0
	var stage: String = host.flow.stage if is_instance_valid(host.flow) else "approach"
	var saved: bool = bool(host.facts.get("rescue_done",false))
	var drop: float = 0
	if stage=="rescue":
		drop = lerpf(0,78,clampf(time/2,0,1))
		if time>3: drop = lerpf(78,34,clampf((time-3)/3,0,1))
	elif saved: drop = 34
	var nest := Rect2(2135,430+drop,160,72)
	draw_line(Vector2(2040,350),nest.position+Vector2(0,5),WhaleUIStyle.MUTED,3,true)
	draw_line(Vector2(2390,350),nest.position+Vector2(160,5),WhaleUIStyle.MUTED,3,true)
	draw_rect(nest,Color("665b68"))
	draw_rect(nest,Color("c1a18c"),false,2)
	text(nest.position+Vector2(8,31),"住巢（演出代理）",15)
	draw_line(Vector2(2080,530),Vector2(2350,530+drop),Color("a18868"),9,true)
	if stage=="rescue" and time>2:
		draw_line(Vector2(2275,642),Vector2(2210,530+drop),WhaleUIStyle.AMBER,7,true)
	text(Vector2(2330,695),"安全台 / 居民",15)
	if not saved and stage!="rescue":
		for i: int in 4:
			var fall: float = fmod(host.elapsed*35+i*23,65)
			draw_circle(Vector2(2160+i*25,530+fall),2,WhaleUIStyle.MUTED)
	if saved: text(Vector2(2180,370),"住户已经上岸",17,WhaleUIStyle.AMBER)
