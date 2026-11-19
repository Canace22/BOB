class_name KitBloodnestWake
extends Node2D
## Six open, bitmap-textured currents + bounded microbubbles / marine glints.
var filament: Texture2D
var sample_path: Callable
var streams: Array[Line2D]=[]
var particles: Array[Dictionary]=[]

func build() -> void:
	z_index=-2
	for i: int in 6:
		var stream:=Line2D.new()
		stream.texture=filament
		stream.texture_mode=Line2D.LINE_TEXTURE_STRETCH
		stream.width=18.0+i%3*5.0
		stream.antialiased=true
		stream.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(stream)
		streams.append(stream)
	for i: int in 26:
		var sprite:=Sprite2D.new()
		var bubble: bool=i<12
		sprite.texture=load("res://art/whalebelly/reference_environment/bubble.png" if bubble else "res://art/world-kit/fx-particle-soft.png")
		sprite.scale=Vector2.ONE*(3.0+(i%4)*0.7)/sprite.texture.get_width()
		add_child(sprite)
		particles.append({"node":sprite,"phase":i*2.399963,"bubble":bubble})

func update_at(clock: float, formation: float, facing: float, drive: float=0.0) -> void:
	for i: int in streams.size():
		var stream: Line2D=streams[i]
		var points:=PackedVector2Array()
		var cycle: float=fposmod(clock*0.12+i*0.167,1.0)
		var start: float=clampf(cycle-0.14,0.0,0.72)
		for j: int in 32:
			var u: float=j/31.0
			var curl: Vector2=sample_path.call(lerpf(start,start+0.28,u),i%3)
			curl.y*=1.08
			var ribbon:=Vector2(lerpf(75.0,-145.0,u)*facing,sin(u*PI)*(i-2.5)*9.0+sin(u*5.0-clock*2.4+i)*7.0)
			points.append(curl.lerp(ribbon,formation))
		stream.points=points
		stream.modulate=Color(0.63,0.85,1.0,(0.38+drive*0.22+0.07*sin(clock*1.2+i))*sin(cycle*PI))
	for i: int in particles.size():
		var particle: Dictionary=particles[i]
		var sprite: Sprite2D=particle.node
		var phase: float=float(particle.phase)
		var cycle: float=fposmod(clock*(0.13 if particle.bubble else 0.18)+i*0.618,1.0)
		var angle: float=phase+clock*0.42
		var curl:=Vector2(cos(angle)*(76.0+i%5*9.0),lerpf(47.0,-69.0,cycle))
		var ribbon:=Vector2(lerpf(42.0,-145.0,cycle)*facing,sin(phase)*39.0+sin(clock+phase)*5.0)
		sprite.position=curl.lerp(ribbon,formation)
		var alpha: float=sin(cycle*PI)*0.42
		sprite.modulate=Color(0.72,0.88,1.0,alpha) if particle.bubble else Color(1.0,0.8,0.67,alpha*0.65)

func bend_at(origin: Vector2, direction: Vector2, strength: float) -> void:
	if strength<=0.0:return
	for stream: Line2D in streams:
		for i: int in stream.get_point_count():
			var point_: Vector2=stream.get_point_position(i)
			var influence: float=exp(-point_.distance_squared_to(origin)/1900.0)
			stream.set_point_position(i,point_+direction.orthogonal()*influence*strength*9.0)
