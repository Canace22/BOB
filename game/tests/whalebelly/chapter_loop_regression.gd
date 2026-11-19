extends SceneTree
## 隔离循环样板实际键盘路线；主路线不写玩家坐标、不注入能力或无敌。
var host: Node2D
var failures: int = 0
var upper: bool = false
const OUT := "res://build/qa/chapter-loop"
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await process_frame
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(2)
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func continue_story() -> void:
	if host.player_ui.page_id!="dialogue": return
	key(KEY_A,false)
	key(KEY_D,false)
	key(KEY_SPACE,false)
	await tick(12)
	await tap(KEY_ESCAPE)
	for i: int in 60:
		if not paused and host.player.controls_enabled: return
		await tick(1)
func walk(x: float, jump: bool = false, budget: int = 400) -> bool:
	for i: int in budget:
		if host.player_ui.page_id=="dialogue": await continue_story()
		var p: TidePlayer=host.player
		if p.health<=0: return false
		if absf(p.position.x-x)<12.0:
			key(KEY_A,false)
			key(KEY_D,false)
			key(KEY_SPACE,false)
			await tick(8)
			return true
		key(KEY_D,p.position.x<x)
		key(KEY_A,p.position.x>x)
		if jump and p.is_on_floor():
			if Input.is_action_pressed("tp_jump"): key(KEY_SPACE,false)
			elif i%8==0: key(KEY_SPACE,true)
		if not p.is_on_floor() and p.velocity.y>=0: key(KEY_SPACE,false)
		await tick(1)
	key(KEY_A,false)
	key(KEY_D,false)
	key(KEY_SPACE,false)
	var p: WhalebellyCampaignPlayer=host.player
	print("WALK_STOP target=",x," position=",p.position," state=",p.state," controls=",p.controls_enabled," floor=",p.is_on_floor()," velocity=",p.velocity," collision=",p.get_slide_collision(0).get_collider().get_path() if p.get_slide_collision_count()>0 else "none"," axis=",p.movement_axis()," room=",host.room.id)
	await shot("failed-walk")
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://tests/whalebelly/chapter_loop_play.tscn").instantiate()
	root.add_child(host)
	current_scene=host
	for i: int in 160:
		if host.player_ui.page_id=="dialogue": break
		await tick(1)
	await continue_story()
	check("warning reached using movement",await walk(485))
	await tick(25)
	if host.player_ui.page_id=="dialogue": await continue_story()
	check("warning has completed before encounter",host.dialogue.seen.get("loop.warning",false))
	if "--threat" in OS.get_cmdline_user_args():
		await threat()
	else:
		await missed_lamp()
	print("CHAPTER_LOOP_V2 failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)

func threat() -> void:
	check("approach activates food defence",await walk(700))
	var enemy: WhaleChapterForager=host.loop.enemies[0]
	var hp: int=host.player.health
	var old_x: float=enemy.position.x
	for i: int in 150:
		if host.player.health<hp: break
		await tick(1)
	check("enemy actively advances from feeding point",absf(enemy.position.x-old_x)>12.0)
	check("approaching without defence takes actual sweep damage promptly",host.player.health<hp and enemy.contact_hits>0)
	await shot("v2-defending-food")
	# 中间停留是独立站位夹具，专门验证双侧风险；不冒充自然路线。
	host.health=5
	host.load_room(0,[950,host.ground_y(950,540)])
	host.player.invulnerable=0.0
	await tick(2)
	var enemies: Array[WhaleChapterForager]=host.loop.enemies
	for i: int in 130:
		await tick(1)
	check("both enemies activate when player stands between them",enemies.all(func(e: WhaleChapterForager) -> bool: return e.awake and e.attack_serial>0))
	check("both sides aim toward the player",enemies[0].facing>0 and enemies[1].facing<0)
	check("middle position exposes player to real damage",host.player.health<5 and enemies.any(func(e: WhaleChapterForager) -> bool: return e.contact_hits>0))
	await shot("v2-middle-risk")

func missed_lamp() -> void:
	check("upper approach is reachable",await walk(670,true))
	check("upper gap is traversable",await walk(1060,true))
	var jumped: bool=false
	key(KEY_D,true)
	for i: int in 450:
		var p: TidePlayer=host.player
		if p.position.x>1240 and p.is_on_floor() and not jumped:
			key(KEY_SPACE,true)
			jumped=true
		if p.velocity.y>=0: key(KEY_SPACE,false)
		if host.dialogue.active.get("id","")=="loop.aftermath": break
		if p.health<=0: break
		await tick(1)
	key(KEY_D,false)
	key(KEY_SPACE,false)
	check("regression actually jumps over old narrow lamp landing zone",jumped and host.player.position.x>1480)
	check("passing the lamp still records the passage",host.loop.passed)
	check("aftermath triggers automatically without returning to lamp",host.dialogue.active.get("id","")=="loop.aftermath")
	check("aftermath has explicit source route destination causality",host.dialogue.active.get("lines",PackedStringArray()).size()==4)
	await tick(80)
	await shot("v2-aftermath-after-skip-lamp")
	await continue_story()
	check("goal points into visible arch instead of imaginary right descent",host.dialogue.objective.text.contains("骨拱"))
	key(KEY_D,true)
	for i: int in 400:
		if host.room_index==1: break
		await tick(1)
	key(KEY_D,false)
	check("continuing right really enters foldwell instead of a dead end",host.room_index==1)
	for i: int in 250:
		if host.dialogue.active.get("id","")=="loop.foldwell_arrival": break
		await tick(1)
	check("destination arrival is playable and named correctly",host.room_index==1 and host.room.name=="折井入口" and host.player.is_inside_tree())
	check("arrival story confirms reason for going downstairs",host.dialogue.active.get("id","")=="loop.foldwell_arrival")
	await shot("v2-foldwell-arrival")
	await continue_story()
	await tick(20)
	check("completion is explicit rather than stuck in a room",host.player_ui.page_id=="chapter_result")
	check("completion offers replay and return actions",host.player_ui.body.find_child("RestartLoop",true,false)!=null and host.player_ui.body.find_child("ReturnPassage",true,false)!=null)
	await shot("v2-completion")
	host.player_ui.body.find_child("RestartLoop",true,false).pressed.emit()
	for i: int in 130:
		if host.dialogue.active.get("id","")=="loop.arrival": break
		await tick(1)
	check("replay button starts a fresh loop",host.room_index==0 and host.dialogue.active.get("id","")=="loop.arrival" and not host.dialogue.seen.has("loop.passage"))
	await continue_story()
