class_name ChapterMotherBattle
extends CrabArena
## Reuse the complete mother-crab fight; only entry, outcome and save routing differ.

signal journey_requested
var progress_path := "user://chapters-v1.json"
var outcome_saved := false
var leaving := false


func _ready() -> void:
	super._ready()
	start()


func _victory() -> void:
	super._victory()
	# The chapter guard survives; retain the grounded original resting pose.
	boss.set_physics_process(false)
	boss.visual.set_physics_process(false)
	boss.state = "waiting"
	boss.visual.present(boss)
	var data := SaveService.read(progress_path)
	for flag: String in ["chapter.guard", "chapter.mother_victory"]:
		if not data.flags.has(flag):
			data.flags.append(flag)
	data.checkpoint_room = "N02-B"
	outcome_saved = SaveService.write(data, progress_path)


func start() -> void:
	if stage == "won":
		continue_journey()
	else:
		super.start()


func continue_journey() -> void:
	if leaving:
		return
	if not outcome_saved:
		_victory()
		if not outcome_saved:
			return
	leaving = true
	journey_requested.emit()


func toggle_dash() -> void:
	pass
