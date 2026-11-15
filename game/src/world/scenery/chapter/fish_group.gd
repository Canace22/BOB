class_name ChapterFishGroup
extends Node2D
## Reuses approved painted swim atlases; choreography owns a separate timeline.
@export var bounds := Rect2(0,0,250,110)
@export var population: int = 18
@export var species: int = 0
@export var phase: float = 0.0
@export var fish_widths := Vector2(8.0,14.0)
@export var school_tint := Color(.65,.82,.92,.48)
@export var path_seconds: float = 24.0
@export var swim_seconds: float = 4.0
@export var migrate: bool = false
@export var reverse: bool = false
@export var formation_size := Vector2.ZERO
var sprites: Array[Sprite2D] = []
var elapsed: float = 0.0

func _ready() -> void:
	var names: Array[String] = ["silverfin","tealback","lantern"]
	var atlas := load("res://art/whalebelly/fish_schools/"+names[clampi(species,0,2)]+"/swim_atlas.png") as Texture2D
	for i in population:
		var fish := Sprite2D.new()
		fish.name = "Fish%02d" % i
		fish.texture = atlas
		fish.hframes = 8
		fish.vframes = 4
		fish.scale = Vector2.ONE * lerpf(fish_widths.x,fish_widths.y,float(i%5)/4.0) / 272.0
		add_child(fish)
		sprites.append(fish)
	update_at(0)

func update_at(time: float) -> void:
	elapsed = time
	for i in sprites.size():
		var offset := float(i)*0.73+phase
		var q := time*TAU/maxf(path_seconds,0.1)+offset*0.035
		var fish := sprites[i]
		fish.position = bounds.get_center() + Vector2(sin(q)*bounds.size.x*.17,cos(q*2.0)*bounds.size.y*.06)
		var spread := formation_size if formation_size!=Vector2.ZERO else bounds.size*Vector2(.68,.70)
		var envelope: float = 1.0
		if migrate:
			var progress: float = fposmod(time/maxf(path_seconds,0.1)+phase/TAU,1.0)
			var along: float = 1.0-progress if reverse else progress
			fish.position = bounds.position+Vector2(along*bounds.size.x,bounds.size.y*(.5+.08*sin(q)))
			envelope = smoothstep(0.0,.1,minf(progress,1.0-progress))
		var across: float = fmod(float(i)*.618,1.0)-.5
		# Complementary x/y fractions put every member on diagonal rails.
		# Keep the legacy orbit, but give migrating schools a loose stable cloud.
		var cloud: bool = migrate or formation_size!=Vector2.ZERO
		var vertical: float = (.32*sin(float(i)*2.399)+.12*cos(float(i)*.73)) if cloud else fmod(float(i)*.381,1.0)-.5
		fish.position += Vector2(across*spread.x,vertical*spread.y)
		fish.frame = int(floor(fposmod(time/maxf(swim_seconds,0.1)+offset,1.0)*32))
		var facing := cos(q)
		var direction: float = (-1.0 if reverse else 1.0) if migrate else (-1.0 if facing<0 else 1.0)
		var turn: float = 1.0 if migrate else (.16+.84*absf(facing))
		fish.scale.x = lerpf(fish_widths.x,fish_widths.y,float(i%5)/4.0)/272.0*direction*turn
		fish.modulate = Color(school_tint,school_tint.a*envelope)
