class_name TideWorldEffects
extends Node2D
## Bitmap effects live under the player for ownership, but retain world transforms.
const ROOT: String="res://art/tide-picker-action36/"
const LAND_KEYS: Array[String]=["dive","dark_dive"]
const RELEASE_KEYS: Array[String]=["scan"]
var actor: TidePlayer
var manifest: Dictionary={}
var frames: Dictionary={}
var particles: Array[Dictionary]=[]
var rope: Line2D
var ghost_clock: float=0.0
var last_ghost: Vector2=Vector2.INF
var height: float=94.0

func setup(player: TidePlayer, target_height: float) -> void:
	actor=player
	height=target_height
	if FileAccess.file_exists(ROOT+"animations.json"):
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"animations.json"))
		if parsed is Dictionary: manifest=parsed.get("actions",{})
	actor.skill_effect.connect(_event)
	actor.animation_tag.connect(_animation)
	actor.damaged.connect(clear)
	rope=Line2D.new()
	rope.name="WorldTether"
	rope.top_level=true
	rope.width=7.0
	rope.texture_mode=Line2D.LINE_TEXTURE_TILE
	rope.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	rope.antialiased=true
	if ResourceLoader.exists(ROOT+"tether.png"): rope.texture=load(ROOT+"tether.png")
	add_child(rope)
	rope.hide()

func _process(dt: float) -> void:
	if not is_instance_valid(actor): return
	var hidden: bool=not actor.get_node("Visual").visible
	if actor.health<=0 or not actor.controls_enabled or hidden:
		clear()
		return
	if actor.hitstop>0.0: return
	for i: int in range(particles.size()-1,-1,-1):
		var item: Dictionary=particles[i]
		item.time+=dt
		var visual: Sprite2D=item.node
		if item.time>=item.life:
			visual.queue_free()
			particles.remove_at(i)
			continue
		if item.has("frames"):
			var index: int=mini(int(item.time/item.life*item.frames.size()),item.frames.size()-1)
			visual.texture=item.frames[index]
		else: visual.modulate.a=(1.0-item.time/item.life)*0.30
	_update_rope()
	var dash: bool=actor.state in ["A1_dash","A5_slit"] and actor.state_duration>0
	if not dash:
		last_ghost=Vector2.INF
		ghost_clock=0.0
		return
	ghost_clock+=dt
	if ghost_clock>=0.045 and (last_ghost==Vector2.INF or actor.global_position.distance_to(last_ghost)>18.0):
		ghost_clock=0.0
		_spawn_ghost()

func _update_rope() -> void:
	var target: Variant=actor.get("grapple_target")
	rope.visible=target is Vector2 and target!=Vector2.INF and rope.texture!=null
	if rope.visible:
		rope.global_transform=Transform2D.IDENTITY
		var fallback: Vector2=actor.global_position+Vector2(actor.facing*12,-height*0.53)
		var hand: Vector2=actor.skill_controller.attacks.socket_world("anchor","tether",fallback,actor.facing)
		var ring: Vector2=actor.grapple_anchor_world_position() if actor.has_method("grapple_anchor_world_position") else target
		rope.points=PackedVector2Array([hand,ring])

func _spawn_ghost() -> void:
	var body: Sprite2D=actor.get_node_or_null("Visual/ActionBody")
	if body==null or not body.visible: body=actor.body
	if body.texture==null: return
	var ghost:=Sprite2D.new()
	ghost.top_level=true
	ghost.texture=body.texture
	ghost.centered=body.centered
	ghost.offset=body.offset
	ghost.flip_h=body.flip_h
	ghost.modulate=Color(0.45,0.9,0.83,0.30)
	add_child(ghost)
	ghost.global_transform=body.global_transform
	ghost.z_as_relative=false
	ghost.z_index=actor.z_index-1
	particles.append({"node":ghost,"time":0.0,"life":0.18,"key":"ghost"})
	last_ghost=actor.global_position
	_limit()

