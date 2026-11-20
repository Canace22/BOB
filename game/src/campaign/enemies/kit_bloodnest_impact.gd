class_name KitBloodnestImpact
extends Node2D
## Presentation only: six local shrimp recoil; finite bitmap wisps and glints.
const DURATION: float=0.46
var began: float=-10.0
var origin: Vector2
var direction: Vector2=Vector2.RIGHT
var weights: PackedFloat32Array=[]
var sparks: Array[Sprite2D]=[]
var arcs: Array[Line2D]=[]
var hit_count: int=0

func build(filament: Texture2D, population: int) -> void:
	z_index=2
	weights.resize(population)
	for i: int in 8:
		var sprite:=Sprite2D.new()
		sprite.texture=load("res://art/world-kit/fx-particle-soft.png")
		sprite.scale=Vector2.ONE*(3.5+i%3)/sprite.texture.get_width()
		sprite.modulate.a=0.0
		add_child(sprite)
		sparks.append(sprite)
	if filament==null:return
	for i: int in 2:
		var arc:=Line2D.new()
		arc.texture=filament
		arc.texture_mode=Line2D.LINE_TEXTURE_STRETCH
		arc.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		arc.width=24.0-i*6.0
		arc.antialiased=true
		arc.modulate.a=0.0
		add_child(arc)
		arcs.append(arc)

func trigger(clock: float, source: Vector2, members: Array[Dictionary]) -> void:
	began=clock
	hit_count+=1
	weights.fill(0.0)
	var contact:=Vector2(clampf(source.x,-76.0,76.0),clampf(source.y,-34.0,35.0))
	var candidates: Array[int]=[]
	for i: int in members.size():
		if members[i].node.modulate.a>0.25:candidates.append(i)
	candidates.sort_custom(func(a: int,b: int)->bool:return members[a].node.position.distance_squared_to(contact)<members[b].node.position.distance_squared_to(contact))
	origin=members[candidates[0]].node.position if not candidates.is_empty() else contact
	direction=(origin-source).normalized()
	if direction.length_squared()<0.1:direction=Vector2.RIGHT
	for i: int in mini(6,candidates.size()): weights[candidates[i]]=1.0-i*0.075
	update_at(clock)

func envelope(clock: float) -> float:
	var age: float=clock-began
	return smoothstep(0.0,0.045,age)*(1.0-smoothstep(0.11,DURATION,age))

func offset(index: int, clock: float) -> Vector2:
	var amount: float=weights[index]*envelope(clock)
	return (direction*17.0+direction.orthogonal()*sin(index*2.4)*10.0)*amount

func highlight(index: int, clock: float) -> float:
	var age: float=clock-began
	return weights[index]*(1.0-smoothstep(0.035,0.18,age)) if age>=0.0 else 0.0

func update_at(clock: float) -> void:
	var age: float=maxf(0.0,clock-began)
	var fade: float=1.0-smoothstep(0.025,0.28,age)
	for i: int in arcs.size():
		var points:=PackedVector2Array()
		var radius: float=13.0+age*55.0+i*6.0
		for j: int in 18:
			var angle: float=direction.angle()+lerpf(-0.9,0.9,j/17.0)
			points.append(origin+Vector2.from_angle(angle)*radius)
		arcs[i].points=points
		arcs[i].modulate=Color(0.85,0.96,1.0,fade*(0.9-i*0.25))
	for i: int in sparks.size():
		var angle: float=direction.angle()+lerpf(-1.25,1.25,i/7.0)
		sparks[i].position=origin+Vector2.from_angle(angle)*(5.0+age*(40.0+i%3*16.0))+Vector2(0,-age*12.0)
		sparks[i].modulate=Color(1.0,0.87,0.74,(1.0-smoothstep(0.04,0.38,age))*0.85)
