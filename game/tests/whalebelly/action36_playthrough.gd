extends SceneTree
## Uninterrupted default main scene. Only physical-key InputEvents change play;
## enemy damage, health, resources, position, doors and respawn are never injected.
const OUT: String="res://build/qa/action36/playthrough"
var host: Node2D
var checks: Array[Dictionary]=[]
var inputs: Array[Dictionary]=[]
var stages: Array[Dictionary]=[]
var banner: Label
var held: Dictionary={}
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for frame: int in count: await physics_frame
func key(code: Key, pressed: bool) -> void:
	if bool(held.get(code,false))==pressed:return
	held[code]=pressed
	var event:=InputEventKey.new()
	event.physical_keycode=code;event.keycode=code;event.pressed=pressed
	Input.parse_input_event(event);Input.flush_buffered_events()
	inputs.append({"physics_frame":Engine.get_physics_frames(),"key":OS.get_keycode_string(code),"pressed":pressed})
func tap(code: Key, frames: int=3) -> void:
	key(code,true);await tick(frames);key(code,false)
func hold(code: Key, frames: int) -> void:
	await tap(code,frames);await tick(12)
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	print("PLAYTHROUGH ","PASS " if passed else "FAIL ",label)
func stage(text: String) -> void:
	banner.text=text
	stages.append({"physics_frame":Engine.get_physics_frames(),"text":text,"room":host.room.id,"practice":host.practice})
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	var overlay:=CanvasLayer.new();overlay.layer=100;root.add_child(overlay)
	banner=Label.new();banner.position=Vector2(16,50)
	banner.add_theme_font_size_override("font_size",18)
	banner.add_theme_color_override("font_outline_color",Color.BLACK)
	banner.add_theme_constant_override("outline_size",6);overlay.add_child(banner)
	await tick(45)
	stage("FORMAL PROGRESS | Actual main scene | Engine keyboard events | Isolated save")
	check("formal_default_entry",host.room.id=="R1-01" and not host.practice)
	await shot("01-formal-start")
	var start: float=host.player.position.x
	await hold(KEY_D,60);check("formal_move_right",host.player.position.x>start+100)
	await tap(KEY_J,5);await shot("02-right-attack");await tick(30)
	start=host.player.position.x
	await hold(KEY_A,55);check("formal_move_left",host.player.position.x<start-100)
	await tap(KEY_J,5);await shot("03-left-attack");await tick(30)
	await tap(KEY_SPACE,10);await shot("04-jump");await tick(60)
	await tap(KEY_F9);await tick(20)
	stage("F9 PRACTICE | Temporary ability access | Does not demonstrate earned unlocks")
	check("explicit_practice",host.practice)
	await hold(KEY_D,10);await tap(KEY_SHIFT,5)
	check("practice_dash_reached",host.player.run_visual.current_key in ["dash","shadow_dash"])
	await shot("05-practice-dash");await tick(35)
	await tap(KEY_B,7);await shot("06-parry-window");await tick(30)
	await hold(KEY_J,40);await shot("07-charge-release");await tick(35)
	await tap(KEY_U,8);check("practice_projectile_reached",host.player.skill_controller.visual_key=="shadow_orb")
	await shot("08-projectile");await tick(55)
	key(KEY_W,true);await tap(KEY_U,8);key(KEY_W,false)
	check("practice_upspell_reached",host.player.skill_controller.visual_key=="abyss_scream")
	await shot("09-up-spell");await tick(55)
	await tap(KEY_SPACE,10);key(KEY_S,true);await tap(KEY_U,8);key(KEY_S,false)
	check("practice_dive_reached",host.player.skill_controller.visual_key=="dark_dive")
	await tick(20);await shot("10-dive-landing");await tick(60)
	await tap(KEY_F9);await tick(30)
	stage("FORMAL PROGRESS RESTORED | Walk away to rearm door, then enter")
	check("formal_progress_restored",not host.practice and not host.abilities.get("dash",false))
	await hold(KEY_A,75)
	var previous_room: String=str(host.room.id)
	key(KEY_D,true)
	for frame: int in 600:
		await tick(1)
		if str(host.room.id)!=previous_room:break
	key(KEY_D,false);await tick(30)
	check("actual_authored_door",host.room.id=="R1-02")
	await shot("11-formal-door-transition")
	if host.room.id=="R1-02":await actual_enemy_death()
	for code: int in held:key(code,false)
	var failed: int=checks.filter(func(row: Dictionary) -> bool:return not row.pass).size()
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"method":"Uninterrupted default main; engine physical-key events (not OS keyboard); QA isolates save only; F9 explicitly enables and restores practice; no position/health/resource/enemy/damage injection; actual authored enemy causes hurt/death and normal checkpoint respawn", "checks":checks,"stages":stages,"inputs":inputs,"failed":failed},"\t"))
	await host.graceful_quit(1 if failed else 0)
func actual_enemy_death() -> void:
	stage("FORMAL COMBAT | Authored enemy attacks cause all damage | No health injection")
	var actor_id: int=host.player.get_instance_id()
	var initial_health: int=host.player.health
	var hurt_seen: bool=false
	var defeat_seen: bool=false
	var attack_sent: bool=false
	var enemy_damaged: bool=false
	var enemy_initial_health: int=int(host.enemies[0].hp) if not host.enemies.is_empty() else 0
	for frame: int in 2400:
		if host.player.get_instance_id()!=actor_id:break
		if host.player.health<=0:
			key(KEY_A,false);key(KEY_D,false)
			if not defeat_seen:
				defeat_seen=true;stage("ACTUAL ENEMY DEATH | Waiting for normal checkpoint respawn")
				await shot("13-actual-death")
		elif not host.enemies.is_empty():
			enemy_damaged=enemy_damaged or int(host.enemies[0].hp)<enemy_initial_health
			var delta: float=float(host.enemies[0].pos.x)-host.player.position.x
			key(KEY_A,delta < -65);key(KEY_D,delta > 65)
			if absf(delta)<85 and not attack_sent:
				attack_sent=true;await tap(KEY_J,3)
			if host.player.health<initial_health and not hurt_seen:
				hurt_seen=true;await shot("12-actual-enemy-hurt")
		await tick(1)
	key(KEY_A,false);key(KEY_D,false)
	check("attack_reaches_authored_enemy",attack_sent and enemy_damaged)
	check("actual_enemy_hurt",hurt_seen)
	check("actual_enemy_defeat",defeat_seen)
	check("normal_checkpoint_respawn",host.player.get_instance_id()!=actor_id and host.player.health==5 and not host.practice)
	stage("FORMAL CHECKPOINT RESPAWN | Same default campaign actor | Controls restored")
	await tick(45);await hold(KEY_D,20);await hold(KEY_A,20)
	await shot("14-normal-respawn")
