extends SceneTree
## Runtime ownership, real membrane load/drop, motion and camera coverage.
var host: WhalebellyMain
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
 for i: int in range(n):await physics_frame
func check(id: String,pass_value: bool,detail: Variant=null) -> void:
 checks.append({"id":id,"pass":pass_value,"detail":detail})
 print("PASS " if pass_value else "FAIL ",id," ",detail)
func run() -> void:
 host=load("res://content/whalebelly/main.tscn").instantiate()
 host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
 root.add_child(host);current_scene=host;await step(40)
 var world: XumenConnectedWorld=host.connected_world
 var art: XumenUnifiedScene=world.unified
 check("full_chapter_art_present",art.terrain_count==91 and art.sprites.size()==100,art.snapshot())
 check("original_physical_connectors",world.passages.supports==26)
 var duplicate_layers: Array[String]=[]
 for chunk: Node in world.chunks.values():
  for path: String in ["Far","Middle","Foreground","World/WorldOriginalPixels","ReferenceEnvironment","ChapterEnvironment","EnvironmentMotion"]:
   var node: CanvasItem=chunk.get_node_or_null(path)
   if node!=null and node.is_visible_in_tree():duplicate_layers.append(str(chunk.name)+"/"+path)
 check("no_legacy_visual_owners",duplicate_layers.is_empty(),duplicate_layers)
 check("player_kept_visible",host.player.is_visible_in_tree() and host.player.z_index==8)
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/xumen-unified/scene.json"))
 check("every_mesh_bound",data.meshes.size()==art.parts.values().filter(func(n: Node)->bool:return n is Polygon2D).size())
 check("single_continuous_main_contour",art.parts.has("MAIN-JAW-ROAD-body") and not art.parts.has("E01-body"))
 art.update_at(0)
 var fish: Sprite2D=art.fish_groups[0].sprites[0]
 var p: Vector2=fish.position;var f: int=fish.frame;var frond: int=art.baleen[0].frame
 art.update_at(.7)
 check("fish_body_and_path",fish.frame!=f and fish.position!=p)
 check("approved_baleen_frames_advance",art.baleen[0].frame!=frond and art.baleen.size()==data.fronds.size(),art.baleen.size())
 art.update_at(4)
 check("baleen_exact_loop",art.baleen[0].frame==frond)
 art.update_at(180)
 var bounded: bool=true
 for emitter: EnvironmentBubbleEmitter in art.bubbles:
  bounded=bounded and emitter.bubbles.size()==emitter.population and emitter.recycled>0
  for b: Dictionary in emitter.bubbles:bounded=bounded and b.bounds.has_point(b.node.position)
 check("all_bubbles_recycle_within_bounds",bounded)
 art.update_at(host.clock)
 check("bottom_pinned_kelp",not art.flexible.is_empty() and art.flexible.all(func(n: ChapterPinnedBitmap)->bool:return n.pin_bottom))
 var t: float=art.elapsed
 paused=true;await create_timer(.25,true).timeout
 check("unified_time_paused",art.elapsed==t)
 paused=false;await step(12);check("unified_time_resumed",art.elapsed>t)
 # Explicit membrane start fixture; subsequent sag and drop are physical inputs.
 host.load_room(2,[840,620]);await step(100)
 var mechanism: WhalebellyMechanisms=host.scenery.get_node("VisualMechanisms")
 check("real_weight_loads_membrane",host.player.is_on_floor() and mechanism.membrane_drop>35,mechanism.membrane_drop)
 var body: Polygon2D=art.parts["MAIN-JAW-ROAD-body"]
 check("visual_follows_collision_sag",absf(float(body.material.get_shader_parameter("membrane_drop"))-mechanism.membrane_drop)<2)
 Input.action_press("down");Input.action_press("jump");await step(2)
 Input.action_release("jump");Input.action_release("down");await step(58)
 check("thinner_main_art_preserves_lower_route",host.player.is_on_floor() and host.player.position.y>740,host.player.position)
 check("membrane_recovers_after_weight_leaves",mechanism.membrane_drop<2,mechanism.membrane_drop)
 # Move camera only: far/front respond, terrain stays fixed.
 host.set_process(false);world.set_physics_process(false);host.player.set_physics_process(false)
 var road_pos: Vector2=body.position;var far_pos: Vector2=art.groups.Far.position;var front_pos: Vector2=art.groups.Foreground.position
 host.camera.position+=Vector2(120,-60);await step(3)
 check("parallax_without_terrain_motion",art.groups.Far.position!=far_pos and art.groups.Foreground.position!=front_pos and body.position==road_pos)
 if DisplayServer.get_name()!="headless":
  await process_frame;RenderingServer.force_draw();root.get_texture().get_image().save_png("res://build/qa/xumen-unified/membrane-lower.png")
 var failed: int=checks.filter(func(c: Dictionary)->bool:return not c.pass).size()
 FileAccess.open("res://build/qa/xumen-unified/specialist.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"scope":"Explicit membrane fixture; real input drop, runtime ownership, deterministic motion, pause and camera tests. Not natural ability acquisition."},"  "))
 print("UNIFIED_QA checks=",checks.size()," failed=",failed)
 await host.graceful_quit(1 if failed else 0)
