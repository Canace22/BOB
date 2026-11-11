class_name DoorwayTestHost
extends WhalebellyMain
## Separate this suite from native QA running in another checkout.
var suite: String = "doors"
func save_path() -> String:
	return "user://whalebelly/doorway-" + suite + "-qa.json"
