extends Sprite2D
## One reusable painted 2D animation element. Open any element .tscn with F6.
@export_enum("foliage", "fish", "light", "caustic", "parallax", "static") var animation_kind: String = "foliage"
@export var amplitude_px: float = 5.0
@export var period: float = 7.0
@export var phase: float = 0.0
@export var root_at_bottom: bool = false
@export var source_origin: Vector2 = Vector2.ZERO
@export var parallax_amount: float = 0.0
@export var swim_extent: Vector2 = Vector2(34,4)
@export var swim_period: float = 28.0
@export var intensity: float = 1.0
@export var external_clock: bool = false
var time: float = 0.0
var home: Vector2

func _ready() -> void:
	home=position
	if animation_kind in ["foliage","caustic"]:
		var mat := ShaderMaterial.new()
		mat.shader=load("res://scenes/environment/elements/"+("pinned_foliage.gdshader" if animation_kind=="foliage" else "caustic.gdshader"))
		material=mat
		mat.set_shader_parameter("root_at_bottom",root_at_bottom)
		mat.set_shader_parameter("source_origin",source_origin)
		mat.set_shader_parameter("curtain",str(name).begins_with("BALEEN"))
		mat.set_shader_parameter("amplitude",amplitude_px)
		mat.set_shader_parameter("period",period)
		mat.set_shader_parameter("phase",phase)
	if animation_kind=="light":
		var mat := CanvasItemMaterial.new();mat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD;material=mat
	update_at(0.0)

func _process(delta: float) -> void:
	if external_clock: return
	time+=delta
	update_at(time)

func update_at(t: float, camera_offset: Vector2 = Vector2.ZERO) -> void:
	time=t
	position=home+camera_offset*parallax_amount
	if animation_kind=="fish":
		var a := t*TAU/swim_period
		var left: float=545.0 if str(name).begins_with("FISH-02") else 840.0
		var distance: float=fposmod(home.x-left-t*220.0/swim_period,220.0)
		position.x=left+distance+camera_offset.x*parallax_amount
		position.y+=sin(a*2.0+phase)*swim_extent.y-sin(phase)*swim_extent.y
		# Continuous school flow. Invisible boundary recycling avoids synchronized paper turns.
		flip_h=false
		modulate.a=smoothstep(0.0,22.0,minf(distance,220.0-distance))
		frame=int(floor(t*12.0/period+phase*12.0/TAU))%12
	elif animation_kind in ["foliage","caustic"]:
		material.set_shader_parameter("clock",t)
		modulate.a=intensity
	elif animation_kind=="light":
		modulate.a=intensity*(0.85+0.15*sin(t*TAU/period+phase))
