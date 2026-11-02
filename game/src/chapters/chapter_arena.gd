class_name ChapterArena
extends BossArena


func _physics_process(delta: float) -> void:
	if not GameState.has_flag("chapter.challenge"):
		$Curtain.hide()
		return
	super._physics_process(delta)
