from pathlib import Path
p=Path('BOB/godot/WhalebellyRuins/scripts/main.gd');s=p.read_text(encoding='utf-8');s=s.replace('var zoomed: bool = false','var zoomed: bool = false\nvar reference_follow: bool = true\nvar camera_room_id: String = ""')
a=s.index('func update_camera()');b=s.index('func _process(',a)
s=s[:a]+'''func reference_camera_active() -> bool:
	return room.get("layered_environment",false) and reference_follow and capture_path.is_empty() and layer_solo < 0

func update_camera() -> void:
	if (zoomed or reference_camera_active()) and not reference_visible:
		camera.zoom = Vector2.ONE
		var size: Vector2 = get_viewport_rect().size
		var margin: float = 28.0 if room.get("layered_environment",false) else 0.0
		var target := Vector2(clampf(player.position.x, size.x/2+margin, maxf(size.x/2+margin,float(room.size[0])-size.x/2-margin)),clampf(player.position.y-170.0,size.y/2+12.0,maxf(size.y/2+12.0,float(room.size[1])-size.y/2-12.0)))
		if room.get("layered_environment",false) and camera_room_id==str(room.id):
			camera.position=camera.position.lerp(target,1.0-exp(-get_process_delta_time()*6.0))
		else: camera.position=target
	else:
		var fit: float = minf(get_viewport_rect().size.x/float(room.size[0]),get_viewport_rect().size.y/float(room.size[1]))
		camera.zoom=Vector2.ONE*fit
		camera.position=point(room.size)*0.5
	camera_room_id=str(room.id)

'''+s[b:]
s=s.replace('KEY_TAB: zoomed = not zoomed','''KEY_TAB:
			if room.get("layered_environment",false):
				reference_follow=not reference_follow
				zoomed=false
			else: zoomed=not zoomed''')
s=s.replace('environment.level_camera_offset = Vector2(clampf(shift.x,-5,5),clampf(shift.y,-2,2))','''var offset := Vector2.ZERO
		if (zoomed or reference_camera_active()) and not reference_visible and layer_solo<0 and capture_path.is_empty():
			offset=(camera.position-point(room.size)*0.5)/(1671.0/1280.0)
		environment.level_camera_offset=Vector2(clampf(offset.x,-128.0,128.0),clampf(offset.y,-18.0,18.0))''')
p.write_text(s,encoding='utf-8',newline='\n')
