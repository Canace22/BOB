extends SceneTree
## QA-only existing V6 schema and transient ownership regression, no production save writes.
var host: Node2D
var checks: Array[Dictionary]=[]
const SAVE: String="user://whalebelly/artmatch_qa_save.json"

func _initialize() -> void: run.call_deferred()

func step(count: int) -> void:
	for i: int in range(count): await physics_frame

func check(label: String,condition: bool) -> void:
	checks.append({"name":label,"pass":condition})
	print("PASS " if condition else "FAIL ",label)

func orb_count() -> int:
	return get_nodes_in_group("tide_player_projectiles").size()

func add_transients() -> void:
	host.player.world_effects._spawn_ghost()
	host.player._spawn_orb()

func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await step(35)
	var saved: String=FileAccess.get_file_as_string(SAVE) if FileAccess.file_exists(SAVE) else ""
	var fixture: Dictionary={"version":6,"checkpoint":{"room":0,"pos":[120,550]},"collected":{"R1-03":true},"defeated":{"R1-04:0":true},"abilities":{"dash":true,"float":false,"anchor":false},"future_ignored_field":123}
	var file:=FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()
	host.load_progress()
	check("old_v6_preserves_abilities_and_room_progress",host.abilities.dash and host.collected.get("R1-03",false) and host.defeated.get("R1-04:0",false))
	check("missing_completed_defaults_false",not host.completed)
	check("new_skill_unlock_uses_old_reward_data",host.player.skill_unlocked("R1-03") and host.player.skill_unlocked("dash"))
	check("chapter_skill_stays_locked",not host.player.skill_unlocked("chapter") and not host.player.request_action("shadow_orb"))
	check("old_missing_optional_ability_is_locked",not host.has_ability("unrecognized_ability"))
	host.save_progress(false)
	var reloaded: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check("save_schema_stays_v6",reloaded.version==6 and reloaded.abilities.dash and not reloaded.has("skill_controller"))
	add_transients()
	check("transient_fixture_created",orb_count()==1 and host.player.world_effects.particles.size()==1)
	host.player.take_damage(1,Vector2(200,0),true)
	await step(2)
	check("hit_clears_orb_and_ghost",orb_count()==0 and host.player.world_effects.particles.is_empty())
	await step(30)
	add_transients()
	host.player._enter("interact",.5)
	await step(2)
	check("interaction_clears_orb_and_ghost",orb_count()==0 and host.player.world_effects.particles.is_empty())
	await step(32)
	add_transients()
	var old: Node=host.player
	host.load_room(1)
	await step(5)
	check("room_change_frees_old_owner_and_projectiles",not is_instance_valid(old) and orb_count()==0 and host.player.world_effects.particles.is_empty())
	host.checkpoint={"room":0,"pos":[120,550]}
	add_transients()
	old=host.player
	host.player.take_damage(5,Vector2.ZERO,true)
	await step(2)
	check("death_clears_projectiles_immediately",orb_count()==0)
	await step(225) # Defeat, fades and the hurt freeze frame.
	check("death_respawns_shared_character_and_cleans_owner",not is_instance_valid(old) and host.room_index==0 and host.player.health==5 and host.player.world_effects.particles.is_empty())
	check("death_keeps_earned_unlocks",host.player.skill_unlocked("dash") and not host.player.skill_unlocked("chapter"))
	# Restore the pre-test QA fixture for the separately run V6 reload route.
	if not saved.is_empty():
		file=FileAccess.open(SAVE,FileAccess.WRITE)
		file.store_string(saved)
		file.close()
	else: DirAccess.remove_absolute(SAVE)
	var failed: int=checks.filter(func(row: Dictionary) -> bool: return not row.pass).size()
	file=FileAccess.open("res://build/qa/action36/lifecycle.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	file.close()
	print("ACTION36_LIFECYCLE checks=",checks.size()," failed=",failed)
	host.graceful_quit(1 if failed else 0)
