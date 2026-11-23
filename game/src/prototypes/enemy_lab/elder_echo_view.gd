class_name EnemyLabElderEchoView
extends Node2D
## 主角幻影播放源动作；与复制伤害共用根位置，不增加第二个战斗执行器。
var mimic: EnemyLabElderMimic
var memory_pose: Sprite2D
var effect: Sprite2D
var action_echo: Sprite2D
var body_key: String=""
var body_frame: int=0
var cache: Dictionary={}
var guard_ring: Sprite2D
var additive: CanvasItemMaterial

func _ready() -> void:
	memory_pose=Sprite2D.new()
	memory_pose.centered=false
	memory_pose.modulate=Color(0.65,0.90,1.0,0.7)
	add_child(memory_pose)
	action_echo=Sprite2D.new()
	action_echo.centered=false
	var ghost_material := ShaderMaterial.new()
	ghost_material.shader=preload("echo_body.gdshader")
	action_echo.material=ghost_material
	add_child(action_echo)
	effect=Sprite2D.new()
	effect.centered=false
	additive=CanvasItemMaterial.new()
	additive.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	add_child(effect)
	guard_ring=Sprite2D.new()
	guard_ring.texture=mimic.enemy.player.action_visual.guard_ring.texture
	guard_ring.rotation=PI*0.5
	guard_ring.scale=Vector2.ONE*0.40
	guard_ring.modulate=Color(0.65,0.95,1.0)
	add_child(guard_ring)
	z_index=8
	clear()

func prepare(key: String) -> void:
	var keys: Array[String]=[clip_key(key,0.0)]
	if key=="wb_flurry": keys.assign(TideCombatVisual.FLURRY_KEYS)
	if key=="wb_drive": keys.assign(["strike1","strike2","dash_slash"])
	if key=="wb_charge": keys.assign(["dash","upper"])
	for clip: String in keys:
		if cache.has(clip): continue
		cache[clip]=mimic.enemy.player.action_visual.load_clip(clip)

func clip_key(key: String, elapsed: float) -> String:
	if key=="wb_drive":
		var step: int=int(elapsed/maxf(0.01,float(mimic.copied.get("duration",0.24))))
		return ["strike1","strike2","dash_slash"][clampi(step,0,maxi(0,mimic.times.size()-1))]
	if key=="wb_flurry": return str(TideCombatVisual.FLURRY_KEYS[TideCombatVisual.flurry_segment(elapsed)])
	var mapped: String=str(TideCombatVisual.SKILL_CLIPS.get(key,key))
	if key=="wb_charge": mapped="dash" if elapsed<float(mimic.copied.get("release",0.18))*0.6 else "upper"
	var legacy: Dictionary={"strike_01":"strike1","A1_dash":"dash","A5_slit":"slit","A3_anchor":"pogo","backstep":"jump","recover":"heal"}
	mapped=str(legacy.get(key,mapped))
	if mimic.enemy.player.action_visual.manifest.has(mapped): return mapped
	return "strike1"

func _physics_process(_dt: float) -> void:
	var enemy: EnemyLabElder=mimic.enemy
	clear()
	if enemy.move_key!="elder_mimic" or not enemy.outcome.is_empty() or mimic.copied.is_empty(): return
	if enemy.state not in ["tell","active"]: return
	var clip: String=clip_key(mimic.source_key,enemy.timer if enemy.state=="active" else 0.0)
	if not cache.has(clip): prepare(mimic.source_key)
	var spec: Dictionary=enemy.player.action_visual.manifest[clip]
	var frames: Dictionary=cache[clip]
	var count: int=int(spec.frame_count)
	var fraction: float=float(spec.get("event_phase",0.5))
	if enemy.state=="tell":
		memory_pose.visible=true
		memory_pose.position=Vector2(-enemy.facing*95.0,-155.0)
		_layer(memory_pose,frames.body,spec.body,int(fraction*count),47.0/float(spec.reference_height),enemy.facing)
		return
	_show_body(clip,frames,spec)
	if mimic.source_key=="parry":
		guard_ring.position=Vector2(enemy.facing*55.0,-65)
		guard_ring.visible=true
		return
	if frames.fx.is_empty() or spec.get("fx")==null: return
	if str(mimic.copied.get("motion",""))=="dive" and mimic.emitted==0: return
	var time: float=enemy.timer
	var duration: float=float(mimic.copied.get("duration",0.5))
	var release: float=float(mimic.copied.get("release",0.1))
	if mimic.source_key=="wb_drive": time=fmod(time,duration)
	if mimic.source_key=="wb_flurry":
		var segment: int=TideCombatVisual.flurry_segment(time)
		time-=TideCombatVisual.FLURRY_EDGES[segment]
		duration=TideCombatVisual.FLURRY_EDGES[segment+1]-TideCombatVisual.FLURRY_EDGES[segment]
		release=TideCombatVisual.FLURRY_HITS[segment]-TideCombatVisual.FLURRY_EDGES[segment]
	fraction=TideActionVisual.align_event(clampf(time/maxf(duration,0.01),0.0,1.0),release/maxf(duration,0.01),float(spec.get("event_phase",0.5)))
	if bool(spec.get("authored_pivot",false)) and time<release: return
	var index: int=int(fraction*int(spec.get("fx_frame_count",count)))
	# 稀疏源FX的接触亮帧短保持，避免加速后只闪一帧；不延后或重复判定。
	var impacts: Dictionary={"strike1":4,"upper":4,"great_slash":8,"heavy":4,"up_spell":3,"dive":4,"dark_dive":4}
	if mimic.last_release>=0.0 and enemy.timer-mimic.last_release<0.08:
		index=int(impacts.get(clip,index))
	# 新普攻的接触帧与弧光尺度和主角共用配置，避免复制时重新放大攻击观感。
	var slash: Dictionary=spec.get("slash_fx",{})
	if not slash.is_empty():
		index=int(slash.contact_frame)+int(maxf(0.0,time-release)*float(slash.fps))
	effect.visible=true
	effect.material=additive if str(spec.get("fx_blend",""))=="additive" else null
	_layer(effect,frames.fx,spec.fx,index,94.0/float(spec.reference_height),enemy.facing)
	effect.rotation=float(slash.get("rotation",0.0))*enemy.facing
	effect.scale*=float(slash.get("scale",1.0))
	effect.modulate=Color(0.95,0.87,0.62,0.85)

