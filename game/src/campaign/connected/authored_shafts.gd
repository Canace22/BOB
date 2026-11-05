class_name XumenAuthoredShafts
extends Node2D
## Portrait-native bone spines, distinct original-top aligned ledges.
const EDGES: Array[String]=["E33"]
var host: WhalebellyMain
var parts: Dictionary={}
var schools: Array[ChapterFishGroup]=[]
var emitters: Array[EnvironmentBubbleEmitter]=[]
var elapsed: float=0.0

func _ready() -> void:
	name="AuthoredShafts"
	process_mode=Node.PROCESS_MODE_PAUSABLE
	for edge: String in EDGES:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/xumen-vertical/"+edge+"-placement.json"))
		var group: Dictionary={}
		for item: Dictionary in data.instances:
			var sprite:=Sprite2D.new()
			sprite.name=item.id
			sprite.texture=load("res://art/xumen-vertical/"+str(item.file))
			sprite.position=Vector2(item.at[0],item.at[1])
			sprite.centered=false;sprite.z_index=int(item.z)
			if str(item.id).ends_with("spine"):sprite.modulate=Color(.65,.69,.75,1.0)
			add_child(sprite);group[str(item.id)]=sprite
		parts[edge]=group
		var axis: float=2123.0 if edge=="E33" else 3893.0
		var bottom: float=103.847 if edge=="E33" else 190.847
		var rise: float=785.0 if edge=="E33" else 1102.0
		for i: int in range(2):
			var school:=ChapterFishGroup.new()
			school.name=edge+"_FISH_"+str(i)
			school.bounds=Rect2(axis+170,bottom-rise*(.35+.45*i),200,90)
			school.population=6;school.species=i;school.phase=2.1+i*2.6
			school.z_index=-18;add_child(school);schools.append(school)
			var bubble:=EnvironmentBubbleEmitter.new()
			bubble.name=edge+"_BUBBLE_"+str(i)
			bubble.bounds=Rect2(axis+120+i*170,bottom-rise+40,55,rise-30)
			bubble.population=6;bubble.external_clock=true;bubble.seed_id=533+i*57
			bubble.base_speed=15;bubble.bubble_opacity=.20;bubble.z_index=-5
			add_child(bubble);emitters.append(bubble)
	update_at(host.clock)

func _process(_dt: float) -> void:
	visible=not host.reference_visible and host.layer_solo<0 and host.capture_path.is_empty()
	update_at(host.clock)

func update_at(time: float) -> void:
	elapsed=time
	for edge: String in parts:
		parts[edge][edge+"-depth"].modulate=Color(.70,.76,.82,1.0)*(1.0+sin(time*TAU/17.0)*.01)
	for school: ChapterFishGroup in schools:school.update_at(time)
	for bubble: EnvironmentBubbleEmitter in emitters:bubble.update_at(time)

func snapshot() -> Dictionary:
	return {"edges":EDGES,"time":elapsed,"fish":schools.size()*6,"bubbles":emitters.size()*6,"plates":get_child_count()-schools.size()-emitters.size()}
