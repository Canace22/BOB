extends TestSuite

func test_wall_probes_ignore_one_way_shapes_and_keep_solid_walls() -> void:
	var actor := TidePlayer.new()
	var wall := StaticBody2D.new()
	wall.position = Vector2(10000,10000)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	wall.add_child(shape)
	add(wall)
	var ray := RayCast2D.new()
	ray.position = wall.position-Vector2(40,0)
	ray.target_position = Vector2(80,0)
	add(ray)
	await tree.physics_frame
	ray.force_raycast_update()
	check(ray.is_colliding(),"Probe actually intersects the wall")
	check(actor._wall_probe_hits_solid(ray),"A solid wall still allows a wall jump")
	shape.one_way_collision = true
	ray.force_raycast_update()
	check(ray.is_colliding(),"Ray detection still sees the one-way shape")
	check(not actor._wall_probe_hits_solid(ray),"A one-way shape cannot redirect a double jump")
	shape.queue_free()
	await tree.physics_frame
	var polygon := CollisionPolygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2(-10,-10),Vector2(10,-10),Vector2(10,10),Vector2(-10,10)])
	wall.add_child(polygon)
	await tree.physics_frame
	ray.force_raycast_update()
	check(actor._wall_probe_hits_solid(ray),"Solid authored polygons retain wall jumping")
	polygon.one_way_collision = true
	ray.force_raycast_update()
	check(ray.is_colliding(),"Ray detection still sees the one-way polygon")
	check(not actor._wall_probe_hits_solid(ray),"Authored one-way polygons are also ignored")
	actor.free()
