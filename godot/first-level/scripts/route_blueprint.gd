extends Node2D
var level: Node2D
var font: Font=ThemeDB.fallback_font

func _draw() -> void:
	if not is_instance_valid(level):return
	var r=level.room
	for x in range(0,int(r.width)+1,2):
		draw_line(Vector2(x*64,0),Vector2(x*64,r.height*64),Color(0.4,0.8,0.9,0.12),1)
	for y in range(0,int(r.height)+1,2):
		draw_line(Vector2(0,y*64),Vector2(r.width*64,y*64),Color(0.4,0.8,0.9,0.12),1)
	for route in r.routes:
		var points=PackedVector2Array()
		for pt in route.points:points.append(Vector2(pt[0],pt[1])*64-Vector2(0,30))
		var color=Color("72e4d7") if route.type=="main" else Color("e5b86b")
		if route.type=="hidden":color=Color("d19ae6")
		if points.size()>1:draw_polyline(points,color,3,true)
	for p in r.platforms:
		var a=Vector2(p.x,p.y)*64
		draw_line(a,a+Vector2(p.w*64,0),Color("fff0b5"),3)
		draw_string(font,a+Vector2(8,-8),str(p.id)+"  ("+str(p.x)+", "+str(p.y)+")  "+str(p.w)+"U",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff0b5"))
	for d in r.doors:
		var at=Vector2(d.x,d.y)*64
		draw_circle(at,8,Color("fcb46e"))
		draw_string(font,at+Vector2(-65,-190),str(d.id)+" → "+str(d.to),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fcb46e"))
	for a in r.get("anchors",[]):
		draw_arc(Vector2(a.x,a.y)*64,4.5*64,0,TAU,48,Color(0.9,0.5,0.4,0.14),1)
