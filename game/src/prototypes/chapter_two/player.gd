class_name ChapterTwoPlayer
extends EnemyLabPlayer
## 章节样板只用基础技法，不读取正式主线能力或发放新技能。
func skill_unlocked(rule: String) -> bool:
	return rule=="always"

func skill_practice_enabled() -> bool: return false

func ability_available(action: String) -> bool:
	if action in ["A1_dash","parry","strike_01","strike2","backstep"]: return true
	return super.ability_available(action)

func request_action(action: String) -> bool:
	if not ability_available(action): return false
	return super.request_action(action)
