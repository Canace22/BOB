extends Node2D
@export var bounds: Rect2 = Rect2(0,0,100,240)
@export var population: int = 9
@export var seed_id: int = 0
@export var near_layer: bool = false
@export var external_clock: bool = false
var bubbles: Array[Dictionary] = []
var time: float = 0.0
var recycled: int = 0
func _ready() -> void:
	for i in range(population):
		var sprite := Sprite2D.new()
		sprite.name="Bubble_%02d"%i
		sprite.texture=preload("res://assets/reference_environment/bubble.png")
		var near_bubble: bool=near_layer and i<3
		var size_px: float=(10.0+float(i)*3.0) if near_bubble else 3.0+fmod(float(i*17+seed_id*3),5.0)
		sprite.scale=Vector2.ONE*size_px/12.0
		if near_bubble: sprite.z_index=45-z_index
		add_child(sprite)
		bubbles.append({"node":sprite,"bounds":Rect2(1060,405,74,255) if near_bubble else bounds,"speed":24.0+float(i)*3.0 if near_bubble else 12.0+float(i%7),"opacity":0.58 if near_bubble else 0.36,"near":near_bubble,"index":i,"last_cycle":0})
	update_at(0.0)
func _process(delta: float) -> void:
	if not external_clock:
		time+=delta
		update_at(time)
func update_at(t: float) -> void:
	time=t
	for bubble in bubbles:
		var r: Rect2=bubble.bounds
		var distance: float=t*bubble.speed+float(bubble.index)/float(population)*r.size.y
		var cycle := int(distance/r.size.y)
		if cycle>bubble.last_cycle: recycled+=cycle-bubble.last_cycle
		bubble.last_cycle=cycle
		var y: float=r.end.y-fmod(distance,r.size.y)
		var x: float=r.position.x+r.size.x*(0.18+fmod(float(bubble.index)*0.367,0.64))+sin(t*0.7+float(bubble.index))*3.0
		bubble.node.position=Vector2(x,y)
		bubble.node.modulate.a=smoothstep(0.0,26.0,minf(y-r.position.y,r.end.y-y))*bubble.opacity
