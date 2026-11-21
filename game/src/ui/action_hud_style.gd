class_name WhaleActionHUDStyle
extends RefCounted
## 静态位图图标与常规UI排版共用入口，不持有技能或任务状态。
const ATLAS: Texture2D = preload("res://art/action-hud-v1/icons.png")
const COUNTER: Texture2D = preload("res://art/action-hud-v1/counter.png")
static var regions: Dictionary = {}
static var counter_regions: Dictionary = {}
static var backdrop: StyleBoxTexture

static func initialize() -> void:
	if not regions.is_empty(): return
	regions = JSON.parse_string(FileAccess.get_file_as_string("res://art/action-hud-v1/icons.json"))
	counter_regions = JSON.parse_string(FileAccess.get_file_as_string("res://art/action-hud-v1/counter.json"))
	# 常规UI九宫格：中心保持均匀压暗，只在外缘按固定像素羽化，避免椭圆底露出四角。
	var image := Image.create(192,192,false,Image.FORMAT_RGBA8)
	for y: int in 192:
		for x: int in 192:
			var outside: Vector2 = (Vector2(x+0.5,y+0.5)-Vector2(96,96)).abs()-Vector2(48,48)
			var distance: float = outside.max(Vector2.ZERO).length()
			var alpha: float = 1.0-smoothstep(0.0,48.0,distance)
			image.set_pixel(x,y,Color(0.02,0.08,0.11,alpha))
	backdrop = StyleBoxTexture.new()
	backdrop.texture = ImageTexture.create_from_image(image)
	for side: Side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: backdrop.set_texture_margin(side,48)

static func region(id: String, counter: bool = false) -> Rect2:
	initialize()
	var cell: Array = (counter_regions if counter else regions).get(id,[0,0,1,1])
	return Rect2(float(cell[0]),float(cell[1]),float(cell[2]),float(cell[3]))

static func icon(canvas: CanvasItem, id: String, rect: Rect2, tint: Color = Color.WHITE, counter: bool = false) -> void:
	var source: Rect2 = region(id,counter)
	var dimensions: Vector2 = source.size * minf(rect.size.x/source.size.x,rect.size.y/source.size.y)
	canvas.draw_texture_rect_region(COUNTER if counter else ATLAS,Rect2(rect.get_center()-dimensions*0.5,dimensions),source,tint)

static func text(canvas: CanvasItem, at: Vector2, value: String, font_size: int = 15, color: Color = WhaleUIStyle.BONE) -> void:
	canvas.draw_string_outline(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color(0.01,0.025,0.035,0.85*color.a))
	canvas.draw_string(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

static func panel(canvas: CanvasItem, rect: Rect2, opacity: float = 0.74) -> void:
	initialize()
	backdrop.modulate_color = Color(1,1,1,opacity)
	var inset: float = minf(8.0,minf(rect.size.x,rect.size.y)*0.2)
	canvas.draw_style_box(backdrop,rect.grow(-inset).grow(48))

static func dock_rect(viewport: Vector2) -> Rect2:
	# 与认可的全屏稿保持相同比例；交互提示读取同一矩形，避免各自漂移。
	var width: float = clampf(viewport.x*0.28,340,420)
	return Rect2(viewport.x-width-20,viewport.y-158,width,138)

static func short_name(action: String, fallback: String = "") -> String:
	return str({"wb_rise":"上挑","wb_charge":"撞击","scan":"探潮","A5_slit":"潜隙","crystal_dash":"长冲","shadow_orb":"深鸣","abyss_scream":"共鸣啸"}.get(action,TideCombatHints.NAMES.get(action,fallback)))

static func action_icon(action: String) -> String:
	return str({"strike_01":"slash","parry":"guard","A1_dash":"dash","backstep":"backstep","wb_rise":"rise","wb_drive":"drive","wb_draw":"sweep","wb_charge":"charge","wb_flurry":"flurry","cyclone":"cyclone","recover":"recover","A4_parry":"orb","scan":"scan","A5_slit":"slit","heavy":"heavy","crystal_dash":"lance","up_spell":"jet","dive":"dive","shadow_orb":"dark_orb","abyss_scream":"scream","dark_dive":"bell"}.get(action,"slash"))
