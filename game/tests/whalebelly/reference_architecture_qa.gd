extends "res://tests/whalebelly/remaining_19_qa.gd"
## Original art architecture integrated in the real campaign, renderer fixtures.
func review(id: String) -> void:
	await super.review(id)
	paused=true
	host.zoomed=false
	host.update_camera()
	var base: Image = await frame()
	var pieces: Node2D = host.scenery.get_node("Framing")
	var pixels: int = await contribution(pieces,base)
	check(id+" native architecture actually contributes",pixels>100,pixels)
	for child: Node in pieces.get_children():
		check(id+" framing is behind gameplay "+str(child.name),child.z_index<0)
		var art: Sprite2D = child.get_node("Art")
		check(id+" native uniform scale "+str(child.name),is_equal_approx(absf(art.scale.x),absf(art.scale.y)))
	check(id+" decorative framing contains no collision",pieces.find_children("*","CollisionObject2D",true,false).is_empty())
	if id=="R5-01":
		var a: Sprite2D = host.scenery.get_node("World/ProgressSlot0/After")
		var b: Sprite2D = host.scenery.get_node("World/ProgressSlot1/After")
		var c: Sprite2D = host.scenery.get_node("World/ProgressSlot2/After")
		check("three original marks are horizontal carved sockets",a.position.x<b.position.x and b.position.x<c.position.x and absf(a.position.y-c.position.y)<3.0)
		check("old standalone totem is not rendered",host.scenery.find_children("*progress-three-slots*","Sprite2D",true,false).is_empty())
	paused=false
