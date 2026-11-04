class_name XumenConnectedLayout
extends RefCounted
## Absolute chapter coordinates. Original room geometry remains unscaled.
var origins: Array[Vector2] = []
var edges: Array[Dictionary] = []
var bounds: Rect2

func configure(rooms: Array) -> void:
	origins=[Vector2.ZERO]
	for i: int in range(1,5):
		var last: Array=rooms[i-1].surfaces[0]
		var first: Array=rooms[i].surfaces[0]
		origins.append(origins[i-1]+Vector2(float(rooms[i-1].size[0])+512,float(last[-1][1])-float(first[0][1])))
	origins.append(origins[1]+Vector2(100,-1390))
	origins.append(origins[1]+Vector2(1850,-1390))
	for i: int in range(4):
		var a:=origins[i]+Vector2(float(rooms[i].size[0])-8,float(rooms[i].surfaces[0][-1][1]))
		var b:=origins[i+1]+Vector2(8,float(rooms[i+1].surfaces[0][0][1]))
		edges.append({"id":"E0"+str(i+1),"from":i,"to":i+1,"points":PackedVector2Array([a,b]),"ability":"boss" if i==3 else ""})
	# Both branches emerge from the two existing upper exits in the hub.
	var left:=origins[1]+Vector2(150,190)
	var left_end:=origins[5]+Vector2(100,795)
	var left_shaft: float=origins[5].x-160
	edges.append({"id":"E33","from":1,"to":5,"points":PackedVector2Array([left,Vector2(left_shaft,left.y),Vector2(left_shaft,left_end.y),left_end]),"ability":"float"})
	var right:=origins[1]+Vector2(1660,277)
	var right_end:=origins[6]+Vector2(12,565)
	var right_shaft: float=origins[6].x-140
	edges.append({"id":"E35","from":1,"to":6,"points":PackedVector2Array([right,Vector2(right_shaft,right.y),Vector2(right_shaft,right_end.y),right_end]),"ability":"anchor"})
	bounds=Rect2(origins[0],Vector2(rooms[0].size[0],rooms[0].size[1]))
	for i: int in range(rooms.size()):bounds=bounds.merge(Rect2(origins[i],Vector2(rooms[i].size[0],rooms[i].size[1])))

func absolute(index: int, local: Vector2) -> Vector2:
	return origins[index]+local

func containing(at: Vector2, rooms: Array, current: int) -> int:
	for i: int in range(rooms.size()):
		if i==current:continue
		var area:=Rect2(origins[i]+Vector2(22,0),Vector2(float(rooms[i].size[0])-44,float(rooms[i].size[1])))
		if area.has_point(at):return i
	return current
