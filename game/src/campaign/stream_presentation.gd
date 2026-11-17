class_name CampaignStreamPresentation
extends RefCounted
## 逐绘图节点淡化房间外沿，保留原有层级、遮挡及环境 Shader 的计算。

const EDGE_FADE: float = 100.0
const EDGE_SHADER: Shader = preload("res://src/campaign/stream_room_edges.gdshader")
const UNIFORMS := "\nuniform vec2 stream_room_origin = vec2(0.0);\nuniform vec2 stream_room_size = vec2(1.0);\nuniform float stream_fade_width = 100.0;\nuniform bool stream_preserve_outline = false;\nuniform bool stream_soft_beam = false;\nuniform sampler2D stream_content_mask : filter_linear, repeat_disable;\nuniform bool stream_use_content_mask = false;\nuniform bool stream_mask_keep_endpoints = false;\nuniform vec4 seam_patches[4];\nuniform int seam_count=0;\nvarying vec2 stream_world_pixel;\n"
const VERTEX_TAIL := "\nstream_world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;\n"
const REPAINT_UNIFORMS := "\nuniform bool stream_repaint_live_edges=false;\nuniform vec4 stream_repaint_rectangles[24];\nuniform int stream_repaint_count=0;\n"
const REPAINT_FRAGMENT := "\nif(stream_repaint_live_edges){for(int i=0;i<24;i++){if(i>=stream_repaint_count)break;vec4 r=stream_repaint_rectangles[i];if(stream_world_pixel.x>=r.x && stream_world_pixel.y>=r.y && stream_world_pixel.x<r.x+r.z && stream_world_pixel.y<r.y+r.w){COLOR.a=0.0;break;}}}\n"
const FRAGMENT_TAIL := "\nif(stream_use_content_mask){ float keep=stream_mask_keep_endpoints ? 1.0-smoothstep(0.025,0.055,min(UV.x,1.0-UV.x)) : 0.0; COLOR.a*=mix(texture(stream_content_mask,UV).a,1.0,keep); }\nif(stream_soft_beam){ float beam_left=mix(0.39,0.03,UV.y); float beam_right=mix(0.52,0.94,UV.y); COLOR.a*=smoothstep(0.0,0.06,min(UV.x-beam_left,beam_right-UV.x))*smoothstep(0.0,0.18,UV.y)*smoothstep(0.0,0.22,1.0-UV.y); }\nvec2 stream_edge_distance = min(stream_world_pixel - stream_room_origin, stream_room_origin + stream_room_size - stream_world_pixel);\nif(!stream_preserve_outline) COLOR.a *= smoothstep(0.0, max(stream_fade_width, 1.0), min(stream_edge_distance.x, stream_edge_distance.y));\nfloat seam_owner=1.0-smoothstep(140.0,280.0,min(stream_edge_distance.x,stream_edge_distance.y));\nfor(int seam_i=0;seam_i<4;seam_i++){ if(seam_i>=seam_count)break; vec4 patch=seam_patches[seam_i]; vec2 edge=min(stream_world_pixel-patch.xy,patch.xy+patch.zw-stream_world_pixel); COLOR.a*=1.0-seam_owner*smoothstep(0.0,100.0,min(edge.x,edge.y)); }\n"
static var shader_cache: Dictionary = {}

static func apply(scene: Node2D, origin: Vector2, room_size: Vector2) -> void:
	_apply_tree(scene,origin,room_size.max(Vector2.ONE))

static func _apply_tree(node: Node, origin: Vector2, room_size: Vector2) -> void:
	# 旧房远景由完整世界画面替换，中景动件、道路和前景仍保留原节点。
	var parent_node: Node = node.get_parent()
	var chapter_far: bool = node is Sprite2D and parent_node != null and parent_node.name=="Far" and parent_node.get_parent() is ChapterRoomEnvironment
	var reference_far: bool = node is Sprite2D and node.name=="ENV-UNDERPAINT" and parent_node is WhalebellyReferenceEnvironment
	if FileAccess.file_exists(CampaignWorldTerrain.DATA) and CampaignWorldTerrain.owns(node):
		node.hide()
		node.set_meta("stream_master_terrain",true)
		return
	if node is Sprite2D and (CampaignStreamWater.owns(node.texture) or chapter_far or reference_far):
		node.visible = false
		node.set_meta("stream_shared_water",true)
		return
	if node is XumenContinuousDepth:
		node.hide()
		node.set_process(false)
		node.set_meta("stream_shared_water",true)
		return
	if node is CanvasItem and _draws(node):
		var item: CanvasItem = node
		# 邻房已经准备过的材质跨界直接复用，避免边界帧再次复制整房材质。
		if item.get_meta("stream_edge_origin",Vector2.INF)!=origin or item.get_meta("stream_edge_size",Vector2.ZERO)!=room_size:
			var material: ShaderMaterial = _edge_material(item.material)
			material.set_shader_parameter("stream_room_origin",origin)
			material.set_shader_parameter("stream_room_size",room_size)
			material.set_shader_parameter("stream_fade_width",EDGE_FADE)
			# 地形自然轮廓不能随房间矩形消失；仍在下方 seam_patches 内交给补绘。
			var parent: Node = node.get_parent()
			var terrain_art: bool = (parent != null and parent.name == "Art" and parent.get_parent() != null and parent.get_parent().name == "World") or (node.name=="Surface" and parent!=null and parent.name=="World")
			material.set_shader_parameter("stream_preserve_outline",terrain_art)
			# 入库光束有硬三角边，沿自身位图轮廓软化，避免被误看作背景拼缝。
			material.set_shader_parameter("stream_soft_beam",node is Sprite2D and node.texture != null and node.texture.resource_path.ends_with("/fx-cold-beam.png"))
			if node is Sprite2D and node.texture != null:
				var source_path: String = node.texture.resource_path
				if terrain_art and source_path.contains("/R1-03/World.png"):
					# 重绘仅接管舌台两端的静态岸线；中部680..1000的下垂膜保持实时。
					var rectangles: PackedVector4Array=CampaignWorldTerrain.repaint_rectangles()
					material.set_shader_parameter("stream_repaint_live_edges",true)
					material.set_shader_parameter("stream_repaint_rectangles",rectangles)
					material.set_shader_parameter("stream_repaint_count",rectangles.size())
				if source_path.contains("/r1-chapter-scenes/"):
					var id: String = source_path.get_base_dir().get_file()+"-"+source_path.get_file().trim_suffix(".png")
					var mask_path: String = "res://art/continuous-backdrops-v1/chapter/"+id+".png"
					if ResourceLoader.exists(mask_path):
						material.set_shader_parameter("stream_content_mask",load(mask_path))
						material.set_shader_parameter("stream_use_content_mask",true)
						# 原生遮罩在外画布端会重新描边；两端由连接层接管，保留原图端口余量。
						material.set_shader_parameter("stream_mask_keep_endpoints",source_path.get_file()=="World.png")

			var patches: PackedVector4Array=CampaignSeamArt.patches_for(origin)
			material.set_shader_parameter("seam_patches",patches)
			material.set_shader_parameter("seam_count",0 if terrain_art else mini(patches.size(),4))
			item.material = material
			item.set_meta("stream_edge_origin",origin)
			item.set_meta("stream_edge_size",room_size)
	for child: Node in node.get_children(): _apply_tree(child,origin,room_size)

