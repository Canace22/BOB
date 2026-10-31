extends Node

var data: Dictionary = {"version":1,"checkpoint":0,"boss":false,"dash":false,"fragment":false,"habitat":false,"complete":false,"latch":false}
var hp: int = 4
var energy: int = 4
var qa := false
var transient := false
var events: Array = []
var room_index := 0
var hits_on_boss := 0
var deaths := 0
var save_file: String:
	get: return "user://save-qa.json" if qa else "user://save-v1.json"

func record(event: String, detail: Dictionary = {}) -> void:
	events.append({"frame":Engine.get_physics_frames(),"event":event,"room":room_index,"detail":detail})
	print("EVENT ",event," ",JSON.stringify(detail))

func save_game() -> void:
	if transient: return
	var file := FileAccess.open(save_file + ".tmp",FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(save_file):
		DirAccess.copy_absolute(save_file,save_file+".bak")
	DirAccess.rename_absolute(save_file+".tmp",save_file)

func load_game() -> void:
	for candidate in [save_file, save_file+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var json=JSON.new()
		if json.parse(FileAccess.get_file_as_string(candidate))!=OK: continue
		var parsed=json.data
		if not parsed is Dictionary or parsed.get("version",0)!=1: continue
		var checkpoint_value=parsed.get("checkpoint",-1)
		if not typeof(checkpoint_value) in [TYPE_INT,TYPE_FLOAT]: continue
		if checkpoint_value!=0 and checkpoint_value!=3: continue
		var valid=true
		for key in ["boss","dash","fragment","habitat","complete"]:
			if not parsed.get(key) is bool: valid=false
		if not valid: continue
		if parsed.has("latch") and not parsed.latch is bool: continue
		if parsed.dash and not parsed.boss: continue
		if parsed.complete and not parsed.dash: continue
		data.merge(parsed,true)
		data.checkpoint=int(data.checkpoint)
		if candidate.ends_with(".bak"): record("save_recovered")
		return

func reset_game() -> void:
	data={"version":1,"checkpoint":0,"boss":false,"dash":false,"fragment":false,"habitat":false,"complete":false,"latch":false}
	hp=4
	energy=4
	save_game()
	record("new_journey")
