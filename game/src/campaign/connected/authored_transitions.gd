class_name XumenAuthoredTransitions
extends Node2D
## Per-edge authored bitmap layers; original passage bodies remain authoritative.
var host: WhalebellyMain
var parts: Dictionary={}
var schools: Array[ChapterFishGroup]=[]
var emitters: Array[EnvironmentBubbleEmitter]=[]
var elapsed: float=0.0
const EDGES: Array[String]=["E02","E03"]
const PLATES: Dictionary={
	"E02":{"depth":Vector2(3029,-269.153),"arch":Vector2(3460,-253.153),"ground":Vector2(3310,546.847)},
	"E03":{"depth":Vector2(5213,-234.153),"arch":Vector2(5644,-218.153),"ground":Vector2(5494,581.847)}
}

func _ready() -> void:
	name="AuthoredTransitions"
	process_mode=Node.PROCESS_MODE_PAUSABLE
	for edge: String in EDGES:
		var layers: Dictionary={}
		for type: String in PLATES[edge]:
			var art:=Sprite2D.new()
			art.name=edge+"_"+type
			art.texture=load("res://art/xumen-transitions/"+edge+"-"+type+".png")
			art.centered=false
			art.position=PLATES[edge][type]
			art.z_index={"depth":-28,"arch":-1,"ground":12}.get(type,15)
			add_child(art);layers[type]=art
		parts[edge]=layers
		var school:=ChapterFishGroup.new()
		school.name=edge+"_FISH"
		var shift: Vector2=PLATES[edge].depth-PLATES.E02.depth
		school.bounds=Rect2(Vector2(3910,300)+shift,Vector2(250,100))
		school.population=12;school.species=1;school.phase=2.7
		school.z_index=-18
		add_child(school);schools.append(school)
		for i: int in range(2):
			var bubble:=EnvironmentBubbleEmitter.new()
			bubble.name=edge+"_BUBBLE_"+str(i)
			bubble.bounds=Rect2(Vector2(3910+i*290,280)+shift,Vector2(55,310))
			bubble.population=4; bubble.external_clock=true
			bubble.seed_id=310+i*43; bubble.base_speed=11
			bubble.bubble_opacity=.19; bubble.z_index=0
			add_child(bubble);emitters.append(bubble)
	update_at(host.clock)

func _process(_dt: float) -> void:
	visible=not host.reference_visible and host.layer_solo<0 and host.capture_path.is_empty()
	update_at(host.clock)

func update_at(time: float) -> void:
	elapsed=time
	for edge: String in parts:
		parts[edge].depth.modulate=Color(.65,.71,.77,1.0)*(1.0+sin(time*TAU/14.0)*.01)
	for school: ChapterFishGroup in schools:school.update_at(time)
	for bubble: EnvironmentBubbleEmitter in emitters:bubble.update_at(time)

func snapshot() -> Dictionary:
	return {"edges":EDGES,"plates":parts.size()*3,"time":elapsed,"fish":12*schools.size(),"bubbles":4*emitters.size()}
