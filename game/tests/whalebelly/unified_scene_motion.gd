extends SceneTree
## Rendered environment loop and hardware frame sampling, no real user save.
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
 for i: int in range(n):await physics_frame
func shot(id: String) -> void:
 await process_frame;RenderingServer.force_draw()
 root.get_texture().get_image().save_png("res://build/qa/xumen-unified/"+id+".png")
func run() -> void:
 Engine.max_fps=60
 host=load("res://content/whalebelly/main.tscn").instantiate()
 host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
 root.add_child(host);current_scene=host;await step(80)
 host.set_process(false);host.connected_world.set_physics_process(false);host.player.set_physics_process(false)
 for actor: Node in get_nodes_in_group("tide_enemies"):actor.set_physics_process(false)
 var art: XumenUnifiedScene=host.connected_world.unified
 host.camera.position=Vector2(720,350)
 var sample_only: bool="--sample-only" in OS.get_cmdline_user_args()
 # Deterministic frames show the approved curtain animation at game scale.
 art.set_process(false)
 for i: int in range(0 if sample_only else 49):
  art.update_at(float(i)/12);await step(1);await shot("motion-%03d"%i)
 # Separate unrecorded, normal real-time sampling.
 art.set_process(true);host.set_process(true)
 await step(120)
 var times: Array[float]=[];var last: int=Time.get_ticks_usec()
 for i: int in range(600):
  await process_frame
  var now: int=Time.get_ticks_usec();times.append(float(now-last)/1000);last=now
 times.sort()
 var result: Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"resolution":root.size,"samples":times.size(),"frame_cap":60,"vsync":DisplayServer.window_get_vsync_mode(),"median_ms":times[300],"p95_ms":times[570],"p99_ms":times[594],"texture_mib":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576,"process_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,"scope":"GPU warm environment-only frame intervals, screenshot capture disabled during sample; not combat or cross-device guarantee."}
 FileAccess.open("res://build/qa/xumen-unified/performance.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print("UNIFIED_PERFORMANCE ",result)
 await host.graceful_quit()