static func _draws(item: CanvasItem) -> bool:
	# 空容器和碰撞体不参与材质接入，避免意外改变子节点的渲染继承。
	return item is Sprite2D or item is AnimatedSprite2D or item is TextureRect or item is Line2D or item is Polygon2D or item is MeshInstance2D or item is MultiMeshInstance2D or item is NinePatchRect or item is ColorRect or item is GPUParticles2D or item is CPUParticles2D or not item.draw.get_connections().is_empty()

static func _edge_material(source: Material) -> ShaderMaterial:
	if source is ShaderMaterial and source.shader != null:
		var result: ShaderMaterial = source.duplicate(false)
		result.shader = _shader_for(source.shader.code)
		# 更换 Shader 后显式保留参数，环境脚本仍可通过节点 material 更新时间。
		for parameter: Dictionary in source.shader.get_shader_uniform_list():
			var value: Variant = source.get_shader_parameter(str(parameter.name))
			if value != null: result.set_shader_parameter(str(parameter.name),value)
		return result
	var result := ShaderMaterial.new()
	result.shader = EDGE_SHADER
	if source is CanvasItemMaterial:
		# 入库光斑使用加色混合，转为 Shader 时保留原混合和光照语义。
		var blends: Array[String] = ["blend_mix","blend_add","blend_sub","blend_mul","blend_premul_alpha"]
		var modes: Array[String] = [blends[source.blend_mode]]
		if source.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED: modes.append("unshaded")
		elif source.light_mode == CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY: modes.append("light_only")
		result.shader = _shader_for("shader_type canvas_item;\nrender_mode " + ", ".join(modes) + ";\n")
	return result

static func _shader_for(source: String) -> Shader:
	if shader_cache.has(source): return shader_cache[source]
	var code: String = source
	if not source.contains("uniform vec2 stream_room_origin"):
		var declaration := RegEx.new()
		declaration.compile("shader_type\\s+canvas_item\\s*;")
		var header: RegExMatch = declaration.search(code)
		if header == null:
			push_error("Room edge presentation requires a canvas_item shader")
			return EDGE_SHADER
		code = code.insert(header.get_end(),UNIFORMS+REPAINT_UNIFORMS)
		code = _append_function(code,"vertex",VERTEX_TAIL)
		code = _append_function(code,"fragment",FRAGMENT_TAIL+REPAINT_FRAGMENT)
	var shader := Shader.new()
	shader.code = code
	shader_cache[source] = shader
	return shader

static func _append_function(code: String, function: String, tail: String) -> String:
	var pattern := RegEx.new()
	pattern.compile("\\bvoid\\s+" + function + "\\s*\\(\\s*\\)\\s*\\{")
	var body_match: RegExMatch = pattern.search(code)
	if body_match == null: return code + "\nvoid " + function + "() {" + tail + "}\n"
	var depth: int = 1
	var cursor: int = body_match.get_end()
	# 配对完整函数体，跳过注释中的括号，不能插到原 Shader 的 if/for 分支中。
	while cursor < code.length():
		var pair: String = code.substr(cursor,2)
		if pair == "//":
			var newline: int = code.find("\n",cursor+2)
			cursor = code.length() if newline < 0 else newline+1
			continue
		if pair == "/*":
			var end: int = code.find("*/",cursor+2)
			cursor = code.length() if end < 0 else end+2
			continue
		if code[cursor] == "{": depth += 1
		elif code[cursor] == "}":
			depth -= 1
			if depth == 0: return code.insert(cursor,tail)
		cursor += 1
	push_error("Unbalanced canvas shader function: " + function)
	return code
