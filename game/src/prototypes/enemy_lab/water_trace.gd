class_name EnemyLabWaterTrace
extends RefCounted
## 连续线段/矩形检测由各敌方水弹共用，避免低帧穿透。
static func crosses(start: Vector2, end: Vector2, rect: Rect2) -> bool:
	# 线段与扩展受击框相交，低帧率不能越过玩家或击中斜线外目标。
	var low: float=0.0
	var high: float=1.0
	var delta: Vector2=end-start
	for axis: int in 2:
		if is_zero_approx(delta[axis]):
			if start[axis]<rect.position[axis] or start[axis]>rect.end[axis]: return false
		else:
			var a: float=(rect.position[axis]-start[axis])/delta[axis]
			var b: float=(rect.end[axis]-start[axis])/delta[axis]
			low=maxf(low,minf(a,b))
			high=minf(high,maxf(a,b))
			if low>high: return false
	return true

