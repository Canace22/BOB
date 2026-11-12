extends TestSuite

class SavedCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/relics-test-%s.json" % str(ProjectSettings.globalize_path("res://").hash())

func test_ownership_stacks_in_either_order() -> void:
	eq(CampaignRelics.capacity({}), 0, "No free shield on new journey")
	eq(CampaignRelics.capacity({"R1-06":true}), 1, "Optional fragment works before shell")
	eq(CampaignRelics.capacity({"R1-03":true}), 2, "Main route shell gives two points")
	eq(CampaignRelics.capacity({"R1-03":true,"R1-06":true,"R1-07":true}), 3, "Both relics stack, memory does not add shield")

func test_damage_overflow_and_falls() -> void:
	var relics := CampaignRelics.new()
	relics.refill({"R1-03":true})
	eq(relics.absorb(1,true), 1, "Fall damage bypasses protection")
	eq(relics.charges, 2, "Fall does not waste charges")
	eq(relics.absorb(0,false), 0, "Zero damage consumes nothing")
	eq(relics.absorb(3,false), 1, "Excess damage reaches health")
	eq(relics.charges, 0, "Charges cannot become negative")
	eq(relics.absorb(1,false), 1, "Empty shield leaves combat unchanged")

func test_old_v6_and_new_journey() -> void:
	var host := SavedCampaign.new()
	host.rooms = [{"id":"R1-01"}]
	var payload := {"version":6,"checkpoint":{"room":0,"pos":[240,610]},"collected":{"R1-03":true,"R1-06":true}}
	eq(WhaleUISaveAccess.write(host.save_path(),payload), OK, "Old save fixture writes")
	host.load_progress()
	eq(host.relics.charges, 3, "Old collected rewards gain their benefits automatically")
	eq(host.point(host.checkpoint.pos), Vector2(240,610), "Checkpoint unchanged")
	payload.collected = {}
	WhaleUISaveAccess.write(host.save_path(),payload)
	host.load_progress()
	eq(host.relics.charges, 0, "Empty new progress removes old shield")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(host.save_path()+suffix): DirAccess.remove_absolute(host.save_path()+suffix)
	host.free()

func test_real_damage_pipeline_and_room_lifecycle() -> void:
	var scene: PackedScene = load("res://content/whalebelly/main.tscn")
	var host: WhalebellyMain = scene.instantiate()
	host.set_script(SavedCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	await physics_frames(20)
	host.collected["R1-03"] = true
	host.relics.refill(host.collected)
	var p: WhalebellyCampaignPlayer = host.player
	check(p.skill_controller.request("parry"), "Existing parry remains available")
	p.skill_controller.elapsed = float(p.skill_controller.data.release)
	check(not p.take_damage(1), "Successful parry rejects hit before shield")
	eq(host.relics.charges, 2, "Parry does not consume shield")
	p.skill_controller.cancel()
	p.invulnerable = 0
	p.take_damage(1)
	eq(p.health, 5, "Actual enemy damage is absorbed")
	eq(p.soul, 99, "Full block preserves soul")
	eq(host.relics.charges, 1, "One point spent")
	p.take_damage(1)
	eq(host.relics.charges, 1, "Repeated contact in invulnerability spends nothing")
	p.invulnerable = 0
	p.take_damage(2)
	eq(p.health, 4, "Only damage overflow reaches life")
	eq(p.soul, 99, "Taking damage no longer drains soul")
	host.load_room(1)
	eq(host.relics.charges, 0, "Door load does not recharge shield")
	host.load_room(0, [240,610])
	check(host.try_camp(), "Existing camp accepts rest")
	eq(host.relics.charges, 2, "Camp restores acquired protection")
	eq(host.health, 5, "Camp still restores health")
	host.relics.charges = 1
	var practice_key := InputEventKey.new()
	practice_key.physical_keycode = KEY_F9
	practice_key.pressed = true
	host._unhandled_key_input(practice_key)
	host.collected["R1-06"] = true
	host.relics.refill(host.collected)
	host._unhandled_key_input(practice_key)
	eq(host.relics.charges, 1, "Exiting practice restores spent charges")
	check(not host.collected.get("R1-06", false), "Practice cannot keep optional loot")
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for tween: Tween in tree.get_processed_tweens(): tween.kill()
	for sound: Node in host.find_children("*", "AudioStreamPlayer", true, false):
		sound.stop()
		sound.stream = null
	host.sound_bank.clear()
	host.sound_variants.clear()
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(host.save_path()+suffix): DirAccess.remove_absolute(host.save_path()+suffix)
	await tree.create_timer(0.3).timeout
