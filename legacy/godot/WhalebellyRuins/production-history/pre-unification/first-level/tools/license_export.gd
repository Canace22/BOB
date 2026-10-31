extends SceneTree
func _initialize() -> void:
	var out="G:/鲸落万物生/builds/须门遗港-v0.1/"
	var f=FileAccess.open(out+"GODOT-LICENSE.txt",FileAccess.WRITE)
	f.store_string(Engine.get_license_text())
	f.close()
	f=FileAccess.open(out+"GODOT-THIRD-PARTY.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"licenses":Engine.get_license_info(),"copyright":Engine.get_copyright_info()},"\t"))
	f.close()
	quit()
