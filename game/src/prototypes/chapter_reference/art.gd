class_name ChapterReferenceArt
extends RefCounted
## 原件锚点预先换算为运行纹理像素；仅等比放置，不把台面拉成长柱。
var entries: Dictionary={}
var textures: Dictionary={}
var missing: PackedStringArray=[]

func _init() -> void:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://content/prototypes/chapter_reference/resources.json"))
	if parsed is Dictionary: entries=parsed.get("art",{})

func texture(id: String) -> Texture2D:
	if textures.has(id): return textures[id] as Texture2D
	var path: String=str(entries.get(id,{}).get("path",""))
	var value: Texture2D=null
	if not path.is_empty() and ResourceLoader.exists(path): value=load(path) as Texture2D
	if value==null:
		var reason: String="%s: %s" % [id,path if not path.is_empty() else "unregistered art id"]
		missing.append(reason)
		push_error("Chapter reference missing bitmap: "+reason)
	textures[id]=value
	return value

func metrics(id: String, tex: Texture2D) -> Dictionary:
	var entry: Dictionary=entries.get(id,{})
	var size:=Vector2(tex.get_width(),tex.get_height())
	var box: Array=entry.get("bbox",[0,0,1,1])
	var rect:=Rect2(Vector2(float(box[0])*size.x,float(box[1])*size.y),Vector2(float(box[2]-box[0])*size.x,float(box[3]-box[1])*size.y))
	return {"bounds":rect,"size":size,"anchors":entry.get("anchors",{})}

func sprite(id: String, at: Vector2, width: float, anchor: String="foot") -> Sprite2D:
	var tex: Texture2D=texture(id)
	if tex==null: return null
	var data: Dictionary=metrics(id,tex)
	var rect: Rect2=data.bounds
	var raw: Array=data.anchors.get(anchor,[0.5,1.0])
	var pivot: Vector2=Vector2(float(raw[0]),float(raw[1]))*data.size
	var item:=Sprite2D.new()
	item.texture=tex
	item.centered=false
	item.scale=Vector2.ONE*width/maxf(rect.size.x,1)
	item.position=at-pivot*item.scale
	item.set_meta("reference_anchor",at)
	item.set_meta("reference_bounds",Rect2(item.position+rect.position*item.scale,rect.size*item.scale))
	return item

func surface(parent: Node2D, id: String, rect: Rect2) -> void:
	var count: int=maxi(1,ceili(rect.size.x/330.0))
	var span: float=rect.size.x/float(count)
	for i: int in count:
		var item: Sprite2D=sprite(id,Vector2(rect.position.x+(float(i)+0.5)*span,rect.position.y),span+12,"surface")
		if item==null: return
		item.z_index=8
		parent.add_child(item)
