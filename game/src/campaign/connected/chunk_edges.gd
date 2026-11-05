class_name XumenChunkEdges
extends RefCounted
## Non-destructive alpha margins on painted layers, not gameplay bodies.
var compiled: Dictionary={}
var materials: Dictionary={}

func bind_chunk(id: int,chunk: Node2D,size: Vector2) -> void:
	var items: Array[ShaderMaterial]=[]
	if id<2:
		var old_portal: Node2D=chunk.get_node_or_null("Continuity_E01")
		if old_portal!=null:
			old_portal.hide()
			old_portal.process_mode=Node.PROCESS_MODE_DISABLED
	if id==1:
		var surface: Sprite2D=chunk.get_node("ChapterEnvironment/World/Surface")
		surface.texture=preload("res://art/xumen-transitions/hub-world-clean.png")
		chunk.get_node("ChapterEnvironment/Middle/Surface").texture=preload("res://art/xumen-e01/hub-middle-clean.png")
	if id==2:
		chunk.get_node("ChapterEnvironment/World/Surface").texture=preload("res://art/xumen-transitions/tongue-world-clean.png")
		chunk.get_node("ChapterEnvironment/Middle/Surface").texture=preload("res://art/xumen-transitions/tongue-middle-clean.png")
	if id==3:
		chunk.get_node("ChapterEnvironment/World/Surface").texture=preload("res://art/xumen-transitions/arena-world-clean.png")
		chunk.get_node("ChapterEnvironment/Middle/Surface").texture=preload("res://art/xumen-transitions/arena-middle-clean.png")
	if id==4:
		chunk.get_node("ChapterEnvironment/World/Surface").texture=preload("res://art/xumen-transitions/nursery-world-clean.png")
		chunk.get_node("ChapterEnvironment/Middle/Surface").texture=preload("res://art/xumen-transitions/nursery-middle-clean.png")
	if id==5 and "E33" in XumenAuthoredShafts.EDGES:
		chunk.get_node("ChapterEnvironment/World/Surface").texture=load("res://art/xumen-vertical/E33-upper-world.png")
		chunk.get_node("ChapterEnvironment/Middle/Surface").texture=load("res://art/xumen-vertical/E33-upper-middle.png")
	for branch: String in XumenAuthoredShafts.EDGES:
		if id==1 or (id==5 and branch=="E33") or (id==6 and branch=="E35"):
			var portal: Node2D=chunk.get_node_or_null("Continuity_"+branch)
			if portal!=null:portal.hide();portal.process_mode=Node.PROCESS_MODE_DISABLED
	for edge: String in XumenAuthoredTransitions.EDGES:
		if (edge=="E02" and id in [1,2]) or (edge=="E03" and id in [2,3]) or (edge=="E04" and id in [3,4]):
			var old_joint: Node2D=chunk.get_node_or_null("Continuity_"+edge)
			if old_joint!=null:
				old_joint.hide()
				old_joint.process_mode=Node.PROCESS_MODE_DISABLED
	for node: Node in chunk.find_children("*","CanvasItem",true,false):
		if not (node is Sprite2D or node is Polygon2D or node is MeshInstance2D):continue
		var parent: Node=node.get_parent()
		var actor: bool=false
		while parent!=null and parent!=chunk:
			if parent is CharacterBody2D:actor=true;break
			parent=parent.get_parent()
		if actor:continue
		if str(node.name) in ["PlayerArt","EnemyArt0","EnemyArt1","EnemyArt2"]:continue
		var old: ShaderMaterial=node.material as ShaderMaterial
		var source: String=old.shader.code if old!=null else "shader_type canvas_item;\nvoid fragment(){}"
		var key: String=source+str(id<2)
		if not compiled.has(key):
			var code: String=source
			if code.find("void fragment()")<0:code+="\nvoid fragment(){}"
			code=code.replace("shader_type canvas_item;","shader_type canvas_item;\nuniform vec2 chunk_origin; uniform vec2 chunk_size; varying vec2 chunk_pixel; uniform float e01_far_clean=0.0; uniform sampler2D e01_owner; uniform bool use_e01_owner=false; uniform sampler2D joint_owner; uniform bool use_joint_owner=false; uniform sampler2D next_owner; uniform bool use_next_owner=false;")
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
			end=code.find("{",code.find("void fragment()"))+1
			depth=1
			while depth>0 and end<code.length():
				if code[end]=="{":depth+=1
				if code[end]=="}":depth-=1
				end+=1
			code=code.insert(end-1,"\nif(use_e01_owner) COLOR.a*=texture(e01_owner,clamp((chunk_pixel-chunk_origin)/chunk_size,vec2(0.0),vec2(1.0))).r; COLOR.a*=mix(1.0,smoothstep(800.0,1400.0,chunk_pixel.x-chunk_origin.x),e01_far_clean);\n")
			code=code.insert(end-1,"\nif(use_joint_owner) COLOR.a*=texture(joint_owner,clamp((chunk_pixel-chunk_origin)/chunk_size,vec2(0.0),vec2(1.0))).r;\n")
			code=code.insert(end-1,"\nif(use_next_owner) COLOR.a*=texture(next_owner,clamp((chunk_pixel-chunk_origin)/chunk_size,vec2(0.0),vec2(1.0))).r;\n")
			var shader:=Shader.new()
			shader.code=code
			compiled[key]=shader
		var material:=old.duplicate() as ShaderMaterial if old!=null else ShaderMaterial.new()
		material.shader=compiled[key]
		material.set_shader_parameter("chunk_size",size)
		if id<2:
			material.set_shader_parameter("use_e01_owner",true)
			material.set_shader_parameter("e01_owner",[preload("res://art/xumen-e01/R1-01-ownership.png"),preload("res://art/xumen-e01/R1-02-ownership.png")][id])
		if id==1 and str(chunk.get_path_to(node)).begins_with("ChapterEnvironment/Far/"):
			material.set_shader_parameter("e01_far_clean",1.0)
		if id in [1,2,3,4]:
			var path: String=str(chunk.get_path_to(node))
			var far_layer: bool=path.begins_with("Far/") or path.begins_with("ChapterEnvironment/Far/") or path=="ContinuousOralDepth"
			var world_layer: bool=path.begins_with("World/") or path.begins_with("ChapterEnvironment/World/")
			var owner_edge: String="E02" if id<3 else "E04"
			var owner: String=owner_edge+"-"+("far-owner-" if far_layer else "owner-" if world_layer else "other-owner-")+str(id)
			material.set_shader_parameter("use_joint_owner",true)
			material.set_shader_parameter("joint_owner",load("res://art/xumen-transitions/"+owner+".png"))
		if id in [2,3]:
			var path: String=str(chunk.get_path_to(node))
			var far_layer: bool=path.begins_with("Far/") or path.begins_with("ChapterEnvironment/Far/") or path=="ContinuousOralDepth"
			var owner: String="E03-"+("far-owner-" if far_layer else "owner-")+str(id)
			material.set_shader_parameter("use_next_owner",true)
			material.set_shader_parameter("next_owner",load("res://art/xumen-transitions/"+owner+".png"))
		node.material=material
		items.append(material)
	materials[id]=items

func move_chunk(id: int,at: Vector2) -> void:
	for material: ShaderMaterial in materials.get(id,[]):
		material.set_shader_parameter("chunk_origin",at)
		material.set_shader_parameter("room_origin",at)
		material.set_shader_parameter("scene_origin",at)
