extends SceneTree
## Copies runtime art listed in res://art/manifest.json from the repo into res://art/.
## "src" is relative to the repo root; a trailing "/" copies every png/wav in that folder.
## "max" (optional) downscales PNGs so the longer side is at most that many pixels.
## Run via: node tools/godot.mjs sync-art

const MANIFEST := "res://art/manifest.json"
const EXTENSIONS := ["png", "wav", "ogg"]


func _initialize() -> void:
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var copied := 0
	var errors := 0
	for entry: Dictionary in manifest["entries"]:
		var pairs := _expand(repo.path_join(entry["src"]), "res://art/".path_join(entry["dest"]))
		if pairs.is_empty():
			printerr("MISSING ", entry["src"])
			errors += 1
		for pair: PackedStringArray in pairs:
			if _copy(pair[0], pair[1], int(entry.get("max", 0))):
				copied += 1
			else:
				errors += 1
	print("sync_art: %d file(s) copied, %d error(s)" % [copied, errors])
	quit(1 if errors > 0 else 0)


func _expand(src: String, dest: String) -> Array[PackedStringArray]:
	var pairs: Array[PackedStringArray] = []
	if not src.ends_with("/"):
		if FileAccess.file_exists(src):
			pairs.append(PackedStringArray([src, dest]))
		return pairs
	for file in DirAccess.get_files_at(src):
		if EXTENSIONS.has(file.get_extension()):
			pairs.append(PackedStringArray([src + file, dest.path_join(file)]))
	return pairs


func _copy(src: String, dest: String, max_size: int) -> bool:
	var target := ProjectSettings.globalize_path(dest)
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if max_size <= 0 or src.get_extension() != "png":
		return DirAccess.copy_absolute(src, target) == OK
	var image := Image.load_from_file(src)
	if image == null:
		printerr("CANNOT LOAD ", src)
		return false
	var longest := maxi(image.get_width(), image.get_height())
	if longest > max_size:
		var scale := float(max_size) / longest
		image.resize(roundi(image.get_width() * scale), roundi(image.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	return image.save_png(target) == OK
