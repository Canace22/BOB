extends SceneTree
## Main-scene sample through physical-key InputEvents. Damage is an explicit QA stimulus.
var host: Node2D
var checks: Array[Dictionary] = []
var run_trace: Array[Dictionary] = []
const OUT: String = "res://build/qa/action36/sample"

func _initialize() -> void: run.call_deferred()
func tick(frames: int) -> void:
	for i: int in frames: await physics_frame
func key(code: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"pass":ok})
	print("SAMPLE ","PASS " if ok else "FAIL ",label)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func displayed(key_name: String) -> bool:
	var p: TidePlayer = host.player
	return p.run_visual.active and p.run_visual.current_key==key_name and p.run_visual.sprite.visible and not p.body.visible and not p.get_node("Visual/Legs").visible

func trace_run(direction: String) -> void:
	var poses: Dictionary={}
	for frame: int in 65:
		await tick(1)
		var view: TideActionVisual=host.player.run_visual
		if view.current_key!="run": continue
		var index: int=view.load_clip("run").body.find(view.sprite.texture)
		poses[index]=true
		run_trace.append({"direction":direction,"frame":index,"cycle":view.phase,"x":host.player.position.x,"y":host.player.position.y,"floor":host.player.is_on_floor()})
	check("run_"+direction+"_covers_two_cycles",host.player.run_visual.phase>=2.0)
	check("run_"+direction+"_uses_all_authored_poses",poses.size()==int(host.player.run_visual.manifest.run.frame_count))

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(45)
	check("idle_uses_new_single_body",displayed("idle"))
	await shot("01-idle")
	var start: Vector2 = host.player.position
	key(KEY_D,true)
	await trace_run("right")
	check("right_motion_and_new_run",displayed("run") and host.player.position.x>start.x+30 and host.player.facing>0)
	await shot("02-run-right")
	key(KEY_D,false)
	await tick(18)
	key(KEY_A,true)
	await trace_run("left")
	check("left_motion_and_new_run",displayed("run") and host.player.facing<0)
	await shot("03-run-left")
	key(KEY_A,false)
	await tick(24)
	key(KEY_J,true)
	await tick(5)
	check("attack_uses_new_single_body",displayed("strike1"))
	await shot("04-strike-left")
	key(KEY_J,false)
	await tick(30)
	key(KEY_F9,true)
	await tick(2)
	key(KEY_F9,false)
	key(KEY_F10,true)
	await tick(2)
	key(KEY_F10,false)
	await tick(30)
	check("practice_enabled_for_dash",host.practice)
	key(KEY_D,true)
	await tick(8)
	key(KEY_D,false)
	await tick(8)
	var dash_start: float = host.player.position.x
	key(KEY_SHIFT,true)
	await tick(4)
	check("dash_has_new_visual_and_physical_motion",displayed("dash") and host.player.position.x>dash_start+20)
	await shot("05-dash")
	key(KEY_SHIFT,false)
	await tick(45)
	key(KEY_B,true);await tick(7)
	check("parry_uses_new_body",displayed("parry"))
	var parry_health: int=host.player.health
	var hit_accepted: bool=host.player.take_damage(1,host.player.position+Vector2(host.player.facing*50,0))
	check("parry_front_attack_is_rejected",not hit_accepted and host.player.skill_controller.parried and host.player.health==parry_health)
	await shot("06a-parry-success");key(KEY_B,false);await tick(35)
	var health_before: int = host.player.health
	host.player.invulnerable = 0.0
	host.player.take_damage(1,host.player.global_position+Vector2(50,0),true)
	await tick(3)
	check("hurt_uses_new_body_and_real_health",displayed("hurt") and host.player.health==health_before-1)
	await shot("06-hurt")
	await tick(100)
	check("hurt_recovers_control",host.player.controls_enabled and host.player.state=="idle")
	var original_player: int = host.player.get_instance_id()
	host.player.take_damage(99,Vector2.ZERO,true)
	await tick(12)
	check("death_blocks_actions",host.player.state=="defeat" and not host.player.request_action("strike_01"))
	await shot("07-defeat")
	await tick(210)
	check("campaign_respawns_actual_actor",is_instance_valid(host.player) and host.player.get_instance_id()!=original_player and host.player.health==5)
	await shot("08-respawn")
	if "--extended" in OS.get_cmdline_user_args(): await extended_route()
	var failures: int = checks.filter(func(row: Dictionary) -> bool: return not row.pass).size()
	FileAccess.open(OUT.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"method":"Actual main scene; physical-key InputEvent mapping for movement/attack/dash/parry; explicit QA front-attack stimulus for parry, injected damage for hurt/death; isolated QA save; no claim of OS keyboard", "checks":checks,"failed":failures},"\t"))
	FileAccess.open(OUT.path_join("run-trace.json"),FileAccess.WRITE).store_string(JSON.stringify(run_trace,"\t"))
	await host.graceful_quit(1 if failures else 0)

func extended_route() -> void:
	# The respawned shared player keeps explicit practice mode; its default upgrade
	# selector is restored. Spell costs, movement and the automatic door remain real.
	key(KEY_D,true);await tick(12);key(KEY_D,false);await tick(12)
	key(KEY_U,true);await tick(5)
	check("physical_U_casts_upgraded_projectile",host.player.skill_controller.visual_key=="shadow_orb")
	await shot("09-projectile");key(KEY_U,false);await tick(65)
	key(KEY_W,true);key(KEY_U,true);await tick(6)
	check("physical_W_U_casts_upgraded_upspell",host.player.skill_controller.visual_key=="abyss_scream")
	await shot("10-upspell");key(KEY_U,false);key(KEY_W,false);await tick(65)
	key(KEY_SPACE,true);await tick(9);key(KEY_SPACE,false)
	key(KEY_S,true);key(KEY_U,true);await tick(5)
	check("physical_air_S_U_casts_dive",host.player.skill_controller.visual_key=="dark_dive")
	key(KEY_U,false);key(KEY_S,false);await tick(20);await shot("11-dive");await tick(60)
	var initial_room: String=str(host.room.id)
	key(KEY_D,true)
	for frame: int in 480:
		await tick(1)
		if str(host.room.id)!=initial_room: break
	key(KEY_D,false);await tick(30)
	check("physical_movement_enters_next_room",str(host.room.id)!=initial_room)
	check("next_room_keeps_shared_animation",is_instance_valid(host.player.run_visual.sprite) and host.player.run_visual.active)
	await shot("12-next-room")
