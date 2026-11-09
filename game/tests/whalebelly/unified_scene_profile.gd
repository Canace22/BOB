extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func sample(label: String) -> void:
 for i: int in range(120):await process_frame
 var intervals: Array[float]=[];var processes: Array[float]=[];var last: int=Time.get_ticks_usec()
 for i: int in range(300):
  await process_frame
  var now: int=Time.get_ticks_usec();intervals.append(float(now-last)/1000);last=now
  processes.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
 intervals.sort();processes.sort()
 print("PROFILE ",label," wall median/p95=",intervals[150],"/",intervals[285]," cpu median/p95=",processes[150],"/",processes[285]," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func run() -> void:
 Engine.max_fps=60
 host=load("res://content/whalebelly/main.tscn").instantiate();host.qa=true;host.qa_connected=true;host.integration_external_test=true
 root.add_child(host);current_scene=host
 for i: int in range(60):await physics_frame
 host.player.set_physics_process(false);host.connected_world.set_physics_process(false)
 await sample("full")
 host.set_process(false);host.connected_world.unified.set_process(false)
 await sample("static")
 host.connected_world.unified.hide()
 await sample("no-unified-render")
 host.process_mode=Node.PROCESS_MODE_DISABLED
 await sample("all-host-disabled")
 host.player_ui.hide();host.player_ui.process_mode=Node.PROCESS_MODE_DISABLED
 await sample("ui-hidden")
 host.hide()
 await sample("all-art-hidden")
 for node: Node in root.find_children("*","Node",true,false):
  if node!=root:node.process_mode=Node.PROCESS_MODE_DISABLED
 await sample("all-nodes-disabled")
 await host.graceful_quit()
