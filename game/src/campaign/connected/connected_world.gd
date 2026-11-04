class_name XumenConnectedWorld
extends Node2D
## Persistent geometry, one player, local-coordinate rebasing at room boundaries.
var host: WhalebellyMain
var enabled: bool=false
var layout:=XumenConnectedLayout.new()
var chunks: Dictionary={}
var contexts: Dictionary={}
var origin:=Vector2.ZERO
var passages: XumenPhysicalPassages
var switching: bool=false
var crossings: int=0
var active_index: int=0
var edge_masks:=XumenChunkEdges.new()
var far_underpaint: Sprite2D
var e01: XumenE01Transition
var authored: XumenAuthoredTransitions
var ambience: AudioStreamPlayer
var persistent_projectiles: Node2D
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	if enabled:
		ambience=AudioStreamPlayer.new()
		ambience.name="ChapterWaterAmbience"
		var bed: AudioStreamWAV=preload("res://art/whalebelly/runtime/audio/water_bed.wav").duplicate()
		bed.loop_mode=AudioStreamWAV.LOOP_FORWARD
		bed.loop_begin=0
		bed.loop_end=int(bed.get_length()*bed.mix_rate)
		ambience.stream=bed
		if OS.has_feature("web"):ambience.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		ambience.volume_db=-29
		add_child(ambience)
		ambience.play()
		persistent_projectiles=Node2D.new()
		persistent_projectiles.name="PersistentProjectiles"
		add_child(persistent_projectiles)
func load_room(index: int, spawn: Array=[], discover: bool=true) -> void:
	if chunks.is_empty():
		host._load_isolated_room(index,spawn,discover)
		layout.configure(host.rooms)
		origin=layout.origins[index]
		active_index=index
		chunks[index]=host.scenery
		contexts[index]={"enemies":host.enemies.duplicate()}
		for i: int in range(host.rooms.size()):
			if not chunks.has(i):
				var scene: Node2D=load("res://content/whalebelly/r1/"+str(host.rooms[i].id)+".tscn").instantiate()
				host.add_child(scene)
				chunks[i]=scene
			chunks[i].name="Chunk_"+str(host.rooms[i].id)
			chunks[i].position=layout.origins[i]-origin
			var baked_player: CanvasItem=chunks[i].get_node_or_null("World/PlayerArt")
			if baked_player!=null:baked_player.hide()
			edge_masks.bind_chunk(i,chunks[i],host.point(host.rooms[i].size))
			edge_masks.move_chunk(i,chunks[i].position)
			set_active(i,i==index)
		far_underpaint=Sprite2D.new()
		far_underpaint.texture=preload("res://art/xumen-continuity/continuous-oral-depth.png")
		far_underpaint.centered=false
		far_underpaint.z_index=-60
		var far_scale: float=maxf((layout.bounds.size.x+256)/far_underpaint.texture.get_width(),(layout.bounds.size.y+256)/far_underpaint.texture.get_height())
		far_underpaint.scale=Vector2.ONE*far_scale
		far_underpaint.position=layout.bounds.position-origin-Vector2(100,100)
		host.add_child(far_underpaint)
		passages=XumenPhysicalPassages.new()
		passages.layout=layout
		passages.host=host
		host.add_child(passages)
		passages.position=-origin
		e01=XumenE01Transition.new()
		e01.host=host
		host.add_child(e01)
		e01.position=-origin
		authored=XumenAuthoredTransitions.new()
		authored.host=host
		host.add_child(authored)
		authored.position=-origin
		prepare_e01_neighbours()
		set_bounds()
		return
	var old_index: int=active_index
	var traveller: CharacterBody2D=host.player if switching else null
	var absolute: Vector2=host.player.position+origin
	var velocity: Vector2=host.player.velocity
	var live_orbs: Dictionary={}
	if traveller!=null:
		for orb: Node2D in get_tree().get_nodes_in_group("tide_player_projectiles"):
			if orb.caster==traveller:
				live_orbs[orb]=orb.global_position+origin
				if orb.get_parent()!=persistent_projectiles:orb.reparent(persistent_projectiles,true)
	contexts[old_index]={"enemies":host.enemies.duplicate()}
	if traveller!=null:
		# Natural crossing preserves live FX/projectile age; explicit reload still resets.
		move_player(traveller,host,true)
	else:
		host.player.queue_free()
		# Respawn/explicit preview rebuilds actors, preserving original reset rules.
		for id: int in contexts.keys():reset_context(id)
	set_active(old_index,false)
	var shift: Vector2=layout.origins[index]-origin
	origin=layout.origins[index]
	for id: int in chunks:
		chunks[id].position=layout.origins[id]-origin
		edge_masks.move_chunk(id,chunks[id].position)
	far_underpaint.position-=shift
	passages.position=-origin
	e01.position=-origin
	authored.position=-origin
	if traveller!=null:
		traveller.world_effects.rebase(shift)
		for orb: Node2D in get_tree().get_nodes_in_group("tide_player_projectiles"):
			if live_orbs.has(orb):orb.global_position=live_orbs[orb]-origin
	host.camera.position-=shift
	host.camera.follow_anchor-=shift
	if traveller!=null:
		traveller.position-=shift
		spawn=[absolute.x-origin.x,absolute.y-origin.y]
	if contexts.has(index):
		host.room_index=index
		host.room=host.rooms[index]
		host.scenery=chunks[index]
		host.enemies=contexts[index].enemies
		host.player=traveller
		move_player(traveller,host.scenery.get_node("World"),false)
		traveller.position=absolute-origin
		host.room_preview=not discover
		if discover and not host.practice:host.visited[str(host.room.id)]=true
		host.player_ui.bind_player(traveller)
		var reference_environment: Node2D=host.scenery.get_node_or_null("ReferenceEnvironment")
		host.reference.texture=load(host.room.get("reference","res://art/whalebelly/reference/r1/"+str(host.room.id)+".png"))
		host.reference.scale=reference_environment.scale if reference_environment!=null else Vector2.ONE
		host.continuity.bind_room()
		host.update_layers()
		host.record_event("room_enter",{"room":str(host.room.id),"connected":true})
	else:
		host.scenery=null
		host._load_isolated_room(index,spawn,discover,chunks[index],traveller)
		contexts[index]={"enemies":host.enemies.duplicate()}
	set_active(index,true)
	prepare_e01_neighbours()
	host.player.z_index=20 if host.scenery.has_node("ReferenceEnvironment") else 3
	if traveller!=null:
		traveller.velocity=velocity
		traveller.transition_locked=false
		traveller.spawn_lock_left=0
		traveller.last_safe=traveller.position
		traveller.grapple_target=Vector2.INF
		crossings+=1
		host.record_event("connected_crossing",{"from":old_index,"to":index,"world":[absolute.x,absolute.y],"same_player":true})
	set_bounds()
	active_index=index
	if traveller!=null and host.ui_session_started and discover and not host.practice:host.save_progress(false)
	switching=false

