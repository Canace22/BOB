extends TestSuite


func test_ui_font_covers_current_chinese_text() -> void:
	var font := load("res://art/fonts/WhalefallUI.ttf") as FontFile
	var characters: Dictionary[int, bool] = {}
	for directory: String in ["res://src", "res://content"]:
		_collect(directory, characters)
	for code: int in characters:
		check(font.has_char(code), "UI font missing: " + String.chr(code))


func _collect(directory: String, characters: Dictionary[int, bool]) -> void:
	for child in DirAccess.get_directories_at(directory):
		_collect(directory.path_join(child), characters)
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() not in ["gd", "tscn", "tres"]:
			continue
		var text := FileAccess.get_file_as_string(directory.path_join(file))
		for i in text.length():
			var code := text.unicode_at(i)
			if code >= 0x3400 and code <= 0x9fff:
				characters[code] = true
