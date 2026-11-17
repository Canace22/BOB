class_name CampaignCameraWorldBounds
extends RefCounted
## 整个世界的横向/纵向可见轮廓，房间之间的空隙由实际连接通道接通。
var regions: Array[Rect2] = []
var passages: Array[PackedVector2Array] = []
const CORRIDOR_MARGIN := 180.0
const CONTOUR_BLEND := 240.0

func configure(layout: Dictionary) -> void:
	regions.clear()
	passages.clear()
	for rect: Rect2 in layout.get("room_bounds",{}).values(): regions.append(rect)
	for link: Dictionary in layout.get("links",[]):
		var path: PackedVector2Array=link.path
		passages.append(path)
		for i: int in range(1,path.size()):
			var rect:=Rect2(path[i-1],Vector2.ZERO).expand(path[i]).grow(CORRIDOR_MARGIN)
			regions.append(rect)

func target(actor: Vector2, half_view: Vector2, softness: float) -> Vector2:
	if regions.is_empty(): return actor
	# 连接是开放水域；它的窄包围盒不是镜头边界。接近实际路线时连续退回居中。
	var distance: float=INF
	for path: PackedVector2Array in passages:
		for i: int in range(1,path.size()):
			distance=minf(distance,actor.distance_to(Geometry2D.get_closest_point_to_segment(actor,path[i-1],path[i])))
	var edge_weight: float=smoothstep(CORRIDOR_MARGIN,CORRIDOR_MARGIN+240.0,distance)
	if edge_weight<=0.0: return actor
	var limited:=Vector2(_axis_target(actor,half_view,softness,0),_axis_target(actor,half_view,softness,1))
	return actor.lerp(limited,edge_weight)

func _axis_target(actor: Vector2, half_view: Vector2, softness: float, axis: int) -> float:
	var cross_axis: int=1-axis
	var limits: Vector2=_span(actor[axis],actor[cross_axis],axis)
	if limits==Vector2.INF: return actor[axis]
	# 轮廓台阶在横向移动时逐渐显露，不能在相邻房的高度交界突然改限位。
	for sign_value: float in [-1.0,1.0]:
		var other: Vector2=_span(actor[axis],actor[cross_axis]+sign_value*CONTOUR_BLEND,axis)
		if other==Vector2.INF: continue
		var distance: float=_distance_to_region(actor,axis,sign_value)
		var blend: float=1.0-smoothstep(0.0,CONTOUR_BLEND,distance)
		limits.x=lerpf(limits.x,minf(limits.x,other.x),blend)
		limits.y=lerpf(limits.y,maxf(limits.y,other.y),blend)
	if limits==Vector2.INF: return actor[axis]
	var minimum: float=limits.x+half_view[axis]
	var maximum: float=limits.y-half_view[axis]
	# 细连接台/竖井两侧本来就是开放水域，不能把窄通道误当封闭小房间。
	if minimum>=maximum: return actor[axis]
	var fit_weight: float=smoothstep(0.0,softness*2.0,maximum-minimum) if softness>0 else 1.0
	var width: float=minf(softness,(maximum-minimum)*0.5)
	var value: float=actor[axis]
	if width<=0.0: return clampf(value,minimum,maximum)
	if value<minimum+width:
		var t: float=clampf((value-minimum)/width,0.0,1.0)
		return lerpf(value,minimum+width*t*t*(2.0-t),fit_weight)
	if value>maximum-width:
		var t: float=clampf((maximum-value)/width,0.0,1.0)
		return lerpf(value,maximum-width*t*t*(2.0-t),fit_weight)
	return value

func _span(at: float, across: float, axis: int) -> Vector2:
	var intervals: Array[Vector2]=[]
	for rect: Rect2 in regions:
		if across>=rect.position[1-axis] and across<=rect.end[1-axis]:
			intervals.append(Vector2(rect.position[axis],rect.end[axis]))
	intervals.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x<b.x)
	var merged: Array[Vector2]=[]
	for interval: Vector2 in intervals:
		if not merged.is_empty() and interval.x<=merged[-1].y:
			merged[-1].y=maxf(merged[-1].y,interval.y)
		else: merged.append(interval)
	for interval: Vector2 in merged:
		if at>=interval.x and at<=interval.y: return interval
	# 跳跃或跌落暂离房间包围盒时，使用最近的世界连通截面。
	var closest:=Vector2.INF
	var distance: float=INF
	for interval: Vector2 in merged:
		var gap: float=absf(at-clampf(at,interval.x,interval.y))
		if gap<distance:
			distance=gap
			closest=interval
	return closest

func _distance_to_region(actor: Vector2, axis: int, direction: float) -> float:
	var closest: float=CONTOUR_BLEND
	for rect: Rect2 in regions:
		if actor[axis]<rect.position[axis] or actor[axis]>rect.end[axis]: continue
		var edge: float=rect.position[1-axis] if direction>0.0 else rect.end[1-axis]
		var distance: float=(edge-actor[1-axis])*direction
		if distance>=0.0: closest=minf(closest,distance)
	return closest
