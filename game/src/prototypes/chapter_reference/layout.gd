class_name ChapterReferenceLayout
extends RefCounted
## 独立地编参照，不读取或重写章节对白JSON。
static func read(chapter: int) -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://content/prototypes/chapter_reference/layouts.json"))
	if not parsed is Dictionary: return {}
	return parsed.get("chapters",{}).get(str(chapter),{})

static func enabled() -> bool:
	return not "--no-reference" in OS.get_cmdline_user_args()

static func rect(raw: Array) -> Rect2:
	return Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))

static func point(raw: Array) -> Vector2: return Vector2(float(raw[0]),float(raw[1]))

static func body(parent: Node2D, raw: Array) -> StaticBody2D:
	var area: Rect2=rect(raw)
	var result:=StaticBody2D.new()
	result.position=area.get_center()
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=area.size
	collision.shape=shape
	# 所有新增支路都是单向薄台；底路和敌人原试验场碰撞不归本层改动。
	collision.one_way_collision=true
	collision.one_way_collision_margin=4
	result.add_child(collision)
	parent.add_child(result)
	return result
