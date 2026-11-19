extends TestSuite
## 触发条件和旧V6兼容；不依赖正式主线场景、角色或真实存档。
class StoryHost extends Node2D:
	var room: Dictionary = {"id":"R1-01"}
	var scenery: Node2D
	var collected: Dictionary = {}
	var abilities: Dictionary = {}
	func has_ability(id: String) -> bool: return bool(abilities.get(id,false))
	func record_event(_id: String, _data: Dictionary) -> void: pass
	func save_progress(_show: bool) -> void: pass

func test_dialogue_trigger_conditions_and_replay_are_explicit() -> void:
	var host := StoryHost.new()
	host.scenery=Node2D.new()
	host.add_child(host.scenery)
	add(host)
	var trigger := WhaleDialogueTrigger.new()
	trigger.dialogue_id="qa.once"
	trigger.room_id="R1-01"
	trigger.lines=PackedStringArray(["测试"])
	host.scenery.add_child(trigger)
	check(trigger.eligible(host,{}),"new trigger is eligible")
	check(not trigger.eligible(host,{"qa.once":true}),"once blocks replay")
	trigger.once=false
	check(trigger.eligible(host,{"qa.once":true}),"explicit repeat permits rereading")
	trigger.required_seen=PackedStringArray(["qa.previous"])
	check(not trigger.eligible(host,{}),"prerequisite blocks trigger")
	trigger.required_collected=PackedStringArray(["R1-03"])
	check(not trigger.eligible(host,{"qa.previous":true}),"collection is a separate prerequisite")
	host.collected["R1-03"]=true
	trigger.required_abilities=PackedStringArray(["dash"])
	check(not trigger.eligible(host,{"qa.previous":true}),"ability condition is checked")
	host.abilities.dash=true
	check(trigger.eligible(host,{"qa.previous":true}),"all conditions satisfied")
	trigger.blocked_seen=PackedStringArray(["qa.end"])
	check(not trigger.eligible(host,{"qa.previous":true,"qa.end":true}),"completed branch can block earlier text")
	host.room.id="R1-02"
	check(not trigger.eligible(host,{"qa.previous":true}),"resident neighbour cannot start dialogue")

func test_dialogue_save_is_optional_and_rejects_malformed_state() -> void:
	var path: String = "user://dialogue-unit-v6.json"
	var payload: Dictionary = {"version":6,"checkpoint":{"room":0,"pos":[]},"abilities":{},"collected":{},"defeated":{}}
	eq(WhaleUISaveAccess.write(path,payload),OK,"write old V6 fixture")
	check(not WhaleUISaveAccess.read(path,[{}]).is_empty(),"V6 without story still loads")
	payload.narrative={"seen":{"qa.opening":true},"objective":{"id":"qa.goal","text":"前往灯光处","room":"R1-01"}}
	WhaleUISaveAccess.write(path,payload)
	eq(WhaleUISaveAccess.read(path,[{}]).narrative,payload.narrative,"story and objective roundtrip")
	payload.narrative.seen["bad"]="true"
	WhaleUISaveAccess.write(path,payload)
	check(WhaleUISaveAccess.read(path,[{}]).is_empty(),"invalid flag type rejected")
	payload.narrative={"seen":{},"objective":{"text":42}}
	WhaleUISaveAccess.write(path,payload)
	check(WhaleUISaveAccess.read(path,[{}]).is_empty(),"invalid objective type rejected")
	for suffix: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func test_rereading_old_dialogue_never_rolls_back_new_objective() -> void:
	var host := StoryHost.new()
	add(host)
	var story := WhaleCampaignDialogue.new()
	story.host=host
	host.add_child(story)
	story.set_process(false)
	var old: Dictionary = {"id":"qa.old","room":"R1-01","objective_id":"qa.first_goal","objective":"先看灯"}
	story._commit(old,true)
	eq(story.objective.id,"qa.first_goal","skip sets first objective")
	story._commit({"id":"qa.next","room":"R1-01","objective_id":"qa.next_goal","objective":"向前走"},false)
	story._commit(old,false)
	eq(story.objective.id,"qa.next_goal","repeated text cannot undo later progress")
