class_name ChapterThreeView
extends ChapterTwoView
## 机制验证用几何代理；水路、居民和救援均非正式美术。
func _ready() -> void:
	include_mender=true
	super._ready()

func _process(_dt: float) -> void:
	z_index=20 if host.using_reference() else -2
	if not is_instance_valid(host.flow): return
	characters.update_three(host)
	elder.visible=bool(host.facts.get("valve_opened",false)) and (host.flow.stage!="rescue" or host.flow.rescue_time>=5)
	elder.texture=ELDER_IDLE
	var cell: Dictionary=elder_regions[22]
	elder.region_rect=Rect2(0,0,cell.rect[2],cell.rect[3])
	elder.offset=-Vector2(cell.pivot[0],cell.pivot[1])
	elder.position=Vector2(980,520)
	elder.scale=Vector2.ONE*0.7

func _draw() -> void:
	if host.using_reference():
		_draw_reference_labels()
		return
	draw_rect(Rect2(-500,-500,4500,1900),Color("18383c"))
	for rect: Rect2 in ChapterThreeWhitebox.FLOORS:
		draw_rect(rect,Color("52615b"))
		draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("bdbea1"),4,true)
	var flooded: bool=bool(host.facts.get("valve_opened",false)) and (host.flow.stage!="rescue" or host.flow.rescue_time>=5)
	var repaired: bool=bool(host.facts.get("repaired",false))
	draw_rect(Rect2(570,470,330,40),Color("55564c") if flooded else Color("a69964"))
	text(Vector2(585,455),"菌床：只剩断丝" if flooded else "食物菌床 · 新菌丝卷曲",17)
	draw_rect(Rect2(710,370,140,85),Color("6a6863"),false,5)
	text(Vector2(670,350),"补巢者 / 住户",16)
	text(Vector2(900,470),"浅槽回水 · F查看 →",17,WhaleUIStyle.AMBER)
	text(Vector2(1330,730),"废弃低坑 · 可交锋区域",18)
	text(Vector2(1620,555),"排水通道已清开" if host.facts.get("enemy_cleared",false) else "栖污大甲占住排水通道",16)
	var opening: bool=host.flow.stage=="rescue"
	var t: float=host.flow.rescue_time
	var draining: bool=host.flow.stage in ["valve","ready"] or (opening and t<2)
	for i: int in 6:
		var angle: float=host.elapsed*0.9+i*TAU/6
		draw_circle(Vector2(1010,490)+Vector2(cos(angle)*65,sin(angle)*15),3,Color("a6a884"))
	var debris_count: int=6 if draining else 18
	for i: int in debris_count:
		var xx: float=1160+fmod(host.elapsed*45+i*1050.0/debris_count,1050)
		draw_circle(Vector2(xx,625+sin(host.elapsed+i)*5),3,Color("a6a884"))
	if opening and t<6:
		draw_line(Vector2(2090,535),Vector2(2170,640),Color("8b8170"),15,true)
	else:
		draw_rect(Rect2(2090,535,45,115),Color("8b8170"))
	if flooded: text(Vector2(1990,480),"守卫压回旧瓣（代理）",16)
	text(Vector2(2020,510),"旧瓣 · F查看 / 撬开",17,WhaleUIStyle.AMBER)
	if draining:
		draw_line(Vector2(1990,630),Vector2(2190,630),Color("7fbdc1"),7,true)
		text(Vector2(1840,725),"旧瓣裂缝正在排水 · 近处碎屑减少",15)
	if opening and t>=2:
		var front: float=lerpf(2200,520,clampf((t-2)/3,0,1))
		draw_rect(Rect2(front,485,2200-front,40),Color(0.5,0.8,0.85,0.65))
		draw_line(Vector2(front,470),Vector2(front,530),WhaleUIStyle.BONE,6,true)
		text(Vector2(1100,380),"回水正冲向住巢 ←" if t<5 else "住巢系带断裂（演出代理）",19,WhaleUIStyle.AMBER)
	if flooded and not host.facts.get("salvage",false):
		draw_rect(Rect2(450,493,65,18),Color("b2a18b"))
		text(Vector2(385,460),"可用旧壳 · F捡回",16,WhaleUIStyle.AMBER)
	if host.facts.get("salvage",false) and not repaired:
		draw_rect(Rect2(host.player.position+Vector2(-28,-70),Vector2(40,12)),Color("b2a18b"))
		text(Vector2(720,320),"巢片缺口 · F固定",16,WhaleUIStyle.AMBER)
	if repaired:
		draw_line(Vector2(700,405),Vector2(860,405),WhaleUIStyle.AMBER,7,true)
		text(Vector2(670,320),"巢片已固定 · 菌床仍受损",16)
	else:
		draw_rect(Rect2(3250,120,35,400),Color("6f7773"))
		text(Vector2(3110,100),"尚未安置 · 离场前先回住巢",16)
	text(Vector2(3310,460),"肝缘脂库 →",22,WhaleUIStyle.AMBER)

func _draw_reference_labels() -> void:
	text(Vector2(585,415),"菌床表层受损" if host.facts.get("valve_opened",false) else "菌床 / 居住岸",17)
	text(Vector2(900,470),"浅槽 · F查看",17,WhaleUIStyle.AMBER)
	text(Vector2(2020,510),"旧瓣 · F查看 / 撬开",17,WhaleUIStyle.AMBER)
	if host.flow.stage=="rescue": text(Vector2(1000,360),"回水冲向住巢（状态参照）",18)
	if host.flow.stage=="salvage": text(Vector2(385,460),"旧壳 · F捡回",16,WhaleUIStyle.AMBER)
	if host.flow.stage=="carry": text(Vector2(720,320),"巢片缺口 · F固定",16,WhaleUIStyle.AMBER)
	text(Vector2(3310,460),"肝缘脂库 →",22,WhaleUIStyle.AMBER)
