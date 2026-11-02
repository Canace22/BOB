class_name AmbientFishSchool
extends Node2D
## Authored tail frames plus a bounded, fading travel path. No gameplay collision.

const MEMBERS := "res://art/environment/fish-schools.json"
@export_enum("silverfin", "tealback", "lantern") var species: String = "silverfin"
@export_range(1, 28) var member_count: int = 8
@export var travel_width: float = 520.0
@export var period: float = 16.0
@export var reverse: bool = false
var elapsed: float = 0.0
var members: Array[Dictionary] = []
var fish: Array[Sprite2D] = []


func _ready() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MEMBERS))
	var species_index: int = ["silverfin", "tealback", "lantern"].find(species)
	var texture := load("res://art/environment/%s.png" % species) as Texture2D
	for member: Dictionary in metadata.members[species_index].slice(0, member_count):
		members.append(member)
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.hframes = 8
		sprite.vframes = 4
		sprite.scale = Vector2.ONE * float(member.size) / 320.0
		sprite.flip_h = reverse
		add_child(sprite)
		fish.append(sprite)
	_present()


func _process(delta: float) -> void:
	elapsed = fposmod(elapsed + delta, period)
	_present()


func _present() -> void:
	for i in fish.size():
		var member: Dictionary = members[i]
		var phase := fposmod(elapsed / period + float(member.ox) / travel_width + 0.5, 1.0)
		var x := (phase - 0.5) * travel_width
		fish[i].position = Vector2(-x if reverse else x,
			float(member.oy) * 0.5 + sin(TAU * (elapsed / period + float(member.phase))) * 4.0)
		fish[i].modulate.a = smoothstep(0.0, 0.12, phase) * smoothstep(0.0, 0.12, 1.0 - phase)
		fish[i].frame = int(fposmod(elapsed / period * float(member.cycles) + float(member.phase), 1.0) * 32.0)