func reset_context(index: int) -> void:
	if not contexts.has(index):return
	var old: Node2D=chunks[index]
	# Replacing this chunk is a respawn/preview, never a natural crossing.
	if is_instance_valid(host.player) and old.is_ancestor_of(host.player):move_player(host.player,host,true)
	host.remove_child(old)
	old.queue_free()
	var scene: Node2D=load("res://content/whalebelly/r1/"+str(host.rooms[index].id)+".tscn").instantiate()
	host.add_child(scene)
	chunks[index]=scene
	scene.name="Chunk_"+str(host.rooms[index].id)
	var baked: CanvasItem=scene.get_node_or_null("World/PlayerArt")
	if baked!=null:baked.hide()
	edge_masks.bind_chunk(index,scene,host.point(host.rooms[index].size))
	contexts.erase(index)

func set_active(index: int, active: bool) -> void:
	var scene: Node2D=chunks[index]
	scene.process_mode=Node.PROCESS_MODE_PAUSABLE if active else Node.PROCESS_MODE_DISABLED
	# Autonomous painted motion is safe outside the active gameplay context.
	var reference_env: Node=scene.get_node_or_null("ReferenceEnvironment")
	if reference_env!=null:reference_env.process_mode=Node.PROCESS_MODE_PAUSABLE
	var chapter: Node=scene.get_node_or_null("ChapterEnvironment")
	if chapter!=null:chapter.process_mode=Node.PROCESS_MODE_PAUSABLE
	for runtime: String in ["EnvironmentMotion","VisualMechanisms"]:
		var child: Node=scene.get_node_or_null(runtime)
		if child!=null:child.process_mode=scene.process_mode
	var audio: AudioStreamPlayer=scene.get_node_or_null("EnvironmentMotion/WaterAmbience")
	if audio!=null:audio.stream_paused=not active
	for actor: Dictionary in contexts.get(index,{}).get("enemies",[]):
		if actor.has("actor") and is_instance_valid(actor.actor):
			actor.actor.process_mode=scene.process_mode
			if actor.actor is CampaignCorpseCrab or actor.actor is CampaignCrabBoss:actor.actor.target=host.player

