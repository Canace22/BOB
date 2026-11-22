class_name EnemyLabAnimationOverride
extends RefCounted
## 可选位图覆盖只采样战斗状态进度；资源不完整时整段回退，不另建动作时钟。

const CONFIG: String="res://art/combat-animation-v2/enemies/animations.json"
var enemies: Dictionary={}
var diagnostics: Array[String]=[]
var loaded: bool=false
var sources: Dictionary={}

func ensure_loaded() -> void:
	if loaded: return
	loaded=true
	if not FileAccess.file_exists(CONFIG): return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary or not parsed.get("enemies") is Dictionary:
		_reject("animations.json 缺少 enemies 字典")
		return
	sources=parsed.enemies

func warmup(id: String) -> void:
	ensure_loaded()
	if enemies.has(id): return
	# 只在该敌人入场时解码其所属图集，不能首次出招加载全部Boss素材。
	var source: Variant=sources.get(id,{})
	var entry: Dictionary={"clips":[],"windups":[]}
	enemies[id]=entry
	if not source is Dictionary: return
	for kind: String in ["clips","windups"]:
		var items: Variant=source.get(kind,[])
		if not items is Array: continue
		for candidate: Variant in items:
			var clip: Dictionary=_validate(candidate,id,kind)
			if not clip.is_empty(): entry[kind].append(clip)

func sample(id: String, action: String, state: String, pulse: int, progress: float, kind: String="clips", phase_duration: float=0.0) -> Dictionary:
	warmup(id)
	# 复制释放仍归专用呈现；随后独立的回稳状态可以读取新身体，不能被旧招式ID挡住。
	if action=="elder_mimic" and state not in ["tell","reground"]: return {}
	var entry: Dictionary=enemies.get(id,{})
	var fallback: Dictionary={}
	for clip: Dictionary in entry.get(kind,[]):
		if clip.action!=action or clip.state!=state: continue
		if clip.has("pulse"):
			if int(clip.pulse)==pulse: return _frame(clip,progress,phase_duration)
		else: fallback=clip
	return _frame(fallback,progress,phase_duration) if not fallback.is_empty() else {}

func apply_body(sprite: Sprite2D, sampled: Dictionary, facing: float, target_height: float) -> void:
	var clip: Dictionary=sampled.clip
	var frame: Dictionary=sampled.frame
	sprite.hframes=1
	sprite.vframes=1
	sprite.centered=false
	sprite.region_enabled=true
	sprite.texture=clip.resource
	var rect: Array=frame.rect
	sprite.region_rect=Rect2(rect[0],rect[1],rect[2],rect[3])
	sprite.offset=-Vector2(float(frame.pivot[0]),float(frame.pivot[1]))
	var factor: float=target_height/float(clip.reference_height)
	sprite.scale=Vector2(-facing*factor,factor)
	if frame.has("weak_center") and sprite.material is ShaderMaterial:
		var mat: ShaderMaterial=sprite.material as ShaderMaterial
		mat.set_shader_parameter("weak_center",(sprite.region_rect.position+Vector2(frame.weak_center[0],frame.weak_center[1]))/sprite.texture.get_size())
		mat.set_shader_parameter("weak_radius",Vector2(frame.weak_radius[0],frame.weak_radius[1])/sprite.texture.get_size())

func _frame(clip: Dictionary, progress: float, phase_duration: float=0.0) -> Dictionary:
	# 快速挥击按阶段实际秒数采样，压力加速不会把画面接触点提前到伤害之前。
	var cursor: float=clampf(progress,0.0,1.0)
	if str(clip.get("time_unit","phase"))=="seconds":
		cursor*=phase_duration if phase_duration>0.0 else float(clip.reference_duration)
	var selected: Dictionary=clip.frames[0]
	for frame: Dictionary in clip.frames:
		if float(frame.at)>cursor+0.0000001: break
		selected=frame
	return {"clip":clip,"frame":selected}

func _validate(candidate: Variant, id: String, kind: String) -> Dictionary:
	if not candidate is Dictionary: return {}
	var clip: Dictionary=candidate.duplicate(true)
	var label: String="%s/%s/%s"%[id,clip.get("action","?"),clip.get("state","?")]
	var path: String=str(clip.get("texture",""))
	if not clip.get("action") is String or not clip.get("state") is String or not _number(clip.get("reference_height")) or float(clip.reference_height)<=0.0:
		return _invalid(label,"缺少动作、阶段或正数 reference_height")
	if not path.begins_with("res://art/") or not ResourceLoader.exists(path):
		return _invalid(label,"贴图不存在: "+path)
	var bitmap: Texture2D=load(path) as Texture2D
	if bitmap==null: return _invalid(label,"资源不是 Texture2D")
	if not clip.get("frames") is Array or clip.frames.is_empty(): return _invalid(label,"没有帧")
	var unit: String=str(clip.get("time_unit","phase"))
	if unit not in ["phase","seconds"]: return _invalid(label,"未知时间单位")
	if unit=="seconds" and (not _number(clip.get("reference_duration")) or float(clip.reference_duration)<=0.0):
		return _invalid(label,"秒数采样缺少有效参考时长")
	var previous: float=-1.0
	for item: Variant in clip.frames:
		if not item is Dictionary: return _invalid(label,"帧不是字典")
		var frame: Dictionary=item
		if not _number(frame.get("at")): return _invalid(label,"缺少 at")
		var at: float=float(frame.at)
		var maximum: float=float(clip.reference_duration) if unit=="seconds" else 1.0
		if at<0.0 or at>maximum or at<=previous or (previous<0.0 and at!=0.0): return _invalid(label,"at 必须从0开始严格递增且不超出阶段")
		previous=at
		if not _vector(frame.get("rect"),4) or not _vector(frame.get("pivot"),2): return _invalid(label,"rect/pivot 格式错误")
		var r: Array=frame.rect
		if float(r[0])<0 or float(r[1])<0 or float(r[2])<=0 or float(r[3])<=0 or float(r[0])+float(r[2])>bitmap.get_width() or float(r[1])+float(r[3])>bitmap.get_height(): return _invalid(label,"裁片超出贴图")
		# 水系Boss随帧更换贴图时，黄色背部弱点必须拥有对应的新局部锚点。
		if id=="pump_warden" and kind=="clips":
			if not _vector(frame.get("weak_center"),2) or not _vector(frame.get("weak_radius"),2): return _invalid(label,"泵庭身体帧缺少弱点锚点")
			if float(frame.weak_radius[0])<=0 or float(frame.weak_radius[1])<=0: return _invalid(label,"弱点半径必须为正")
	if kind=="windups":
		if not _vector(clip.get("anchor"),2) or not _number(clip.get("scale",1.0)) or float(clip.get("scale",1.0))<=0: return _invalid(label,"前摇FX anchor/scale 错误")
	clip.resource=bitmap
	return clip

func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func _vector(value: Variant, size: int) -> bool:
	if not value is Array or value.size()!=size: return false
	for item: Variant in value:
		if not _number(item): return false
	return true

func _invalid(label: String, reason: String) -> Dictionary:
	_reject(label+": "+reason)
	return {}

func _reject(reason: String) -> void:
	diagnostics.append(reason)
	push_warning("EnemyLabAnimationOverride: "+reason)
