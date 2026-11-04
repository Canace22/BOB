class_name XumenPhysicalPassages
extends Node2D
## Painted modular floor and collision share the same authored top edge.
var layout: XumenConnectedLayout
var host: WhalebellyMain
var gates: Array[Dictionary]=[]
var supports: int=0
const FLOOR=preload("res://art/xumen-connected/floor.png")
const BACK=preload("res://art/xumen-connected/background.png")
const FRONT=preload("res://art/xumen-connected/foreground.png")
const LEDGE=preload("res://art/xumen-connected/ledge.png")
const SHAFT=preload("res://art/xumen-connected/shaft-background.png")
const SHAFT_WALLS=preload("res://art/xumen-connected/shaft-walls.png")

func _ready() -> void:
	name="PhysicalChapterPassages"
	process_mode=Node.PROCESS_MODE_PAUSABLE
	for edge: Dictionary in layout.edges:
		var points: PackedVector2Array=edge.points
		if str(edge.id) in ["E33","E35"]:
			var begin: Vector2=points[1]
			var end: Vector2=points[-2]
			var count: int=ceili(absf(end.y-begin.y)/130)
			shaft_backdrop(begin,end)
			floor_span(Vector2(minf(points[0].x,begin.x),begin.y),Vector2(maxf(points[0].x,begin.x),begin.y),str(edge.id)+"_lower",62)
			for i: int in range(count+1):
				var at: Vector2=begin.lerp(end,float(i)/count)
				floor_span(at-Vector2(105,0),at+Vector2(105,0),str(edge.id)+"_"+str(i),62)
			floor_span(Vector2(minf(end.x,points[-1].x),end.y),Vector2(maxf(end.x,points[-1].x),end.y),str(edge.id)+"_upper",62)
		else:
			floor_span(points[0]-Vector2(18,0),points[-1]+Vector2(18,0),str(edge.id))
			if str(edge.id)!="E01":backdrop((points[0]+points[-1])*.5)
		if not str(edge.ability).is_empty():gate(edge,points[0])

func floor_span(a: Vector2,b: Vector2,id: String,depth: float=300) -> void:
	var body:=StaticBody2D.new()
	body.name="Floor_"+id
	body.collision_layer=1
	body.collision_mask=0
	add_child(body)
	var polygon:=CollisionPolygon2D.new()
	polygon.polygon=PackedVector2Array([a,b,b+Vector2(0,38),a+Vector2(0,38)])
	polygon.one_way_collision=depth<100
	body.add_child(polygon)
	if depth<100:
		var ledge:=Sprite2D.new()
		ledge.texture=LEDGE
		ledge.centered=false
		var ratio: float=(b.x-a.x+24)/LEDGE.get_width()
		ledge.scale=Vector2.ONE*ratio
		ledge.position=a-Vector2(12,79*ratio)
		ledge.z_index=2
		body.add_child(ledge)
		supports+=1
		return
	if id=="E01":
		supports+=1
		return
	var art:=Polygon2D.new()
	art.name="PaintedFloor"
	art.texture=FLOOR
	art.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	art.polygon=PackedVector2Array([a,b,b+Vector2(0,depth),a+Vector2(0,depth)])
	art.uv=PackedVector2Array([Vector2(0,0),Vector2(b.x-a.x,0),Vector2(b.x-a.x,depth),Vector2(0,depth)])
	art.z_index=2
	body.add_child(art)
	supports+=1

func shaft_backdrop(begin: Vector2,end: Vector2) -> void:
	var scale_value: float=(absf(end.y-begin.y)+400)/SHAFT.get_height()
	for layer: int in range(2):
		var art:=Sprite2D.new()
		art.texture=SHAFT if layer==0 else SHAFT_WALLS
		art.position=(begin+end)*.5-Vector2(0,50)
		art.scale=Vector2.ONE*scale_value
		art.z_index=-40 if layer==0 else -35
		add_child(art)

func backdrop(ground: Vector2) -> void:
	var back:=Sprite2D.new()
	back.texture=BACK
	back.centered=false
	back.position=ground-Vector2(768,624)
	back.z_index=-30
	add_child(back)
	var front:=Sprite2D.new()
	front.texture=FRONT
	front.centered=false
	front.position=ground-Vector2(768,624)
	front.z_index=8
	add_child(front)

func gate(edge: Dictionary,at: Vector2) -> void:
	var barrier:=StaticBody2D.new()
	barrier.name="AbilityGate_"+str(edge.id)
	barrier.collision_layer=1
	barrier.position=at-Vector2(0,180)
	add_child(barrier)
	var shape:=CollisionShape2D.new()
	var rectangle:=RectangleShape2D.new()
	rectangle.size=Vector2(28,360)
	shape.shape=rectangle
	barrier.add_child(shape)
	# Also seal the target entry plane, so wall-jumping around the source
	# marker cannot enter an inactive, ability-locked gameplay context.
	var target: int=int(edge.to)
	var seal:=CollisionShape2D.new()
	var entry_shape:=RectangleShape2D.new()
	entry_shape.size=Vector2(28,float(host.rooms[target].size[1])+80)
	seal.shape=entry_shape
	seal.position=layout.origins[target]+Vector2(18,float(host.rooms[target].size[1])*.5)-barrier.position
	barrier.add_child(seal)
	var label:=Label.new()
	label.text={"float":"浮游通路","anchor":"锚环通路","boss":"守卫封锁"}.get(str(edge.ability),"")
	label.add_theme_font_override("font",preload("res://art/fonts/WhalefallUI.ttf"))
	label.add_theme_constant_override("outline_size",5)
	label.position=Vector2(-46,-40)
	label.z_index=30
	barrier.add_child(label)
	gates.append({"edge":edge,"shape":shape,"seal":seal,"label":label})

func unlocked(edge: Dictionary) -> bool:
	if str(edge.ability)=="boss":return host.defeated.get("R1-04:0",false)
	return str(edge.ability).is_empty() or host.has_ability(str(edge.ability))

func on_branch_step(world: Vector2) -> bool:
	for edge: Dictionary in layout.edges:
		if not str(edge.id) in ["E33","E35"]:continue
		var points: PackedVector2Array=edge.points
		if absf(world.x-points[1].x)<125 and world.y>=points[-2].y-10 and world.y<=points[1].y+12:return true
	return false

func _physics_process(_dt: float) -> void:
	for item: Dictionary in gates:
		var open: bool=unlocked(item.edge)
		item.shape.set_deferred("disabled",open)
		item.seal.set_deferred("disabled",open)
		item.label.visible=not open
