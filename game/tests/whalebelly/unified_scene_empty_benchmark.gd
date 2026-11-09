extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 Engine.max_fps=60
 for i: int in range(120):await process_frame
 var times: Array[float]=[];var last: int=Time.get_ticks_usec()
 for i: int in range(600):
  await process_frame
  var now: int=Time.get_ticks_usec();times.append(float(now-last)/1000);last=now
 times.sort();print("EMPTY_CONTROL median/p95=",times[300],"/",times[570])
 quit()
