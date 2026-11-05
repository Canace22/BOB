class_name XumenE01Transition
extends Node2D
## World-authored joint, one clock; no gameplay bodies or replacement controller.
var host: WhalebellyMain
var elapsed: float=0.0
var foreground_enabled: bool=true
var parts: Dictionary={}
var schools: Array[ChapterFishGroup]=[]
var emitters: Array[EnvironmentBubbleEmitter]=[]
var fronds: Array[WhalebellyBaleenFrames]=[]

func _ready() -> void:
	name="Transition_E01"
	process_mode=Node.PROCESS_MODE_PAUSABLE
	plate("E01_DEPTH", "depth",Vector2(845,-264.153),-28)
	plate("E01_MID_ARCH","arch",Vector2(1389,-20.153),-1)
	if "E33" in XumenAuthoredShafts.EDGES:parts.E01_MID_ARCH.texture=load("res://art/xumen-vertical/E33-e01-arch-top.png")
	plate("E01_WORLD_GROUND","ground",Vector2(1100,531.847),12)
	plate("E01_FRONT","foreground",Vector2(845,-530),15)
	for i: int in range(2):
		var school:=ChapterFishGroup.new()
		school.name="E01_FISH_"+str(i)
		school.bounds=Rect2(1700+i*230,300+i*95,220,100)
		school.population=10+i*2
		school.species=i
		school.phase=1.8+i*2.1
		school.z_index=-18
		add_child(school);schools.append(school)
		var emitter:=EnvironmentBubbleEmitter.new()
		emitter.name="E01_BUBBLE_"+str(i)
		emitter.bounds=Rect2(1780+i*300,250,60,360)
		emitter.population=5
		emitter.external_clock=true
		emitter.seed_id=210+i*37
		emitter.base_speed=12
		emitter.bubble_opacity=.22
		emitter.z_index=0
		add_child(emitter);emitters.append(emitter)
	for i: int in range(3):
		var frond: WhalebellyBaleenFrames=load("res://content/whalebelly/environment/elements/BALEEN-RIGHT.tscn").instantiate()
		frond.name="E01_FLEX_"+str(i)
		frond.external_clock=true
		frond.phase_offset_frames=i*13
		frond.flip_h=false
		frond.position=Vector2(1705+i*170,170-i*65)
		frond.scale=Vector2.ONE*(.45+i*.07)
		frond.z_index=0
		add_child(frond);fronds.append(frond)
	update_at(host.clock)

func plate(id: String, asset: String, at: Vector2, depth: int) -> void:
	var art:=Sprite2D.new()
	art.name=id
	art.texture=load("res://art/xumen-e01/"+asset+".png")
	art.centered=false
	art.position=at
	art.z_index=depth
	add_child(art);parts[id]=art

func _process(_dt: float) -> void:
	visible=not host.reference_visible and host.layer_solo<0 and host.capture_path.is_empty()
	var absolute_camera: Vector2=host.camera.position+host.connected_world.origin
	parts.E01_FRONT.position=Vector2(845,-530)-(absolute_camera-Vector2(1927,456))*.008
	parts.E01_FRONT.visible=foreground_enabled
	update_at(host.clock)

func update_at(time: float) -> void:
	elapsed=time
	for school: ChapterFishGroup in schools:school.update_at(time)
	for emitter: EnvironmentBubbleEmitter in emitters:emitter.update_at(time)
	for frond: WhalebellyBaleenFrames in fronds:frond.update_at(time)
	if parts.has("E01_DEPTH"):
		parts.E01_DEPTH.modulate=Color.WHITE*(1.0+sin(time*TAU/12.0)*.012)

func snapshot() -> Dictionary:
	return {"edge":"E01","time":elapsed,"plates":parts.size(),"fish":22,"bubbles":10,"flex":fronds.size(),"clock":"host.clock","world_origin":[position.x,position.y]}
