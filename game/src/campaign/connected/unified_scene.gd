class_name XumenUnifiedScene
extends Node2D
## One world-space art master; art ownership is independent of room contexts.
const ACTIVE: bool=true
var host: WhalebellyMain
var groups: Dictionary={}
var parts: Dictionary={}
var fish_groups: Array[ChapterFishGroup]=[]
var bubbles: Array[EnvironmentBubbleEmitter]=[]
var baleen: Array[WhalebellyBaleenFrames]=[]
var flexible: Array[ChapterPinnedBitmap]=[]
var elapsed: float=0
var foreground_enabled: bool=true
var sprites: Array[Dictionary]=[]
var terrain_count: int=0
var water_material: ShaderMaterial

func _ready() -> void:
	name="UnifiedXumen"
	process_mode=Node.PROCESS_MODE_PAUSABLE
	for layer: String in ["Far","Middle","World","Foreground"]:groups[layer]=get_node(layer)
	# Standalone editor preview retains the complete static composition.
	if not is_instance_valid(host):return
	water_material=groups.Far.get_child(0).material
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/xumen-unified/scene.json"))
	for item: Dictionary in data.meshes:
		var mesh: Polygon2D=get_node(str(item.layer)+"/"+str(item.id))
		parts[str(item.id)]=mesh;terrain_count+=1
	for item: Dictionary in data.instances:
		var art: Sprite2D=get_node(str(item.layer)+"/"+str(item.id))
		parts[str(item.id)]=art
		sprites.append({"node":art,"kind":str(item.kind),"base":art.position,"scale":art.scale})
		if item.kind=="kelp":
			var flex:=ChapterPinnedBitmap.new();flex.texture=art.texture
			flex.position=art.position;flex.scale=art.scale;flex.pin_bottom=true
			flex.amplitude=2;flex.period=11;flex.phase=sprites.size()*.7;flex.z_index=art.z_index
			art.hide();groups[item.layer].add_child(flex);flexible.append(flex)
	create_motion()
	update_at(host.clock)

func create_motion() -> void:
	for i: int in range(8):
		var fish:=ChapterFishGroup.new();fish.bounds=Rect2(450+i*1240,300+(i%3)*90,330,100)
		fish.population=10;fish.species=i%2;fish.phase=i*1.9;fish.z_index=-32
		groups.Middle.add_child(fish);fish_groups.append(fish)
		var emitter:=EnvironmentBubbleEmitter.new();emitter.bounds=Rect2(330+i*1260,80,65,480)
		emitter.population=6;emitter.external_clock=true;emitter.seed_id=900+i*31
		emitter.base_speed=12;emitter.bubble_opacity=.20;emitter.z_index=-5
		groups.Middle.add_child(emitter);bubbles.append(emitter)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/xumen-unified/scene.json"))
	for item: Dictionary in data.fronds:
		var frond: WhalebellyBaleenFrames=load("res://content/whalebelly/environment/elements/BALEEN-RIGHT.tscn").instantiate()
		frond.name=item.id;frond.position=Vector2(item.at[0],item.at[1]);frond.scale=Vector2.ONE*float(item.scale)
		frond.external_clock=true;frond.phase_offset_frames=int(item.phase);frond.z_index=-6
		groups.Middle.add_child(frond);baleen.append(frond)
	for i: int in range(2):
		var emitter:=EnvironmentBubbleEmitter.new();emitter.bounds=Rect2(2240+i*1640,-1350,70,1430)
		emitter.population=9;emitter.external_clock=true;emitter.seed_id=1300+i*31;emitter.base_speed=16
		emitter.bubble_opacity=.17;emitter.z_index=-5;groups.Middle.add_child(emitter);bubbles.append(emitter)

func _process(_dt: float) -> void:
	if not is_instance_valid(host) or host.quitting:return
	visible=not host.reference_visible
	for chunk: Variant in host.connected_world.chunks.values():
		if is_instance_valid(chunk):suppress_legacy(chunk)
	for legacy: Node2D in [host.connected_world.e01,host.connected_world.authored,host.connected_world.shafts]:
		legacy.hide();legacy.process_mode=Node.PROCESS_MODE_DISABLED
	host.connected_world.far_underpaint.hide()
	host.player.z_index=8
	var selected: int=host.layer_solo
	var names: Array[String]=["Far","Middle","World","Foreground"]
	for i: int in range(4):groups[names[i]].visible=selected<0 or selected==i
	groups.Foreground.visible=groups.Foreground.visible and foreground_enabled
	var camera: Vector2=host.camera.position+host.connected_world.origin
	groups.Far.position=(camera-Vector2(5000,-300))*.006
	groups.Foreground.position=-(camera-Vector2(5000,600))*.015
	update_at(host.clock)

func update_at(time: float) -> void:
	elapsed=time
	water_material.set_shader_parameter("clock",time)
	water_material.set_shader_parameter("chapter_origin",host.connected_world.origin)
	for school: ChapterFishGroup in fish_groups:school.update_at(time)
	for emitter: EnvironmentBubbleEmitter in bubbles:emitter.update_at(time)
	for frond: WhalebellyBaleenFrames in baleen:frond.update_at(time)
	for flex: ChapterPinnedBitmap in flexible:flex.update_at(time)
	for item: Dictionary in sprites:
		var node: Sprite2D=item.node
		if item.kind=="lamp":node.modulate=Color.WHITE*(1+sin(time*TAU/9+item.base.x*.01)*.025)
		if str(item.kind).begins_with("memory:"):
			var index: int=str(item.kind).get_slice(":",1).to_int()
			node.visible=not host.collected.get(str(host.rooms[index].id),false)
			node.position=item.base+Vector2(0,sin(time*TAU/5)*2)
		if item.kind=="gate":node.visible=not host.defeated.get("R1-04:0",false)
	var drop: float=0
	var tongue: Node=host.connected_world.chunks.get(2)
	if tongue!=null:
		var mechanism: Node=tongue.get_node_or_null("VisualMechanisms")
		if mechanism!=null:drop=mechanism.membrane_drop
	for id: String in ["MAIN-JAW-ROAD-body","MAIN-JAW-ROAD-rim"]:
		if parts.has(id):parts[id].material.set_shader_parameter("membrane_drop",drop)

func snapshot() -> Dictionary:
	return {"method":"unified-world-master+painted-texture-terrain","time":elapsed,"meshes":terrain_count,"sprites":sprites.size(),"fish":fish_groups.size()*10,"bubbles":66,"baleen":baleen.size(),"flex":flexible.size(),"old_static":false}

static func suppress_legacy(chunk: Node2D) -> void:
	for path: String in ["Far","Middle","Foreground","World/WorldOriginalPixels","World/RewardArt","World/DoorArt","ContinuousOralDepth"]:
		var item: CanvasItem=chunk.get_node_or_null(path)
		if item!=null:item.hide()
	for path: String in ["ReferenceEnvironment","ChapterEnvironment","EnvironmentMotion"]:
		var environment: CanvasItem=chunk.get_node_or_null(path)
		if environment!=null:
			environment.hide();environment.process_mode=Node.PROCESS_MODE_DISABLED
			if not environment.has_meta("unified_disabled"):
				for child: Node in environment.find_children("*","Node",true,false):child.process_mode=Node.PROCESS_MODE_DISABLED
				environment.set_meta("unified_disabled",true)
	for child: Node in chunk.get_children():
		if str(child.name).begins_with("Continuity_") and child is CanvasItem:child.hide()
