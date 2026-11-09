class_name ChapterPinnedBitmap
extends MeshInstance2D
## Tessellated original pixels, no replacement geometry or gameplay collision.
@export var amplitude: float = 5.0
@export var period: float = 8.0
@export var phase: float = 0.0
@export var pin_bottom: bool = false
@export var root_profile := PackedFloat32Array()
var elapsed: float = 0.0

func _ready() -> void:
	var size := texture.get_size()
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns := 12
	var rows := 24
	for y in range(rows + 1):
		for x in range(columns + 1):
			var point := Vector2(float(x)/columns,float(y)/rows)
			vertices.append(Vector3(point.x*size.x,point.y*size.y,0))
			uv.append(point)
	for y in rows:
		for x in columns:
			var i := y * (columns + 1) + x
			indices.append_array(PackedInt32Array([i,i+1,i+columns+1,i+1,i+columns+2,i+columns+1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var grid := ArrayMesh.new()
	grid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh = grid
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://src/world/scenery/chapter/pinned_bitmap.gdshader")
	surface.set_shader_parameter("amplitude",amplitude)
	surface.set_shader_parameter("period",period)
	surface.set_shader_parameter("phase",phase)
	surface.set_shader_parameter("pin_bottom",pin_bottom)
	if root_profile.size()!=13:
		root_profile.resize(13)
	surface.set_shader_parameter("root_heights",root_profile)
	material = surface
	update_at(0)

func update_at(time: float) -> void:
	elapsed = time
	(material as ShaderMaterial).set_shader_parameter("clock",fposmod(time,period))