func move_player(actor: TidePlayer, parent: Node, keep_global: bool) -> void:
	actor.scene_reparenting=true
	actor.reparent(parent,keep_global)
	actor.scene_reparenting=false

func set_bounds() -> void:
	# Falling still belongs to the current room/connecting region, not bottom of chapter.
	var bottom: float=float(host.room.size[1])
	if host.room_index in [5,6]:bottom=maxf(bottom,layout.origins[1].y+float(host.rooms[1].size[1])-origin.y)
	host.player.world_bounds=Rect2(Vector2(-600,-1800),Vector2(float(host.room.size[0])+1200,bottom+1800))

func _physics_process(_dt: float) -> void:
	if not enabled or switching or chunks.is_empty() or not is_instance_valid(host.player):return
	if host.reference_visible or host.layer_solo>=0 or not host.capture_path.is_empty() or host.player.health<=0:return
	var at: Vector2=host.player.position+origin
	var next: int=layout.containing(at,host.rooms,host.room_index)
	if next!=host.room_index:
		# Only graph-adjacent chunks may activate, never a room underneath a fall.
		for edge: Dictionary in layout.edges:
			if (edge.from==host.room_index and edge.to==next) or (edge.to==host.room_index and edge.from==next):
				if not passages.unlocked(edge):return
				switching=true
				load_room.call_deferred(next,[],true)
				return

func walk_bounds() -> Vector2:
	return Vector2(layout.bounds.position.x-origin.x+18,layout.bounds.end.x-origin.x-18)

func camera_follow(dt: float) -> void:
	var camera: WhalebellyCampaignCamera=host.camera
	var follow: bool=(host.zoomed or host.reference_camera_active()) and not host.reference_visible and host.capture_path.is_empty() and host.layer_solo<0
	if not follow:
		var size: Vector2=host.point(host.room.size)
		camera.zoom=Vector2.ONE*minf(1280/size.x,720/size.y)
		camera.position=size*.5
	else:
		var zoom_target: float=1.0/(camera.dash_zoom if host.player.state in ["A1_dash","A5_slit"] else 1.0)
		camera.zoom=camera.zoom.lerp(Vector2.ONE*zoom_target,1-exp(-dt*6))
		camera.follow_anchor=WhalebellyCampaignCamera.retain_dead_zone(camera.follow_anchor,host.player.position,Vector2(20,55))
		var target: Vector2=camera.follow_anchor+Vector2(host.player.facing*85,-175)
		if not camera.was_following:camera.position=target
		camera.position=camera.position.lerp(target,1-exp(-dt*6))
		var half: Vector2=host.get_viewport_rect().size/(2*camera.zoom)
		var range_rect:=Rect2(layout.bounds.position-origin+half,layout.bounds.size-half*2)
		camera.position=camera.position.clamp(range_rect.position,range_rect.end)
	camera.limit_left=-100000;camera.limit_top=-100000;camera.limit_right=100000;camera.limit_bottom=100000
	camera.was_following=follow
	camera.tracked_room=str(host.room.id)
	camera.offset=Vector2.ZERO
	host.camera_feedback=maxf(0,host.camera_feedback-dt)
	if follow and host.camera_feedback>0:
		camera.offset=Vector2(randf_range(-1,1),randf_range(-1,1))*camera.shake_pixels*clampf(host.camera_feedback/.18,0,1)

func snapshot() -> Dictionary:
	var at: Vector2=host.player.position+origin
	return {"enabled":enabled,"chunks":chunks.size(),"edges":layout.edges.size(),"crossings":crossings,"player_id":host.player.get_instance_id(),"world_x":at.x,"world_y":at.y,"origin":[origin.x,origin.y],"camera_world":[host.camera.position.x+origin.x,host.camera.position.y+origin.y],"e01":e01.snapshot() if is_instance_valid(e01) else {},"authored":authored.snapshot() if is_instance_valid(authored) else {}}

func prepare_e01_neighbours() -> void:
	for id: int in [0,1]:
		if not contexts.has(id):contexts[id]={"enemies":host.create_room_enemies(host.rooms[id],chunks[id])}
		set_active(id,id==host.room_index)
