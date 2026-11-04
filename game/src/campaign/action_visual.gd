class_name TideActionVisual
extends Node
## Atlas animation uses physics/state timing; source-video translation is removed offline.
const ROOT: String = "res://art/tide-picker-action36/"
const LEGACY: Dictionary = {"idle":"idle", "run":"run", "jump_land":"jump", "strike_01":"strike1", "strike_02":"double_jump", "A1_dash":"dash", "A2_float":"float", "A3_anchor":"pogo", "A4_parry":"orb", "A5_slit":"slit", "heavy":"heavy", "recover":"heal", "hit":"hurt", "defeat":"defeat", "interact":"interact"}
var actor: TidePlayer
var sprite: Sprite2D
var effect: Sprite2D
var manifest: Dictionary = {}
var cache: Dictionary = {}
var recent: Array[String] = []
var current_key: String = ""
var elapsed: float = 0.0
var target_height: float = 94.0
var active: bool = false
var was_airborne: bool = false
var last_facing: float = 1.0
var turn_left: float = 0.0
var landing_left: float = 0.0
var phase: float = 0.0
var previous_velocity: Vector2 = Vector2.ZERO
var air_elapsed: float = 0.0
var fall_elapsed: float = 0.0
var locked_elapsed: float = 0.0
var available: Dictionary = {}
var additive_material: CanvasItemMaterial
var anchor_active: bool = false
var anchor_elapsed: float = 0.0
var detach_left: float = 0.0
var wall_jump_span: float = 0.15
var frame_index: int = 0
var action_phases := TideActionPhases.new()