func _show_body(clip: String, frames: Dictionary, spec: Dictionary) -> void:
	var enemy: EnemyLabElder=mimic.enemy
	var time: float=enemy.timer
	var span: float=float(mimic.copied.get("duration",0.5))
	var release: float=float(mimic.copied.get("release",0.1))
	if mimic.source_key=="wb_drive": time=fmod(time,span)
	if mimic.source_key=="wb_flurry":
		var segment: int=TideCombatVisual.flurry_segment(time)
		time-=TideCombatVisual.FLURRY_EDGES[segment]
		span=TideCombatVisual.FLURRY_EDGES[segment+1]-TideCombatVisual.FLURRY_EDGES[segment]
		release=TideCombatVisual.FLURRY_HITS[segment]-TideCombatVisual.FLURRY_EDGES[segment]
	if mimic.source_key=="wb_charge":
		var split: float=release*0.6
		if clip=="dash": span=split; release=0.0
		else: time-=split; span-=split; release-=split
	var fraction: float=clampf(time/maxf(span,0.01),0.0,0.999)
	if spec.has("event_phase"):
		fraction=TideActionVisual.align_event(fraction,release/maxf(span,0.01),float(spec.event_phase))
	if mimic.source_key=="parry": fraction=2.0/float(spec.frame_count)
	if str(mimic.copied.get("motion",""))=="dive":
		fraction=minf(0.44,enemy.timer*0.8) if mimic.emitted==0 else lerpf(0.5,0.99,clampf((enemy.timer-mimic.last_release)/0.24,0.0,1.0))
	body_key=clip
	body_frame=clampi(int(fraction*int(spec.frame_count)),0,int(spec.frame_count)-1)
	if bool(spec.get("authored_pivot",false)):
		# 仅新本体共用phase解析；旧片段/无独立图的技能保持原来的映射与选帧。
		var landed: bool=str(mimic.copied.get("motion",""))=="dive" and mimic.emitted>0
		var context: Dictionary={"active":true,"visual_key":mimic.source_key,"clock":enemy.timer,
			"elapsed":time,"duration":span,"release":release,"landed":landed,
			"landed_at":mimic.last_release,"parry_end":float(mimic.copied.get("parry_end",0.42))}
		if landed: context.duration=mimic.last_release+0.24
		body_frame=enemy.player.action_visual.phase_map.index_from_context(clip,spec,fraction,context)
	action_echo.visible=true
	_layer(action_echo,frames.body,spec.body,body_frame,94.0/float(spec.reference_height),enemy.facing)
	if enemy.is_on_floor() and not bool(spec.get("authored_pivot",false)):
		var bottoms: Array=enemy.player.action_visual.foot_metadata.get(clip,{}).get("bottom",[])
		if not bottoms.is_empty(): action_echo.offset.y=-float(bottoms[mini(body_frame,bottoms.size()-1)])
	# 同一物理/攻击原点保证幻影动作与判定一致，施法者淡显以免挡住动作。
	enemy.visual.modulate.a=0.30

func _layer(sprite: Sprite2D, frames: Array, data: Dictionary, index: int, factor: float, facing: float) -> void:
	if frames.is_empty(): return
	sprite.texture=frames[clampi(index,0,frames.size()-1)]
	sprite.offset=-Vector2(float(data.pivot[0]),float(data.pivot[1]))
	sprite.scale=Vector2(facing*factor,factor)

func clear() -> void:
	if is_instance_valid(memory_pose): memory_pose.hide()
	if is_instance_valid(effect): effect.hide()
	if is_instance_valid(guard_ring): guard_ring.hide()
	if is_instance_valid(action_echo): action_echo.hide()
	if is_instance_valid(mimic) and is_instance_valid(mimic.enemy) and is_instance_valid(mimic.enemy.visual): mimic.enemy.visual.modulate.a=1.0
