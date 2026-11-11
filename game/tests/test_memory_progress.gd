extends TestSuite

class SavedCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/memory-migration-test.json"

func test_old_v6_without_reward_opens_rings_only() -> void:
	verify_old_save(false)

func test_old_v6_collected_memory_restores_float() -> void:
	verify_old_save(true)

func verify_old_save(has_memory: bool) -> void:
	var host := SavedCampaign.new()
	host.qa_full_abilities = false
	host.rooms = [{"id":"R1-02"}]
	var payload: Dictionary = {"version":6,"checkpoint":{"room":0,"pos":[1000,640]},
		"abilities":{"dash":false,"anchor":false,"float":false},
		"collected":{"R1-07":true} if has_memory else {},"visited":{"R1-02":true}}
	eq(WhaleUISaveAccess.write(host.save_path(),payload),OK,"Old V6 fixture writes")
	host.load_progress()
	check(host.has_ability("anchor"),"Old locked anchor opens without resetting checkpoint")
	eq(host.has_ability("float"),has_memory,"Float follows the permanent memory reward")
	check(not host.has_ability("dash"),"Unrelated Boss unlock stays unchanged")
	eq(host.point(host.checkpoint.pos),Vector2(1000,640),"Existing checkpoint retained")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(host.save_path()+suffix): DirAccess.remove_absolute(host.save_path()+suffix)
	host.free()
