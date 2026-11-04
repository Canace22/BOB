extends TestSuite

func test_v6_validation_and_atomic_write() -> void:
	var path := "user://whalebelly/ui-validation-test.json"
	var rooms: Array = [{"id":"R1-01"}]
	var payload: Dictionary = {"version":6,"checkpoint":{"room":0,"pos":[]},"abilities":{},"visited":{}}
	eq(WhaleUISaveAccess.write(path,payload),OK,"Valid save writes")
	check(not WhaleUISaveAccess.read(path,rooms).is_empty(),"V6 without optional fields reads")
	payload.checkpoint.room=5
	WhaleUISaveAccess.write(path,payload)
	check(WhaleUISaveAccess.read(path,rooms).is_empty(),"Out-of-range checkpoint cannot enable Continue")
	check(not WhaleUISaveAccess.read(path+".bak",rooms).is_empty(),"Previous complete save retained")
	payload.checkpoint={"room":0,"pos":["invalid",3]}
	WhaleUISaveAccess.write(path,payload)
	check(WhaleUISaveAccess.read(path,rooms).is_empty(),"Malformed position rejected")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func test_preferences_round_trip() -> void:
	var preferences := WhaleUIPreferences.new()
	preferences.path="user://whalebelly/ui-preferences-test.cfg"
	preferences.numbers=false
	preferences.contrast=true
	preferences.reduce_motion=true
	preferences.volume=0.37
	preferences.muted=true
	eq(preferences.write(),OK,"Settings persisted")
	var loaded := WhaleUIPreferences.new()
	loaded.path=preferences.path
	loaded.read()
	check(not loaded.numbers and loaded.contrast and loaded.reduce_motion and loaded.muted,"Boolean options survive reload")
	check(is_equal_approx(loaded.volume,0.37),"Actual volume survives reload")
	DirAccess.remove_absolute(preferences.path)
