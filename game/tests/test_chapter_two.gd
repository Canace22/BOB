extends TestSuite

func test_whitebox_save_is_separate_and_roundtrips_only_its_facts() -> void:
	var host := ChapterTwoWhitebox.new()
	host.qa_save_suffix = "unit-test"
	check(host.save_path().begins_with("user://chapter-two-whitebox/"),"No campaign save path is used")
	host.facts = {"refusal":true,"guard_defeated":true,"rescue_done":false}
	host.save_progress()
	check(not host.save_failed,"Independent save succeeds")
	var restored := ChapterTwoWhitebox.new()
	restored.qa_save_suffix = "unit-test"
	restored.read_progress()
	eq(restored.facts,host.facts,"Interrupted rescue restores defeated guard without inventing permission")
	DirAccess.remove_absolute(host.save_path())
	host.free()
	restored.free()

func test_checkpoint_tracks_safe_phase_without_skipping_rescue() -> void:
	var host := ChapterTwoWhitebox.new()
	eq(host.checkpoint(),Vector2(150,290),"New run starts above the descent")
	host.facts.refusal = true
	eq(host.checkpoint(),Vector2(1000,510),"Boss retry skips already-seen refusal and descent")
	host.facts.guard_defeated = true
	eq(host.checkpoint(),Vector2(1760,510),"Victory retry is before safe rescue trigger, beyond combat")
	check(not host.facts.get("permit",false),"Victory never directly grants permission")
	host.free()
