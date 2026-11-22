class_name EnemyLabWindupView
extends Sprite2D
## 纯呈现子节点：无伤害、位移和计时；只播放已入库的前摇位图序列。

func _ready() -> void:
	top_level=true
	centered=false
	region_enabled=true
	region_filter_clip_enabled=true
	visible=false

func present(sampled: Dictionary, origin: Vector2, facing: float) -> void:
	visible=not sampled.is_empty()
	if not visible: return
	var clip: Dictionary=sampled.clip
	var frame: Dictionary=sampled.frame
	texture=clip.resource
	var rect: Array=frame.rect
	region_rect=Rect2(rect[0],rect[1],rect[2],rect[3])
	offset=-Vector2(float(frame.pivot[0]),float(frame.pivot[1]))
	var factor: float=float(clip.get("scale",1.0))
	scale=Vector2(-facing*factor,factor)
	global_position=origin+Vector2(-facing*float(clip.anchor[0]),float(clip.anchor[1]))
