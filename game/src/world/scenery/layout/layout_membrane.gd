class_name XumenLayoutMembrane
extends MeshInstance2D
## A bitmap grid lets the existing membrane deformation keep its two ends fixed.
func _ready() -> void:
	var size: Vector2 = texture.get_size()
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns: int = 32
	var rows: int = 4
	for y: int in range(rows+1):
		for x: int in range(columns+1):
			var p := Vector2(float(x)/columns,float(y)/rows)
			vertices.append(Vector3(p.x*size.x,p.y*size.y,0))
			uv.append(p)
	for y: int in rows:
		for x: int in columns:
			var i: int = y*(columns+1)+x
			indices.append_array(PackedInt32Array([i,i+1,i+columns+1,i+1,i+columns+2,i+columns+1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var grid:=ArrayMesh.new()
	grid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh=grid
