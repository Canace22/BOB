extends Node
## Isolated integration fixtures. These are not a normal-playthrough proof.
## The caller owns result serialization and process exit.

var host: Node
var checks: Array[Dictionary] = []
var notes: Array[String] = []
var original_saves: Dictionary = {}

func run(main: Node) -> Dictionary:
	host = main
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not host.game.qa:
		return {"passed": false, "checks": [], "notes": ["Refused: integration fixtures require the isolated QA save slot."]}
	_capture_saves()
	_release_all()
	host.set_overlay("")
	await _wait(0.15)
	await _check_overlays()
	await _check_action_exclusion()
	await _check_doors_and_camp()
	await _check_unique_rewards()
	_check_save_recovery()
	_restore_saves()
	_release_all()
	host.set_overlay("")
	notes.append("Room placement, HP setup, and damaged saves are explicit fixtures; no assertion here substitutes for input-driven end-to-end completion.")
	notes.append("Both QA save files were restored to their pre-fixture bytes; the normal save-v1.json slot was never selected.")
	var passed = not checks.is_empty()
	for check in checks:
		if not check.passed: passed = false
	return {"passed": passed, "checks": checks, "notes": notes}

func _check_overlays() -> void:
	host.game.reset_game()
	await _room(0)
	await _tap("pause")
	var frozen_time = host.level.time
	var frozen_position: Vector2 = host.level.player.position
	await _wait(0.16)
	_add("pause_freezes_world", get_tree().paused and host.paused and absf(host.level.time-frozen_time)<0.001 and host.level.player.position.distance_to(frozen_position)<0.01, "Esc pauses level time and player motion while the test node continues.")
	await _tap("map")
	_add("pause_to_map_consistent", _overlay_consistent(), "After Esc -> Tab, menu visibility and pause mirrors agree with SceneTree.paused.")
	await _tap("map")
	_add("map_toggle_consistent", _overlay_consistent(), "After Esc -> Tab -> Tab, no stale paused boolean remains on an active world.")
	host.set_overlay("")
	host.finish()
	await _wait(0.08)
	_add("completion_overlay_visible", host.menu.visible, "finish() opens the actual completion page.")
	await _tap("pause")
	_add("completion_esc_explores", not get_tree().paused and not host.menu.visible and not host.paused and not host.map_open, "Esc closes completion and resumes exploration, rather than opening the pause page.")
	host.finished = false
	host.set_overlay("")

func _overlay_consistent() -> bool:
	return bool(get_tree().paused) == bool(host.paused or host.map_open) and bool(host.menu.visible) == bool(get_tree().paused)

func _check_action_exclusion() -> void:
	host.game.data.dash = true
	await _room(0)
	await _place(Vector2(3*64,14*64-1))
	var p = host.level.player
	host.game.hp = 3
	host.game.energy = 4
	Input.action_press("dash")
	await _wait(0.035)
	Input.action_release("dash")
	var dashing = p.dash_time > 0
	Input.action_press("heavy")
	Input.action_press("heal")
	await _wait(0.035)
	Input.action_release("heavy")
	Input.action_release("heal")
	_add("dash_rejects_heavy_heal", dashing and p.attack_time<0 and p.heal_time<0 and host.game.energy==4, "During a genuine ground dash, R/F must neither start actions nor spend energy.")
	await _wait(0.9)
	# Elevated fixture stays airborne for >0.8 s cooldown; this tests air-use
	# restriction independently of cooldown. No invulnerability is granted.
	p.position = Vector2(3*64,14*64-450)
	p.velocity = Vector2.ZERO
	p.dash_time = 0
	p.dash_cooldown = 0
	p.air_dash = false
	await _wait(0.04)
	var before = _events("dash")
	await _tap("dash")
	await _wait(0.79)
	var still_airborne = not p.is_on_floor()
	var cooldown_ready = p.dash_cooldown<=0
	await _tap("dash")
	_add("one_air_dash_per_flight", still_airborne and cooldown_ready and _events("dash")==before+1 and p.air_dash, "Second Shift is rejected while airborne even after cooldown expires; first dash was initiated through Input.")
	_release_all()
	await _room(0)

func _check_doors_and_camp() -> void:
	host.game.data.boss = true
	host.game.data.dash = true
	for index in range(host.rooms.size()):
		await _room(index,"right")
		var rightmost: Dictionary = {}
		for platform in host.rooms[index].platforms:
			if not str(platform.id).begins_with("P"): continue
			if rightmost.is_empty() or float(platform.x)+float(platform.w)>float(rightmost.x)+float(rightmost.w): rightmost=platform
		var p = host.level.player
		var x_ok = p.position.x>float(rightmost.x)*64 and p.position.x<(float(rightmost.x)+float(rightmost.w))*64
		var y_ok = absf(p.position.y-float(rightmost.y)*64)<12
		_add("right_entry_"+str(host.rooms[index].id), x_ok and y_ok, "Right entry must stand on the rightmost main P platform, including rooms with fewer than five platforms.")
	await _room(3)
	host.game.hp=2
	host.game.energy=1
	await _place(Vector2(2.8*64,14*64-1))
	await _tap("interact")
	_add("camp_interaction_separate", host.game.room_index==3 and host.game.data.checkpoint==3 and host.game.hp==4 and host.game.energy==4, "E near camp rests and does not accidentally change rooms.")
	await _place(Vector2(0.8*64,14*64-1))
	await _tap("interact")
	await _wait(0.15)
	_add("boss_room_left_exit", host.game.room_index==2, "E at Boss-room left door returns to R1-03 after victory; camp must not intercept it.")
	host.game.data.boss=false
	host.game.data.dash=false
	await _room(3)
	host.level.boss_started=true
	host.game.hp=2
	host.game.energy=1
	await _place(Vector2(2.8*64,14*64-1))
	await _tap("interact")
	_add("combat_cannot_rest", host.game.hp<=2 and host.game.energy==1, "After combat begins, the camp cannot restore health or energy, including if a boundary relocates the player.")
	host.game.data.boss=true
	await _room(0)