func setup(player: TidePlayer, height: float) -> void:
	actor = player
	actor.animation_tag.connect(action_phases.on_animation_tag)
	target_height = height
	if FileAccess.file_exists(ROOT+"animations.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"animations.json"))
		if parsed is Dictionary: manifest = parsed.get("actions", {})
	for key: String in manifest:
		var spec: Dictionary = manifest[key]
		available[key] = spec.has("body") and ResourceLoader.exists(str(spec.body.get("texture", "")))
		if spec.get("fx") != null: available[key] = available[key] and ResourceLoader.exists(str(spec.fx.get("texture", "")))
	sprite = Sprite2D.new()
	sprite.name = "ActionBody"
	sprite.centered = false
	sprite.material = actor.body.material.duplicate()
	sprite.material.set_shader_parameter("split_lower", false)
	sprite.material.set_shader_parameter("legs_only", false)
	actor.get_node("Visual").add_child(sprite)
	effect = Sprite2D.new()
	effect.name = "ActionEffect"
	effect.centered = false
	additive_material=CanvasItemMaterial.new()
	additive_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	actor.get_node("Visual").add_child(effect)

func update(dt: float, travelled_x: float) -> void:
	if actor.hitstop > 0.0: return
	var key: String = choose_key(dt)
	active = bool(available.get(key, false))
	sprite.visible = active
	effect.visible = false
	actor.body.visible = not active
	if not active:
		current_key = key
		var split: bool = actor.lower_body_layer_enabled and actor.is_on_floor() and absf(actor.velocity.x) > 20.0 and actor.state == "strike_01"
		actor.body.material.set_shader_parameter("split_lower", split)
		actor.get_node("Visual/Legs").visible = split
		actor.get_node("Visual/Effect").visible = true
		return
	actor.get_node("Visual/Legs").hide()
	actor.get_node("Visual/Effect").hide()
	if current_key != key:
		current_key = key
		elapsed = 0.0
		phase = 0.0
		locked_elapsed = actor.state_time
	var spec: Dictionary = manifest[key]
	effect.material=additive_material if spec.get("fx_blend","")=="additive" else null
	var count: int = int(spec.frame_count)
	var fraction: float = frame_fraction(key, spec, dt, travelled_x)
	var index: int = clampi(int(fraction*count),0,count-1)
	frame_index=index
	var frames: Dictionary = load_clip(key)
	apply_layer(sprite, frames.body, spec.body, index, float(spec.reference_height))
	sprite.modulate = Color(0.58, 0.78, 0.83, 0.92) if key == "shadow_dash" else Color.WHITE
	if key == "turn": sprite.scale.x *= -1.0
	if spec.get("fx") != null and key not in ["dive", "dark_dive", "orb", "shadow_orb", "anchor", "dash", "shadow_dash", "crystal_dash", "slit", "heavy", "scan"]:
		apply_layer(effect, frames.fx, spec.fx, index, float(spec.reference_height))
		effect.visible = true
	sprite.material.set_shader_parameter("flash", actor.body.material.get_shader_parameter("flash"))

func frame_fraction(key: String, spec: Dictionary, dt: float, travelled_x: float) -> float:
	var count: int = int(spec.frame_count)
	var fraction: float
	var controller: TideSkillController = actor.skill_controller
	if key in ["run", "walk"]:
		# Distance advances the gait; pressing into a wall cannot animate locomotion.
		phase += absf(travelled_x) / (110.0 if key == "run" else 76.0)
		fraction = fposmod(phase, 1.0)
	elif key == "swim":
		elapsed += dt
		fraction = fposmod(elapsed * float(spec.fps) / count, 1.0)
	elif key == "anchor":
		var segments: Dictionary = spec.get("phases", {})
		var hang: Array = segments.get("hang", [0.17,0.80])
		var detach: Array = segments.get("detach", [0.80,1.0])
		if detach_left>0.0: return lerpf(float(detach[0]),float(detach[1]),1.0-detach_left/0.12)
		var enter_time: float = maxf(0.01,float(spec.get("anchor_enter_time",0.08)))
		if anchor_elapsed<enter_time: return anchor_elapsed/enter_time*float(hang[0])
		fraction = float(hang[0])+fposmod((anchor_elapsed-enter_time)*float(spec.fps)/count,maxf(0.01,float(hang[1])-float(hang[0])))
	elif key == "crystal_dash":
		return action_phases.crystal_fraction(spec,controller)
	elif controller.visual_key == key:
		fraction = controller.elapsed / maxf(controller.duration, 0.01)
		if key in ["dive", "dark_dive"] and controller.active:
			var impact: float = clampf(float(spec.get("event_phase", 0.55)), 0.05, 0.95)
			if controller.landed:
				return lerpf(impact, 1.0, clampf((controller.elapsed-controller.landed_at)/maxf(controller.duration-controller.landed_at,0.01),0.0,1.0))
			return minf(impact - 1.0/count, controller.elapsed/maxf(float(controller.data.release),0.01)*(impact-1.0/count))
		if controller.active and spec.has("event_phase"):
			return align_event(fraction, float(controller.data.release)/maxf(controller.duration,0.01), float(spec.event_phase))
	elif key == "wall_jump":
		fraction = 1.0 if actor.wall_lock<=dt+0.0001 else 1.0-actor.wall_lock/maxf(wall_jump_span,0.001)
	elif key == "jump":
		var segments: Dictionary = spec.get("phases", {"rise":[0.08,0.35], "apex":[0.35,0.45], "fall":[0.45,0.70], "land":[0.72,1.0]})
		var segment: String = "rise" if actor.velocity.y < -40.0 else ("fall" if actor.velocity.y > 40.0 else "apex")
		var t: float = clampf((fall_elapsed if segment=="fall" else air_elapsed)/0.24,0.0,1.0)
		if actor.is_on_floor(): segment="land";t=1.0-landing_left/0.12
		var ends: Array = segments[segment]
		fraction = lerpf(float(ends[0]),float(ends[1]),t)
	elif key == "turn": fraction = 1.0-turn_left/0.10
	elif actor.state_duration > 0.0:
		locked_elapsed = actor.state_time if actor.controls_enabled else maxf(locked_elapsed,actor.state_time)+dt
		fraction = locked_elapsed / maxf(actor.state_duration,0.01)
		if spec.has("event_phase"):
			return align_event(fraction, legacy_trigger()/maxf(actor.state_duration,0.01), float(spec.event_phase))
	else:
		elapsed += dt
		fraction = elapsed * float(spec.fps) / count
		if bool(spec.loop): fraction = fposmod(fraction, 1.0)
	return clampf(fraction,0.0,1.0)

func legacy_trigger() -> float:
	if actor.state in ["recover", "interact"]: return actor.state_duration
	var clip: Animation = actor.anim.get_animation("game/"+actor.state)
	var marker: StringName = &"damage" if actor.state in ["strike_01","A3_anchor"] else &"release"
	return clip.get_marker_time(marker)*12.0/actor.animation_fps if clip.has_marker(marker) else 2.0/actor.animation_fps

static func align_event(fraction: float, trigger: float, event_phase: float) -> float:
	fraction=clampf(fraction,0.0,1.0)
	trigger=clampf(trigger,0.0,1.0)
	event_phase=clampf(event_phase,0.0,1.0)
	if trigger<=0.0: return lerpf(event_phase,1.0,fraction)
	if trigger>=1.0: return fraction*event_phase
	return fraction/trigger*event_phase if fraction<=trigger else event_phase+(fraction-trigger)/(1.0-trigger)*(1.0-event_phase)

func choose_key(dt: float) -> String:
	action_phases.tick(dt,actor)
	var air: bool = not actor.is_on_floor()
	var target: Variant = actor.get("grapple_target")
	var anchored: bool = target is Vector2 and target!=Vector2.INF
	if anchored:
		anchor_elapsed = anchor_elapsed+dt if anchor_active else dt
		detach_left=0.0
	elif anchor_active: detach_left=0.12
	else: detach_left=maxf(0.0,detach_left-dt)
	anchor_active=anchored
	if air:
		if not was_airborne or actor.velocity.y < previous_velocity.y-100.0: air_elapsed=0.0;fall_elapsed=0.0
		air_elapsed+=dt
		if actor.velocity.y>40.0: fall_elapsed+=dt
	if was_airborne and not air: landing_left = 0.12
	was_airborne = air
	landing_left = maxf(0.0,landing_left-dt)
	if last_facing != actor.facing and absf(previous_velocity.x)<20.0 and not air: turn_left=0.10
	last_facing = actor.facing
	previous_velocity = actor.velocity
	turn_left=maxf(0.0,turn_left-dt)
	if actor.state in ["hit","defeat"] and actor.state_duration>0.0:
		detach_left=0.0;return str(LEGACY[actor.state])
	if actor.skill_controller.active:
		detach_left=0.0;return actor.skill_controller.visual_key
	if actor.state_duration > 0.0:
		detach_left=0.0;return str(LEGACY.get(actor.state,"idle"))
	# Non-active overlays are selected by gameplay, not merely by a water overlap.
	# Unprotected actors and actors jumping above the surface keep their normal pose.
	if actor.skill_controller.visual_key in ["swim", "crystal_dash", "great_slash", "cyclone"]:
		detach_left=0.0;return actor.skill_controller.visual_key
	if action_phases.crystal_exit_left>0.0: return "crystal_dash"
	if anchored: return "anchor"
	if actor.get("floating") == true:
		detach_left=0.0;return "float"
	if not air and absf(actor.velocity.x)>5.0: detach_left=0.0
	if detach_left>0.0: return "anchor"
	if air:
		if actor.wall_lock > 0.0:
			if current_key!="wall_jump": wall_jump_span=actor.wall_lock
			return "wall_jump"
		if actor._wall_direction()!=0 and actor.velocity.y>0.0: return "wall_slide"
		return "jump"
	if turn_left>0.0: return "turn"
	if absf(actor.velocity.x)>5.0: return "walk" if Input.is_action_pressed("tp_walk") else "run"
	if landing_left>0.0: return "jump"
	return "idle"

func load_clip(key: String) -> Dictionary:
	if not cache.has(key):
		cache[key] = {"body":make_frames(manifest[key].body),"fx":make_frames(manifest[key].get("fx"))}
	if recent.has(key): recent.erase(key)
	recent.append(key)
	if recent.size()>8: cache.erase(recent.pop_front())
	return cache[key]

func make_frames(spec: Variant) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if spec == null: return result
	var texture: Texture2D = load(str(spec.texture))
	for rect: Array in spec.frames:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
		frame.filter_clip = true
		result.append(frame)
	return result

func apply_layer(layer: Sprite2D, frames: Array[Texture2D], spec: Dictionary, index: int, height: float) -> void:
	if frames.is_empty(): return
	layer.texture = frames[mini(index,frames.size()-1)]
	layer.offset = -Vector2(float(spec.pivot[0]),float(spec.pivot[1]))
	layer.scale = Vector2.ONE*target_height/height/actor.visual_scale

func world_socket(key: String, name: String, fallback_world: Vector2, direction: float = 0.0) -> Vector2:
	var spec: Dictionary = manifest.get(key,{})
	var socket: Variant
	if active and current_key==key:
		var sequence: Variant=spec.get("sockets_per_frame",{}).get(name)
		if sequence is Array and frame_index>=0 and frame_index<sequence.size(): socket=sequence[frame_index]
	if not socket is Array or socket.size()!=2: socket=spec.get("sockets",{}).get(name)
	if not socket is Array or socket.size()!=2: return fallback_world
	var facing: float = actor.facing if is_zero_approx(direction) else signf(direction)
	var local: Vector2 = Vector2(float(socket[0])*facing,float(socket[1]))
	return actor.global_position+local*target_height/maxf(float(spec.get("reference_height",160.0)),1.0)
