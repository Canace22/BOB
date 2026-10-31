class_name ChapterFishGroup
extends Node2D
## Reuses approved painted swim atlases; choreography owns a separate timeline.
@export var bounds := Rect2(0,0,250,110)
@export var population: int = 18
@export var species: int = 0
@export var phase: float = 0.0
var sprites: Array[Sprite2D] = []
var elapsed: float = 0.0

func _ready() -> void:
	var names: Array[String] = ["silverfin","tealback"]
	var atlas := load("res://art/environment/fish_schools/"+names[species]+"/swim_atlas.png") as Texture2D
	for i in population:
		var fish := Sprite2D.new()
		fish.name = "Fish%02d" % i
		fish.texture = atlas
		fish.hframes = 8
		fish.vframes = 4
		fish.scale = Vector2.ONE * (8.0 + float(i%5)*1.5) / 272.0
		add_child(fish)
		sprites.append(fish)
	update_at(0)

func update_at(time: float) -> void:
	elapsed = time
	for i in sprites.size():
		var offset := float(i)*0.73+phase
		var q := time*TAU/24.0+offset*0.035
		var fish := sprites[i]
		fish.position = bounds.get_center() + Vector2(sin(q)*bounds.size.x*.17,cos(q*2.0)*bounds.size.y*.06)
		fish.position += Vector2((fmod(float(i)*.618,1.0)-.5)*bounds.size.x*.68,(fmod(float(i)*.381,1.0)-.5)*bounds.size.y*.70)
		fish.frame = int(floor(fposmod(time/4.0+offset,1.0)*32))
		var facing := cos(q)
		fish.scale.x = (8.0+float(i%5)*1.5)/272.0 * (-1.0 if facing<0 else 1.0) * (.16+.84*absf(facing))
		fish.modulate = Color(.65,.82,.92,.48)
