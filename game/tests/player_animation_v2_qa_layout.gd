class_name PlayerAnimationV2QALayout
extends Node2D
## 仅供manual GPU素材展示：直接摆放真实图集，不创建输入、碰撞或技能执行器。
var sprites: Array[Sprite2D]=[]
var heading: Label
var alpha_cache: Dictionary={}
var image_cache: Dictionary={}
var foot_metadata: Dictionary={}

func setup() -> void:
	foot_metadata=TideVisualPhaseMap.read_json("res://src/combat/foot_offsets.json").get("actions",{})
	heading=Label.new()
	heading.position=Vector2(24,18)
	heading.add_theme_font_size_override("font_size",22)
	add_child(heading)
	for i: int in 8:
		var group: int=i%4
		var sprite:=Sprite2D.new()
		sprite.centered=false
		sprite.position=Vector2([190,450,830,1090][group],400 if i<4 else 650)
		add_child(sprite)
		sprites.append(sprite)
		var cross:=Line2D.new()
		cross.points=PackedVector2Array([Vector2(-7,0),Vector2(7,0),Vector2.ZERO,Vector2(0,-7),Vector2(0,7)])
		cross.position=sprite.position
		cross.width=1.0
		cross.default_color=Color("ffb7d2")
		add_child(cross)
		var label:=Label.new()
		label.text=("OLD action36" if group<2 else "NEW runtime")+("  RIGHT" if group%2==0 else "  LEFT")+("  x2" if i<4 else "  94px")
		label.position=sprite.position+Vector2(-100,-225 if i<4 else -130)
		add_child(label)

func show_sample(key: String, old: Dictionary, current: Dictionary, old_frames: Array[Texture2D], new_frames: Array[Texture2D], old_index: int, new_index: int, caption: String) -> Dictionary:
	heading.text="MANUAL ANIMATION FIXTURE / BODY ONLY\n"+caption
	var metrics: Array[Dictionary]=[]
	for i: int in sprites.size():
		var is_old: bool=i%4<2
		var spec: Dictionary=old if is_old else current
		var index: int=old_index if is_old else new_index
		var body: Dictionary=spec.body
		var sprite: Sprite2D=sprites[i]
		sprite.texture=(old_frames if is_old else new_frames)[index]
		sprite.offset=-Vector2(float(body.pivot[0]),float(body.pivot[1]))
		if is_old:
			var feet: Array=foot_metadata.get(key,{}).get("bottom",[])
			if not feet.is_empty(): sprite.offset.y=-float(feet[mini(index,feet.size()-1)])
		var factor: float=94.0/float(spec.reference_height)*(2.0 if i<4 else 1.0)
		sprite.scale=Vector2(factor*(1.0 if i%2==0 else -1.0),factor)
		var bounds: Rect2=alpha_bounds(body,index)
		var first: Vector2=sprite.to_global(sprite.offset+bounds.position)-sprite.global_position
		var last: Vector2=sprite.to_global(sprite.offset+bounds.end)-sprite.global_position
		metrics.append({"facing":1 if i%2==0 else -1,"old":is_old,"scale":factor,
			"pivot":body.pivot,"applied_offset":[sprite.offset.x,sprite.offset.y],
			"alpha_left":minf(first.x,last.x),"alpha_right":maxf(first.x,last.x),
			"alpha_top":minf(first.y,last.y),"alpha_bottom":maxf(first.y,last.y)})
	var mirror_error: float=0.0
	for i: int in [0,2,4,6]:
		mirror_error=maxf(mirror_error,absf(float(metrics[i].alpha_left)+float(metrics[i+1].alpha_right)))
		mirror_error=maxf(mirror_error,absf(float(metrics[i].alpha_bottom)-float(metrics[i+1].alpha_bottom)))
	return {"views":metrics,"mirror_root_error_pixels":mirror_error}

func alpha_bounds(body: Dictionary, index: int) -> Rect2:
	var path: String=str(body.texture)
	var key: String=path+":"+str(index)
	if not alpha_cache.has(key):
		if not image_cache.has(path):
			# 读取引擎实际导入的纹理，避免原始PNG路径产生桌面专用加载警告。
			var texture: Texture2D=load(path) as Texture2D
			var decoded: Image=texture.get_image()
			if decoded.is_compressed(): decoded.decompress()
			image_cache[path]=decoded
		var rect: Array=body.frames[index]
		var image: Image=image_cache[path]
		alpha_cache[key]=Rect2(image.get_region(Rect2i(int(rect[0]),int(rect[1]),int(rect[2]),int(rect[3]))).get_used_rect())
	return alpha_cache[key]
