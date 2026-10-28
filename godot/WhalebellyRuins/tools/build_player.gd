extends SceneTree
# Rebuild the inspectable Player scene and 12 FPS AnimationPlayer libraries.
func _initialize() -> void:
	call_deferred("build")
func build() -> void:
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animations/player/manifest.json"))
	var full:=AnimationLibrary.new()
	var game:=AnimationLibrary.new()
	var events:Dictionary={}
	var clips:Dictionary=load("res://scripts/tide_player.gd").CLIPS
	for id in manifest.actions:
		var original:=make_animation(range(36),3.0,id in ["idle","run","A2_float"])
		var source_track:=original.add_track(Animation.TYPE_VALUE)
		original.track_set_path(source_track,NodePath(".:display_action"));original.value_track_set_update_mode(source_track,Animation.UPDATE_DISCRETE);original.track_insert_key(source_track,0,id)
		original.set_meta("source_action",id)
		full.add_animation(id,original)
		var spec:Array=clips[id]
		var duration:float={"idle":3.0,"run":2.0,"jump_land":1.25,"strike_02":.35,"strike_01":.35,"heavy":.55,"hit":.2,"recover":1.5,"interact":.5,"defeat":3.0,"A1_dash":.2,"A2_float":1.166667,"A3_anchor":.35,"A4_parry":.5,"A5_slit":.3}.get(id,3.0)
		var count:int=maxi(2,ceili(duration*12))
		var sequence:Array=[]
		for i in range(count): sequence.append(roundi(lerpf(spec[1],spec[2],float(i)/maxi(1,count-1))))
		var clip:=make_animation(sequence,duration,id in ["idle","run","A2_float"])
		var display_track:=clip.add_track(Animation.TYPE_VALUE)
		clip.track_set_path(display_track,NodePath(".:display_action"));clip.value_track_set_update_mode(display_track,Animation.UPDATE_DISCRETE);clip.track_insert_key(display_track,0,id)
		clip.add_marker("start",0)
		clip.add_marker("end",duration)
		if id in ["strike_01","A3_anchor","A4_parry","heavy"]:
			var release:float=(3.0 if id=="heavy" else 2.0)/12.0
			clip.add_marker("damage" if id in ["strike_01","A3_anchor"] else "release",release)
		if id in ["A1_dash","A5_slit"]:
			clip.add_marker("invulnerable_start",0)
			clip.add_marker("invulnerable_end",duration)
		game.add_animation(id,clip)
		events[id]={"fps":12,"duration":duration,"source_frames":sequence,"events":{}}
		for marker in clip.get_marker_names(): events[id].events[marker]=clip.get_marker_time(marker)
	ResourceSaver.save(full,"res://assets/animations/player/full_library.tres")
	ResourceSaver.save(game,"res://assets/animations/player/game_library.tres")
	var data:=FileAccess.open("res://assets/animations/player/combat_events.json",FileAccess.WRITE)
	data.store_string(JSON.stringify(events,"\t"));data.close()
	var root:=CharacterBody2D.new()
	root.name="Player"
	root.set_script(load("res://scripts/tide_player.gd"))
	var shape:=CollisionShape2D.new();shape.name="CollisionShape2D"
	var rect:=RectangleShape2D.new();rect.size=Vector2(24,32);shape.shape=rect;shape.position.y=-16
	add(root,shape)
	var visual:=Node2D.new();visual.name="Visual";add(root,visual)
	var sprite:=Sprite2D.new();sprite.name="Body";sprite.centered=false;sprite.offset=-Vector2(manifest.pivot[0],manifest.pivot[1]);sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture=load("res://assets/animations/player/body/idle/000.png")
	var mat:=ShaderMaterial.new();mat.shader=load("res://scripts/tide_flash.gdshader");sprite.material=mat
	visual.add_child(sprite);sprite.owner=root
	var effect:=Sprite2D.new();effect.name="Effect";effect.centered=false;effect.offset=sprite.offset;effect.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;visual.add_child(effect);effect.owner=root
	var animator:=AnimationPlayer.new();animator.name="AnimationPlayer";animator.add_animation_library("full",full);animator.add_animation_library("game",game);add(root,animator)
	var tree:=AnimationTree.new();tree.name="AnimationTree";add(root,tree)
	for x in [-10,0,10]:
		var ray:=RayCast2D.new();ray.name="Foot%d"%x;ray.position=Vector2(x,-4);ray.target_position=Vector2(0,8);ray.collision_mask=1;add(root,ray)
	for side in [-1,1]:
		var ray:=RayCast2D.new();ray.name="WallLeft" if side<0 else "WallRight";ray.position=Vector2(0,-16);ray.target_position=Vector2(side*15,0);ray.collision_mask=1;add(root,ray)
	var packed:=PackedScene.new();packed.pack(root);ResourceSaver.save(packed,"res://scenes/Player.tscn");root.free()
	print("PLAYER_SCENE_AND_LIBRARIES_BUILT");quit()
func add(root:Node,node:Node) -> void:
	root.add_child(node);node.owner=root
func make_animation(frames:Variant,duration:float,loop:bool) -> Animation:
	var a:=Animation.new();a.length=duration;a.step=1.0/12.0;a.loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var track:=a.add_track(Animation.TYPE_VALUE);a.track_set_path(track,NodePath(".:visual_frame"));a.value_track_set_update_mode(track,Animation.UPDATE_DISCRETE)
	for i in range(len(frames)):a.track_insert_key(track,minf(float(i)/12,duration-.0001),frames[i])
	return a
