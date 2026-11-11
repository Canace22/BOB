extends TestSuite

func make_host(id: String) -> WhalebellyMain:
	var host := WhalebellyMain.new()
	host.qa_full_abilities = false
	host.rooms = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	for i: int in host.rooms.size():
		if str(host.rooms[i].id) == id:
			host.room_index = i
			host.room = host.rooms[i]
	return host

func test_memory_reward_changes_goal_to_return_without_mutating_progress() -> void:
	var host := make_host("R1-07")
	eq(CampaignGuidance.next_room(host), "", "Reward is inside this room")
	host.collected["R1-07"] = true
	eq(CampaignGuidance.next_room(host), "R1-02", "Reward leads back to the hub")
	check(CampaignGuidance.hint(host).contains("左门"), "Return direction is explicit")
	check(not host.abilities.float, "Reading guidance cannot grant an ability")
	host.free()

func test_new_ability_is_optional_not_a_main_route_gate() -> void:
	var host := make_host("R1-02")
	eq(CampaignGuidance.next_room(host), "R1-03", "Main route remains available before float")
	check(CampaignGuidance.description(host,"R1-02").contains("记忆袋"), "Before unlock suggests memory")
	host.abilities.float = true
	eq(CampaignGuidance.next_room(host), "R1-03", "New ability does not redirect main route")
	check(CampaignGuidance.description(host,"R1-02").contains("喷气孔"), "After unlock reveals optional use")
	host.free()

func test_map_marks_only_known_rooms_and_keeps_unopened_exit_honest() -> void:
	var host := make_host("R1-02")
	host.visited = {"R1-01":true,"R1-02":true}
	var data := WhaleUICampaignData.new()
	data.host = host
	var nodes := data.map_rooms()
	check(not nodes.any(func(n: Dictionary) -> bool: return n.id == "R1-04"), "Unseen Boss room stays hidden")
	check(nodes.any(func(n: Dictionary) -> bool: return n.id == "R1-03" and n.next), "Known main doorway is recommended")
	check(data.room_description(5).contains("未开放"), "Upper branch announces its dead end before entry")
	eq(CampaignGuidance.door_label(host, {"to":-2}), "后续区域未开放 · 原路返回", "Sealed exit does not promise entry")
	host.free()

func test_boss_and_completion_goals_follow_saved_flags() -> void:
	var host := make_host("R1-04")
	eq(CampaignGuidance.next_room(host), "", "Live Boss blocks forward recommendation")
	host.defeated["R1-04:0"] = true
	eq(CampaignGuidance.next_room(host), "R1-05", "Saved Boss defeat opens onward goal")
	host.visited = {"R1-04":true}
	var data := WhaleUICampaignData.new()
	data.host = host
	check(data.room_description(4).contains("已具备"), "Defeated Boss gate is described as open")
	host.completed = true
	eq(CampaignGuidance.next_room(host), "", "Completed chapter has no fake next room")
	check(CampaignGuidance.hint(host).contains("首关完成"), "Completion survives a revisit")
	host.free()
