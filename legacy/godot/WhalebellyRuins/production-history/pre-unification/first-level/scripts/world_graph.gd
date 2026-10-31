extends Control
var host: Node
var font: Font=ThemeDB.fallback_font

func _draw() -> void:
	if not is_instance_valid(host):return
	# The overview is an anatomical projection, not a concatenation of local room rectangles.
	var points=[Vector2(130,397),Vector2(335,390),Vector2(610,420),Vector2(950,440),Vector2(1155,420),Vector2(785,250),Vector2(485,285)]
	var edges=[[0,1],[1,2],[2,3],[3,4],[1,5],[1,6]]
	for e in edges:
		var a: Vector2=points[e[0]];var b: Vector2=points[e[1]]
		var color=Color("8ce5d9") if e[1]<5 else Color("d7a4dc")
		draw_line(a,b,color,3,true)
		var mid=a.lerp(b,0.5)
		var direction=(b-a).normalized()
		draw_line(mid,mid-direction.rotated(0.5)*12,color,3,true)
		draw_line(mid,mid-direction.rotated(-0.5)*12,color,3,true)
		if e[1]>=5:draw_string(font,mid+Vector2(0,-8),"A2 / E33" if e[1]==5 else "A3 / E35",HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
	var at: Vector2=points[host.game.room_index]
	draw_arc(at,20,0,TAU,32,Color("ffce77"),4,true)
	draw_string(font,Vector2(30,690),"主路 01 ⇄ 02 ⇄ 03 ⇄ 04 ⇄ 05 → R3-01    支路 02 ⇄ 06 → R2-05远侧锁；02 ⇄ 07（死端返回）",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("dbe9e4"))

	draw_string(font,Vector2(30,650),"解剖压缩投影：06在鼻道外侧旧伤，脑区不进入；07在上颚须根，不能画成头顶出口。",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("d9bfa2"))
