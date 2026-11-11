class_name DoorwayTestHost
extends WhalebellyMain
## Separate this suite from native QA running in another checkout.
var suite: String = "doors"
func save_path() -> String:
	var workspace: String = ProjectSettings.globalize_path("res://").sha256_text().left(12)
	return "user://whalebelly/doorway-" + suite + "-" + workspace + ".json"
