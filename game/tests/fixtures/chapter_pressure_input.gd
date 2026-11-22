class_name ChapterPressureInputPolicy
extends RefCounted
## 只读敌人阶段/实物弹体并给出按键；不写角色位置、伤害、生命或敌人状态。
static func decide(enemy: EnemyLabEnemy, player: ChapterTwoPlayer, frame: int) -> Dictionary:
	var buttons: Dictionary={KEY_A:false,KEY_D:false,KEY_I:false,KEY_J:false,KEY_SPACE:false}
	var gap: Vector2=enemy.position-player.position
	var red: bool=enemy.state=="tell" and bool(enemy.spec.get("unblockable",false))
	if red:
		buttons[KEY_A]=gap.x>=0
		buttons[KEY_D]=gap.x<0
		return buttons
	# 换面时先松格挡再用真实方向输入转身，不能在持盾锁朝向期间硬接身后攻击。
	if gap.x*player.facing< -20:
		buttons[KEY_A]=gap.x<0
		buttons[KEY_D]=gap.x>0
		return buttons
	# 鳗的盘身/露头、水遁凝形也有独立准备段，不能只识别通用tell。
	var windup: bool=enemy.state in ["tell","coil","emerge","reform"]
	var guarding: bool=enemy.state=="active" or windup and enemy.phase_duration()-enemy.timer<0.24
	var container: Node=enemy.get_parent()
	for child: Node in container.get_children():
		if (child is EnemyLabWardenShot or child is EnemyLabWaterOrb or child is EnemyLabMimicOrb) and (child as Node2D).position.distance_to(player.position)<240:
			guarding=true
	buttons[KEY_I]=guarding
	if guarding: return buttons
	var opening: bool=enemy.state in ["recover","hurt"]
	buttons[KEY_J]=opening and absf(gap.x)<120 and absf(gap.y)<100 and frame%18<2
	if absf(gap.x)>100:
		buttons[KEY_A]=gap.x<0
		buttons[KEY_D]=gap.x>0
	return buttons
