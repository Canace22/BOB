class_name CampaignSaveBridge
extends RefCounted
## Keeps the restored V6 campaign separate from the modular game's save.json.

static func prepare(import_legacy: bool) -> void:
	DirAccess.make_dir_recursive_absolute("user://whalebelly")
	if not import_legacy:
		return
	import_from(OS.get_data_dir().path_join("WhalefallArtmatchV05"), "user://whalebelly")

static func import_from(old_dir: String, target_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(target_dir)
	for filename: String in ["artmatch_save.json", "tide_campaign_guide.cfg", "tide_3c_guide.cfg"]:
		var source := old_dir.path_join(filename)
		var target := target_dir.path_join(filename)
		if FileAccess.file_exists(target) or not FileAccess.file_exists(source):
			continue
		if filename.ends_with(".json"):
			var parser := JSON.new()
			if parser.parse(FileAccess.get_file_as_string(source)) != OK:
				continue
			var data: Variant = parser.data
			if not data is Dictionary or int(data.get("version", 0)) < 6:
				continue
		DirAccess.copy_absolute(source, ProjectSettings.globalize_path(target))
