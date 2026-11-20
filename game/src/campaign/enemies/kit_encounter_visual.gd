class_name KitEncounterVisual
extends RefCounted
## Visual-only factory: sprite atlases and the optional organ at a swarm's center.
const ClamFrames = preload("res://src/campaign/enemies/kit_clam_visual.gd")
const Bloodnest = preload("res://src/campaign/enemies/kit_bloodnest_visual.gd")

static func swarm_body(config: Dictionary, seed_id: int) -> KitSwarmVisual:
	var vortex: bool = str(config.get("swarm_visual", "")) == "bloodnest_vortex"
	var swarm: KitSwarmVisual = Bloodnest.new() if vortex else KitSwarmVisual.new()
	swarm.texture = load(str(config.sprites.body.path))
	swarm.member_scale = float(config.sprites.body.scale)
	swarm.count = int(config.get("count",16))
	var radius: float = float(config.get("radius",80.0))
	swarm.spread = Vector2(radius,radius*0.55)
	if vortex: (swarm as KitBloodnestVisual).base_tint=Color(str(config.get("tint","ffffff")))
	if vortex and config.sprites.has("trail"): (swarm as KitBloodnestVisual).trail_texture=load(str(config.sprites.trail.path))
	swarm.build(seed_id)
	swarm.position.y = -radius * (0.82 if vortex else 0.55)
	return swarm

static func single_body(config: Dictionary, kind: String) -> Sprite2D:
	var spec: Dictionary = config.sprites.body
	var path: String = str(spec.path)
	var fallback: bool = not ResourceLoader.exists(path)
	if fallback: path = str(spec.get("fallback_path", path))
	var animated: bool = kind == "clam" and not fallback and int(spec.get("columns", 1)) * int(spec.get("rows", 1)) > 1
	var sprite: Sprite2D = ClamFrames.new() if animated else Sprite2D.new()
	sprite.texture = load(path)
	if animated:
		sprite.hframes = maxi(1, int(spec.get("columns", 1)))
		sprite.vframes = maxi(1, int(spec.get("rows", 1)))
	var scale_value: float = float(spec.get("fallback_scale", spec.scale) if fallback else spec.scale)
	sprite.scale = Vector2.ONE * scale_value
	var offset: Array = config.get("offset", [0, 0])
	sprite.position = Vector2(float(offset[0]), float(offset[1]) - sprite.texture.get_height() * scale_value / sprite.vframes * 0.5)
	var pivot: Variant = spec.get("fallback_pivot") if fallback else spec.get("pivot")
	if pivot is Array and pivot.size() == 2:
		var frame_size: Vector2 = sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
		sprite.position = Vector2(float(offset[0]), float(offset[1])) + (frame_size * 0.5 - Vector2(float(pivot[0]), float(pivot[1]))) * scale_value
	return sprite

static func attach_core(parent: Node2D, config: Dictionary) -> Sprite2D:
	var spec: Dictionary = config.sprites.get("core", {})
	if spec.is_empty() or not ResourceLoader.exists(str(spec.get("path", ""))): return null
	var core := Sprite2D.new()
	core.name = "SwarmCore"
	core.texture = load(str(spec.path))
	core.scale = Vector2.ONE * float(spec.scale)
	var offset: Array = spec.get("offset", [0, 0])
	core.position = Vector2(float(offset[0]), float(offset[1]))
	core.z_index = 1
	core.set_meta("authored_scale", core.scale)
	if parent is KitBloodnestVisual:
		core.position=Vector2(20,0)
		core.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var material_:=ShaderMaterial.new()
		material_.shader=Bloodnest.Swim
		core.material=material_
	parent.add_child(core)
	return core

static func update(body: Node2D, core: Sprite2D, state: String, timer: float, duration: float, clock: float) -> void:
	if body is KitBloodnestVisual:
		var tint: Color=body.base_tint
		tint.a=body.modulate.a
		body.modulate=tint # Local shell reaction replaces the legacy whole-cluster flash.
	if body.has_method("update_at"): body.call("update_at", clock, state, timer, duration)
	elif body.has_method("update_pose"): body.call("update_pose", state, timer, duration)
	if not is_instance_valid(core): return
	var amplitude: float = 0.055 if state == "tell" else 0.025
	var original: Vector2 = core.get_meta("authored_scale", Vector2.ONE)
	core.scale = original * (1.0 + sin(clock * 5.0) * amplitude)
	if body is KitBloodnestVisual:
		core.rotation=sin(clock*1.4)*0.1
		core.position=Vector2(20+sin(clock*1.3)*5.0,cos(clock*1.7)*4.0)
		(core.material as ShaderMaterial).set_shader_parameter("clock",clock)

static func hit(body: Node2D, source: Vector2) -> void:
	if body is KitBloodnestVisual: body.receive_hit(source-body.position)
