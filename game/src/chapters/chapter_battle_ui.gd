class_name ChapterBattleUI
extends CrabArenaUI


func _process(delta: float) -> void:
	super._process(delta)
	title.text = "第二章 · 折井封锁口"
	dash_button.hide()
	if arena.stage == "won":
		start_button.text = "继续救巢 · Enter"
		result_time.text = "%.1f 秒 · Enter 继续前行" % arena.battle_time
		if not (arena as ChapterMotherBattle).outcome_saved:
			result_time.text = "进度保存失败 · Enter 重试保存"
	elif arena.stage == "lost":
		message.text = "回声与通路已保留\n按 Enter 重试封锁口"
