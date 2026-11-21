extends TestSuite

func test_chapter_three_progress_has_its_own_namespace() -> void:
	var second:=ChapterTwoWhitebox.new()
	var third:=ChapterThreeWhitebox.new()
	second.qa_save_suffix="chapter-three-unit"
	third.qa_save_suffix="chapter-three-unit"
	check(second.save_path()!=third.save_path(),"Chapters cannot overwrite one another")
	check(third.save_path().begins_with("user://chapter-three-whitebox/"),"No campaign save is used")
	third.facts={"enemy_cleared":true}
	eq(third.checkpoint(),Vector2(2020,640),"Victory resumes beside valve, not after opening")
	third.facts.valve_opened=true
	eq(third.checkpoint(),Vector2(900,510),"Interrupted flood resumes on safe resident platform")
	check(not third.facts.get("settled",false),"Opening does not skip aftermath dialogue or repairs")
	second.free()
	third.free()
