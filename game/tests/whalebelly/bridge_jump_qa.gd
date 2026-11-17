extends SceneTree
## 从截图对应岸台起跳；输入、碰撞脚线和世界位置一起记录，使用独立QA档。
var host: WhalebellyMain
var failed: int=0
var records: Array[Dictionary]=[]
const OUT := "res://build/qa/bridge-jump"
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await physics_frame
func key(code: Key, pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
func shot(name_text: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(name_text+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","bridge-jump")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(35)
	for hold: int in [3,12,30]:
		host.load_room(1)
		host.player.position=Vector2(1200,694)
		host.player.invulnerable=1000
		await tick(30)
		await shot("start-"+str(hold))
		var floor_y: float=host.player.global_position.y
		var landed: bool=false
		var was_airborne: bool=false
		var fell: bool=false
		key(KEY_D,true)
		key(KEY_SPACE,true)
		for frame: int in 110:
			if frame==hold: key(KEY_SPACE,false)
			await tick(1)
			var p: WhalebellyCampaignPlayer=host.player
			var row: Dictionary={"hold":hold,"frame":frame,"room":host.room_index,"pos":[p.global_position.x,p.global_position.y],"velocity":[p.velocity.x,p.velocity.y],"floor":p.is_on_floor(),"mask":p.collision_mask,"drop":p.drop_timer}
			records.append(row)
			if not p.is_on_floor(): was_airborne=true
			if was_airborne and p.is_on_floor():
				landed=true
				print("JUMP_LANDED ",row)
				break
			if p.global_position.y>floor_y+100:
				fell=true
				print("JUMP_FELL ",row)
				break
		key(KEY_D,false)
		key(KEY_SPACE,false)
		await shot("end-"+str(hold))
		if not landed or fell: failed+=1
		print("BRIDGE_JUMP hold=",hold," landed=",landed," fell=",fell)
	host.load_room(1)
	host.player.position=Vector2(1200,694)
	host.player.invulnerable=1000
	await tick(30)
	for code: Key in [KEY_D,KEY_A]:
		var walk_ok: bool=true
		key(code,true)
		for frame: int in 100:
			await tick(1)
			if host.player.global_position.y>840: walk_ok=false
		key(code,false)
		await tick(4)
		if not walk_ok: failed+=1
		print("BRIDGE_WALK direction=",code," pass=",walk_ok," position=",host.player.global_position)
		await shot("walk-"+str(code))
	FileAccess.open(OUT.path_join("trace.json"),FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	print("BRIDGE_JUMP_COMPLETE failed=",failed)
	await host.graceful_quit(1 if failed else 0)