func _check_unique_rewards() -> void:
	host.game.data.fragment=false
	await _room(2)
	var before = _events("fragment")
	await _place(Vector2(24.5*64,11.3*64-1))
	await _tap("interact")
	await _tap("interact")
	var first_once = host.game.data.fragment and _events("fragment")==before+1
	await _room(0)
	await _room(2)
	await _place(Vector2(24.5*64,11.3*64-1))
	await _tap("interact")
	_add("fragment_is_unique", first_once and _events("fragment")==before+1, "Original U0 reward platform grants exactly one fragment event, including after re-entry.")
	host.game.data.boss=true
	host.game.data.dash=false
	await _room(3)
	before=_events("dash_unlock")
	await _place(Vector2(32*64,14*64-1))
	await _tap("interact")
	await _tap("interact")
	_add("dash_grant_is_unique", host.game.data.dash and _events("dash_unlock")==before+1, "A1 can be received once after Boss victory; repeated E does not grant it again.")
	host.game.data.habitat=false
	await _room(4)
	before=_events("habitat")
	await _place(Vector2(4*64,14*64-1))
	await _tap("interact")
	await _tap("interact")
	await _room(3)
	await _room(4)
	await _place(Vector2(4*64,14*64-1))
	await _tap("interact")
	_add("habitat_is_unique", host.game.data.habitat and _events("habitat")==before+1, "H1 is committed once and stays completed on revisit.")

func _check_save_recovery() -> void:
	var path: String = host.game.save_file
	var valid = {"version":1,"checkpoint":3,"boss":true,"dash":true,"fragment":true,"habitat":true,"complete":true}
	_write(path+".bak",JSON.stringify(valid).to_utf8_buffer())
	_write(path,"{ deliberately truncated".to_utf8_buffer())
	host.game.data={"version":1,"checkpoint":0,"boss":false,"dash":false,"fragment":false,"habitat":false,"complete":false}
	host.game.load_game()
	_add("truncated_primary_uses_backup", host.game.data.checkpoint==3 and host.game.data.boss and host.game.data.dash and host.game.data.complete, "Malformed primary QA save falls back to the valid .bak, preserving progression.")
	var invalid=valid.duplicate()
	invalid.checkpoint=99
	_write(path+".bak",JSON.stringify(valid).to_utf8_buffer())
	_write(path,JSON.stringify(invalid).to_utf8_buffer())
	host.game.data.checkpoint=0
	host.game.load_game()
	_add("invalid_checkpoint_uses_backup", host.game.data.checkpoint==3, "Valid JSON with impossible checkpoint is rejected before indexing room data.")
	invalid=valid.duplicate()
	invalid.dash="yes"
	_write(path+".bak",JSON.stringify(valid).to_utf8_buffer())
	_write(path,JSON.stringify(invalid).to_utf8_buffer())
	host.game.data.dash=false
	host.game.load_game()
	_add("invalid_type_uses_backup", typeof(host.game.data.dash)==TYPE_BOOL and host.game.data.dash, "A string in a progression boolean is rejected rather than merged into runtime state.")

func _room(index: int,entry: String="left") -> void:
	_release_all()
	host.set_overlay("")
	host.change_room(index,entry)
	await _wait(0.18)

func _place(position: Vector2) -> void:
	var p = host.level.player
	p.position=position
	p.velocity=Vector2.ZERO
	p.attack_time=-1
	p.heal_time=-1
	p.dash_time=0
	p.hurt_time=0
	await _wait(0.12)

func _tap(action: String) -> void:
	Input.action_press(action)
	await _wait(0.04)
	Input.action_release(action)
	await _wait(0.04)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds,true).timeout

func _events(event: String) -> int:
	var count=0
	for item in host.game.events:
		if item.event==event: count+=1
	return count

func _add(id: String,passed: bool,detail: String) -> void:
	checks.append({"id":id,"passed":passed,"notes":detail})
	print("INTEGRATION_CHECK ",id," ",passed)

func _release_all() -> void:
	for action in ["left","right","jump","attack","heavy","heal","interact","lamp","dash","pause","map","restart","camp"]:
		Input.action_release(action)

func _capture_saves() -> void:
	for suffix in ["",".bak",".tmp"]:
		var path: String=host.game.save_file+suffix
		original_saves[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null

func _restore_saves() -> void:
	for path in original_saves:
		if original_saves[path]==null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else: _write(path,original_saves[path])

func _write(path: String,bytes: PackedByteArray) -> void:
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		_add("fixture_file_write",false,"Could not write isolated QA fixture: "+path)
		return
	file.store_buffer(bytes)
	file.close()
