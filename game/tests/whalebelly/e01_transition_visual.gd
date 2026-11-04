extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
 for i: int in range(n):await physics_frame
func run() -> void:
 host=load("res://content/whalebelly/main.tscn").instantiate()
 host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
 root.add_child(host);current_scene=host
 await step(45)
 host.player.set_physics_process(false)
 for x: float in [1450.0,1900.0,2370.0]:
  var floor_y: float=host.ground_y(x,660) if x<1671 else 631.847
  host.player.position=Vector2(x,floor_y)-host.connected_world.origin
  host.camera.position=Vector2(x+85,456.847)-host.connected_world.origin
  host.camera.follow_anchor=host.player.position
  await step(15);await process_frame;await process_frame;RenderingServer.force_draw()
  root.get_texture().get_image().save_png("res://build/qa/xumen-e01/after/"+str(int(x))+".png")
 # Same fixed cameras, with foreground disabled; no foreground hides joints.
 host.connected_world.e01.foreground_enabled=false
 for x: float in [1450.0,1900.0,2370.0]:
  var floor_y: float=host.ground_y(x,660) if x<1671 else 631.847
  host.player.position=Vector2(x,floor_y)-host.connected_world.origin
  host.camera.position=Vector2(x+85,456.847)-host.connected_world.origin
  host.camera.follow_anchor=host.player.position
  await step(12);await process_frame;RenderingServer.force_draw()
  root.get_texture().get_image().save_png("res://build/qa/xumen-e01/after/no-front-"+str(int(x))+".png")
 host.connected_world.e01.foreground_enabled=true
 print("E01_VISUAL_COMPLETE: three fixed-coordinate layouts, not traversal proof")
 await host.graceful_quit()
