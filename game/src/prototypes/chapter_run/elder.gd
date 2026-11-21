class_name ChapterRunElder
extends EnemyLabElder
## 保留完整复制与幻影；章节适配只补足实体头顶落脚时的脱身反应。
var head_release_left: float=0

func _physics_process(dt: float) -> void:
	head_release_left=maxf(0,head_release_left-dt)
	super._physics_process(dt)
	# 只短暂取消实体承托，伤害协议和原动作前摇不变，让头顶玩家能落回地面。
	if outcome.is_empty() and head_release_left>0: collision_layer=0

func _idle_tick(dt: float) -> void:
	var gap: Vector2=player.position-position
	# 碰撞分离会让脚线比身体高度多一点，不能因此永远不再起手。
	if auto_attack and timer>0.35 and absf(gap.x)<100 and gap.y< -100 and absf(gap.y)<=float(profile.height)+20:
		if begin_attack("elder_vault"):
			head_release_left=0.45
			collision_layer=0
			return
	super._idle_tick(dt)
