class_name EnemyLabCombatSpace
extends RefCounted
## 场地坐标是敌人/玩家共用父空间的房内坐标；判定、射线和弹体显式转世界坐标。
var arena: Rect2=Rect2(0,0,1280,520)
var configured: bool=false
var floor_y: float=520.0
var perches: Array[Vector2]=[]
var shelter: Rect2=Rect2(0,450,215,500)
var exit_x: float=1130.0

func configure(value: Rect2, options: Dictionary={}) -> void:
	arena=value
	configured=true
	floor_y=float(options.get("floor_y",value.end.y))
	exit_x=float(options.get("exit_x",x(1130)))
	shelter=options.get("shelter",Rect2(Vector2(x(0),floor_y-70),Vector2(x(215)-x(0),500)))
	perches.clear()
	for point: Variant in options.get("perches",[]):
		perches.append(point if point is Vector2 else Vector2(point[0],point[1]))

func x(nominal: float) -> float:
	return arena.position.x+nominal/1280.0*arena.size.x

func clamp_x(value: float, lower: float, upper: float) -> float:
	return clampf(value,x(lower),x(upper))

func point(nominal: Vector2) -> Vector2:
	return Vector2(x(nominal.x),floor_y+nominal.y-520.0)

func perch(index: int) -> Vector2:
	if perches.size()>index: return perches[index]
	return point(Vector2(760 if index==0 else 1060,260))

func ground_at(enemy: Node2D, local_x: float) -> float:
	if not configured or not enemy.is_inside_tree(): return floor_y
	# 真实平台顶面是权威；射线从脚线略上方起，避免选中遥远的高层台面。
	var parent: Node2D=enemy.get_parent() as Node2D
	var start: Vector2=parent.to_global(Vector2(local_x,floor_y-100.0))
	var stop: Vector2=parent.to_global(Vector2(local_x,floor_y+180.0))
	var query:=PhysicsRayQueryParameters2D.create(start,stop,1)
	var hit: Dictionary=enemy.get_world_2d().direct_space_state.intersect_ray(query)
	return parent.to_local(hit.position).y if not hit.is_empty() else floor_y
