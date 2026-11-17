class_name WorldMasterRepaints
extends RefCounted
## 重绘替换整个局部形体；原房边界不再裁断它，外沿用同坐标原像素接回母版。
const DATA: String="res://art/world-seam-repaint-v3/registration.json"

static func apply(master: Node2D, items: Array[Dictionary]) -> void:
	if not FileAccess.file_exists(DATA): return
	var entries: Array=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var rectangles:=PackedVector4Array()
	for entry: Dictionary in entries:
		rectangles.append(Vector4(entry.world[0],entry.world[1],entry.world[2],entry.world[3]))
	for item: Dictionary in items:
		var material: ShaderMaterial=item.node.material
		material.set_shader_parameter("repaint_rectangles",rectangles)
		material.set_shader_parameter("repaint_count",rectangles.size())
	for index: int in entries.size():
		var entry: Dictionary=entries[index]
		var sprite:=Sprite2D.new()
		sprite.name="Repaint_"+str(entry.id).replace("-","_")
		sprite.texture=load("res://art/world-seam-repaint-v3/"+str(entry.file))
		sprite.centered=false
		var rect:=Rect2(entry.world[0],entry.world[1],entry.world[2],entry.world[3])
		sprite.position=rect.position
		sprite.scale=rect.size/sprite.texture.get_size()
		var material:=ShaderMaterial.new()
		material.shader=preload("res://tools/master_repaint.gdshader")
		material.set_shader_parameter("original",load("res://art/world-seam-repaint-v3/"+str(entry.basis)))
		material.set_shader_parameter("canvas_size",sprite.texture.get_size())
		material.set_shader_parameter("patches",rectangles)
		material.set_shader_parameter("patch_count",entries.size())
		material.set_shader_parameter("patch_index",index)
		sprite.material=material
		master.add_child(sprite)
		sprite.owner=master
		items.append({"node":sprite,"rect":rect,"source":sprite.texture.resource_path,"label":"repaint/"+str(entry.id),"mask":"","connector":false,"transform":[sprite.scale.x,0,0,sprite.scale.y,rect.position.x,rect.position.y]})
