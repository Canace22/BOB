extends TestSuite
## 验证演员与真实遭遇的所有权；图像是否自然仍由GPU和用户验收。

func fixture(chapter: int) -> ChapterRun:
	var host: ChapterRun=preload("res://content/prototypes/chapters/main.tscn").instantiate()
	host.chapter_id=chapter
	host.save_enabled=false
	host.restore_progress=false
	add(host)
	await physics_frames(4)
	host.set_process(false)
	host.player.set_physics_process(false)
	return host

func select_stage(host: ChapterRun, id: String) -> void:
	for i: int in host.data.stages.size():
		if str(host.data.stages[i].id)==id:
			host.flow.index=i
			return
	check(false,"场景内存在稳定阶段: "+id)

func test_dialogue_guard_yields_to_live_encounter_and_retained_body() -> void:
	var host: ChapterRun=await fixture(12)
	var view: ChapterCharacterPresentation=host.view.characters
	select_stage(host,"ch12_elder_duel")
	view.update_run(host)
	check(view.actors.elder.visible,"交锋前演员在场")
	var before: int=hash([host.flags,host.completed])
	host.encounter.prepare(host.flow.stage().enemy)
	host.encounter.spawn(false)
	var enemy: EnemyLabEnemy=host.encounter.enemy
	enemy.set_physics_process(false)
	view.update_run(host)
	check(not view.actors.elder.visible,"生成真实Boss后演员让位，不出现两个老守护者")
	eq(hash([host.flags,host.completed]),before,"显示更新不伪造交锋完成")
	enemy.health=0
	enemy.finish()
	host.encounter.end_combat()
	host.encounter.retire()
	view.update_run(host)
	check(is_instance_valid(host.encounter.retired_body),"战后真实身体保留")
	check(not view.actors.elder.visible,"非致死战后不额外生成第二个身体")

func test_dead_beam_guard_does_not_reappear_in_aftermath() -> void:
	var host: ChapterRun=await fixture(8)
	var view: ChapterCharacterPresentation=host.view.characters
	select_stage(host,"ch08_no_reply")
	host.flags.ch08_beam_guard_dead=true
	var before: int=hash([host.flags,host.completed])
	for i: int in 10: view.update_run(host)
	check(not view.actors.beam.visible,"死亡后的封梁卫不以闲置演员复活")
	check(view.actors.mender.visible,"善后阶段的补巢者仍在场")
	eq(hash([host.flags,host.completed]),before,"重复更新不写入剧情状态")
