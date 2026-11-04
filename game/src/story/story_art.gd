class_name StoryArt
extends RefCounted
## All new visual actors use authored bitmap frames and explicit measured roots.

static func actor(key: String, height: float) -> StorySpriteAnimator:
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://art/story-c01/characters/animations.json"))
	var visual := StorySpriteAnimator.new()
	if not metadata is Dictionary or not metadata.get("actors", {}).has(key):
		push_error("Missing story actor metadata: " + key)
		return visual
	var spec: Dictionary = metadata.actors[key]
	visual.configure(load(spec.texture), spec.actions, height, float(spec.reference_height),
		Vector2(float(spec.root[0]), float(spec.root[1])))
	return visual