func _event(key: String,event: String,origin: Vector2,direction: float) -> void:
	if event=="land" and key in LAND_KEYS:
		_spawn_atlas(key,origin,direction,0.24)
	elif event=="release" and key in RELEASE_KEYS:
		_spawn_atlas(key,origin,direction,maxf(0.1,actor.state_duration-actor.state_time))
	elif key=="parry" and event=="success":
		var fallback: Vector2=origin+Vector2(direction*45,-height*0.65)
		var guard: Vector2=actor.skill_controller.attacks.socket_world("parry","guard",fallback,direction)
		_spawn_impact(guard,direction,false,"parry")
	elif event=="impact":
		# The impact uses a small, authored luminous bitmap; no geometric placeholder.
		_spawn_impact(origin,direction,key=="shadow_orb")
	elif event=="cancel":
		for i: int in range(particles.size()-1,-1,-1):
			if particles[i].key==key:
				particles[i].node.queue_free()
				particles.remove_at(i)

func _animation(tag: String) -> void:
	if tag in ["hit:start","defeat:start","interact:start"]: clear()
	elif tag=="heavy:release":
		_spawn_atlas("heavy",actor.global_position,actor.facing,maxf(0.1,actor.state_duration-actor.state_time))

func _spawn_atlas(key: String,origin: Vector2,direction: float,life: float) -> void:
	if not manifest.has(key) or manifest[key].get("fx")==null: return
	var spec: Dictionary=manifest[key]
	var fx: Dictionary=spec.fx
	if not frames.has(key):
		if not ResourceLoader.exists(str(fx.texture)): return
		var atlas: Texture2D=load(str(fx.texture))
		var sequence: Array[Texture2D]=[]
		var start: int=clampi(int(fx.get("event_frame",int(float(spec.get("event_phase",0.5))*fx.frames.size()))),0,fx.frames.size()-1)
		for i: int in range(start,fx.frames.size()):
			var region: Array=fx.frames[i]
			var frame:=AtlasTexture.new()
			frame.atlas=atlas
			frame.region=Rect2(region[0],region[1],region[2],region[3])
			frame.filter_clip=true
			sequence.append(frame)
		frames[key]=sequence
	var sprite:=Sprite2D.new()
	sprite.top_level=true
	sprite.centered=false
	sprite.offset=-Vector2(float(fx.pivot[0]),float(fx.pivot[1]))
	sprite.texture=frames[key][0]
	# World-space top-level items must keep the campaign actor's draw layer.
	# A raw -1 puts them behind the room art, rather than behind the body.
	sprite.z_as_relative=false
	sprite.z_index=actor.z_index-1 if key in ["heavy","dive","dark_dive","scan"] else actor.z_index
	if spec.get("fx_blend","")=="additive":
		var material:=CanvasItemMaterial.new()
		material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material=material
	add_child(sprite)
	sprite.global_position=origin
	sprite.scale=Vector2(direction,1.0)*height/float(spec.reference_height)*float(spec.get("fx_scale",1.0))
	var tint: Array=spec.get("fx_tint",[1.0,1.0,1.0,1.0])
	sprite.modulate=Color(float(tint[0]),float(tint[1]),float(tint[2]),float(tint[3]))
	particles.append({"node":sprite,"time":0.0,"life":life,"frames":frames[key],"key":key})
	_limit()

func _spawn_impact(origin: Vector2,direction: float,shadow: bool,effect_key: String="impact") -> void:
	var path: String=ROOT+("shadow_projectile.png" if shadow else "projectile.png")
	if not ResourceLoader.exists(path): return
	var sprite:=Sprite2D.new()
	sprite.texture=load(path)
	sprite.top_level=true
	add_child(sprite)
	sprite.global_position=origin
	sprite.scale=Vector2(direction,1.0)*18.0/maxf(sprite.texture.get_width(),sprite.texture.get_height())
	particles.append({"node":sprite,"time":0.0,"life":0.10,"key":effect_key})
	_limit()

func _limit() -> void:
	while particles.size()>20:
		var oldest: Dictionary=particles.pop_front()
		oldest.node.queue_free()

func clear() -> void:
	for item: Dictionary in particles: item.node.queue_free()
	particles.clear()
	if is_instance_valid(rope): rope.hide()
	last_ghost=Vector2.INF
	ghost_clock=0.0
