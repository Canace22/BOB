extends SceneTree
## Run with --script res://scripts/fall_checks.gd -- --qa-fall-fixture.
## Explicit lethal-fall fixture; preserves both QA files and the normal slot.
var host: Node
var checks: Array=[]
var preserved: Dictionary={}
var normal_hash:=""
var output:="res://evidence/v02/fall-final"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not "--qa-fall-fixture" in OS.get_cmdline_user_args():
		push_error("Missing --qa-fall-fixture; refusing to select normal save.")
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output=arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	for path in ["user://save-qa.json","user://save-qa.json.bak"]:
		preserved[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	normal_hash=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await create_timer(0.2).timeout
	check("qa_slot_selected",host.game.qa and host.game.save_file=="user://save-qa.json")
	host.game.data.checkpoint=0
	host.change_room(1)
	await create_timer(0.3).timeout
	var original_player=host.level.player
	host.game.hp=1
	original_player.position=Vector2(100,host.level.death_y+20)
	await create_timer(0.08).timeout
	check("lethal_fall_delayed",is_instance_valid(original_player) and original_player.respawning and host.game.room_index==1 and host.game.hp==0)
	check("fall_death_event",host.game.events.filter(func(e):return e.event=="death" and e.detail.get("cause","")=="fall").size()==1)
	check("fall_death_effect",host.effect_counts.get("death",0)==1)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/fall-death.png")
	await create_timer(0.4).timeout
	check("respawn_at_checkpoint",host.game.room_index==0 and host.game.hp==4 and not host.level.player.respawning)
	check("single_death",host.game.deaths==1)
	var current_hash=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	check("normal_save_untouched",current_hash==normal_hash)
	for path in preserved:
		if preserved[path]==null:
			if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
		else:
			var restored=FileAccess.open(path,FileAccess.WRITE)
			restored.store_buffer(preserved[path])
			restored.close()
	var result={"passed":checks.all(func(c):return c.passed),"checks":checks,"events":host.game.events,"effect_counts":host.effect_counts,"fixture_note":"R1-02 HP=1 forced below death plane; actual physics invokes fall_recover; normal slot untouched and QA files restored. This is a recovery fixture, not full traversal."}
	var file=FileAccess.open(output+"/fall.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	quit(0 if result.passed else 1)

func check(id: String,passed: bool) -> void:
	checks.append({"id":id,"passed":passed})
	print("FALL_CHECK ",id," ",passed)
