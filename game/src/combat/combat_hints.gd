class_name TideCombatHints
extends RefCounted
## HUD与输入共用同一页表；只读状态，不试放技能，也不改冷却。
const KEYS: Array[String] = ["J","K","I","L"]
const NAMES: Dictionary = {"wb_rise":"挑潮上挑","wb_drive":"三段斩","wb_draw":"横扫","wb_charge":"撞击挑空","wb_flurry":"五段连斩","scan":"骨音探潮","A5_slit":"潜隙","heavy":"重鸣","crystal_dash":"蓄力长冲","cyclone":"回旋斩","recover":"调息","A4_parry":"潮弹","up_spell":"上涌","dive":"下潜","shadow_orb":"深鸣潮弹","abyss_scream":"共鸣啸","dark_dive":"深钟"}

static func rows(p: TideCombatPlayer) -> Array[Dictionary]:
	var page: int = p.pad_input.effective_page()
	var actions: Array[String] = TideCombatInput.BOTH if page == 3 else (TideCombatInput.LT if page == 1 else TideCombatInput.RT)
	var result: Array[Dictionary] = []
	if page == 0: return result
	for i: int in 4:
		var action: String = p.pad_input.resolve_action(actions[i])
		var hold: bool = action in ["recover","crystal_dash"]
		result.append({"key":KEYS[i],"action":action,"title":NAMES.get(action,action),"hold":hold,"status":status(p,action)})
	return result

static func status(p: TideCombatPlayer, action: String) -> String:
	if not p.ability_available(action): return "未解锁"
	var spec: Dictionary = TideSkillCatalog.definition(action)
	var key: String = str(spec.get("cooldown_group",{"A4_parry":"orb","recover":"heal","A5_slit":"slit","heavy":"heavy"}.get(action,action)))
	var cd: float = maxf(float(p.cooldowns.get(action,0.0)),float(p.cooldowns.get(key,0.0)))
	var c := p.skill_controller as TideCombatSkills
	if action == "wb_drive" and c.drive_window > 0.0 and c.drive_step < 3: cd = 0.0
	if cd > 0.0: return "冷却 %.1f秒" % cd
	var cost: int = int(spec.get("cost",p.skill_cost if action in ["A4_parry","heavy","recover"] else 0))
	if p.soul < cost: return "蓄振不足"
	if action == "recover" and p.health >= p.max_health: return "生命已满"
	if (action in ["recover","crystal_dash"] and not p.is_on_floor()) or (bool(spec.get("air_only",false)) and p.is_on_floor()): return "需落地" if action != "dive" else "需在空中"
	if action == "wb_backcut" and not p.retreating: return "需后跳"
	if p.retreating and action != "wb_backcut": return "后跳中"
	if p.state in ["hit","defeat","recover","interact"]: return "动作中"
	if p._offense_active() and not p._offense_released(): return "等待后摇"
	return "可用"
