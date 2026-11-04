class_name XumenChunkEdges
extends RefCounted
## Non-destructive alpha margins on painted layers, not gameplay bodies.
var compiled: Dictionary={}
var materials: Dictionary={}

func bind_chunk(id: int,chunk: Node2D,size: Vector2) -> void:
	var items: Array[ShaderMaterial]=[]
	for node: Node in chunk.find_children("*","CanvasItem",true,false):
		if not (node is Sprite2D or node is Polygon2D):continue
		var parent: Node=node.get_parent()
		var actor: bool=false
		while parent!=null and parent!=chunk:
			if parent is CharacterBody2D:actor=true;break
			parent=parent.get_parent()
		if actor:continue
		if str(node.name) in ["PlayerArt","EnemyArt0","EnemyArt1","EnemyArt2"]:continue
		var old: ShaderMaterial=node.material as ShaderMaterial
		var source: String=old.shader.code if old!=null else "shader_type canvas_item;\nvoid fragment(){}"
		if not compiled.has(source):
			var code: String=source
			code=code.replace("shader_type canvas_item;","shader_type canvas_item;\nuniform vec2 chunk_origin; uniform vec2 chunk_size; varying vec2 chunk_pixel;")
			var vertex: int=code.find("void vertex()")
			if vertex>=0:
				var start: int=code.find("{",vertex)+1
				code=code.insert(start,"\nchunk_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;\n")
			else:code+="\nvoid vertex(){chunk_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}"
			var start: int=code.find("{",code.find("void fragment()"))+1
			var depth: int=1
			var end: int=start
			while depth>0 and end<code.length():
				if code[end]=="{":depth+=1
				if code[end]=="}":depth-=1
				end+=1
			code=code.insert(end-1,"\nvec2 cp=chunk_pixel-chunk_origin; COLOR.a*=smoothstep(0.0,80.0,cp.x)*(1.0-smoothstep(chunk_size.x-80.0,chunk_size.x,cp.x))*smoothstep(0.0,40.0,cp.y)*(1.0-smoothstep(chunk_size.y-60.0,chunk_size.y,cp.y));\n")
			var shader:=Shader.new()
			shader.code=code
			compiled[source]=shader
		var material:=old.duplicate() as ShaderMaterial if old!=null else ShaderMaterial.new()
		material.shader=compiled[source]
		material.set_shader_parameter("chunk_size",size)
		node.material=material
		items.append(material)
	materials[id]=items

func move_chunk(id: int,at: Vector2) -> void:
	for material: ShaderMaterial in materials.get(id,[]):material.set_shader_parameter("chunk_origin",at)
