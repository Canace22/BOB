extends Node
## 在独立GPU进程导出本场景视口，避免多窗口截图串到其它Godot实例。

var arena: Node2D
const OUT: String = "res://build/qa/whitebox-animation/"

func _ready() -> void:
	arena = get_parent()
	_run.call_deferred()

func frames(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = get_viewport().get_texture().get_image().save_png(OUT+name+".png")
	if result != OK: push_error("Animation capture failed: "+name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await frames(12)
	await shot("01-idle")
	arena.player.request_action("wb_rise")
	await frames(7)
	await shot("02-upper")
	arena.reset_arena()
	await frames(4)
	arena.player.request_action("parry")
	await frames(8)
	await shot("03-guard")
	arena.reset_arena()
	await frames(4)
	arena.player.request_action("wb_draw")
	await frames(16)
	await shot("04-wide")
	arena.reset_arena()
	await frames(4)
	arena.player.request_action("wb_flurry")
	await frames(24)
	await shot("05-flurry")
	arena.reset_arena()
	await frames(4)
	arena.player.try_backstep()
	await frames(8)
	await shot("06-backstep")
	arena.reset_arena()
	await frames(4)
	arena.player.request_action("wb_draw")
	await frames(9)
	arena.player.try_backstep()
	await frames(5)
	await shot("07-cancel-white")
	print("ANIMATION GPU CAPTURE: 7 views exported")
	get_tree().quit()
