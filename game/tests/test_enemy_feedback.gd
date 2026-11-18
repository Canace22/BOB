extends TestSuite

func test_streamed_enemy_flash_drives_current_material_and_clears() -> void:
	var actor := Node2D.new()
	var sprite := Sprite2D.new()
	actor.add_child(sprite)
	add(actor)
	var feedback := TideEnemyFeedback.new()
	actor.add_child(feedback)
	feedback.setup(sprite)
	var original := sprite.material as ShaderMaterial
	CampaignStreamPresentation.apply(actor,Vector2.ZERO,Vector2(1600,1000))
	var current := sprite.material as ShaderMaterial
	check(current != original,"room presentation replaces material")
	check(current.shader.code.contains("stream_room_origin"),"streaming edge behavior is retained")
	feedback.receive(0.05,1.0,3.0)
	eq(feedback.materials[0],current,"feedback follows the displayed material")
	check(is_equal_approx(float(current.get_shader_parameter("flash")),1.0),"current enemy visibly flashes")
	feedback.clear()
	check(is_zero_approx(float(current.get_shader_parameter("flash"))),"reset restores normal color")
