class_name ChapterCharacterBindings
extends RefCounted
## 仅呈现位置表；坐标与既有F点同域，不写章节数据或存档。

static func actors(chapter: int) -> Array:
	match chapter:
		4: return [entry("keeper","fat_store_keeper",120,[530,520]),entry("guard","shell_guard",100,[1730,520]),entry("resident","resident_settled",90,[1980,520]),entry("carrier","resident_carrier",64,[2450,520])]
		5: return [entry("mender","nest_mender",104,[500,520]),entry("keeper","ring_keeper",74,[3160,520]),entry("stayer","resident_settled",88,[3090,520]),entry("migrant","resident_migrant",102,[3460,520]),entry("carrier","resident_carrier",65,[2780,520])]
		6: return [entry("keeper","lung_keeper",120,[520,520])]
		7: return [entry("elder","elder_guardian",135,[1580,520]),entry("warden","pump_warden",108,[2140,520])]
		8: return [entry("mender","nest_mender",104,[520,520]),entry("beam","beam_guard",102,[650,520]),entry("guard","shell_guard",100,[2370,520]),entry("resident","resident_settled",88,[360,520]),entry("migrant","resident_migrant",102,[430,520])]
		9: return [entry("carrier","resident_carrier",65,[970,520]),entry("migrant","resident_migrant",102,[2590,520]),entry("mender","nest_mender",104,[2310,520]),entry("guard","shell_guard",100,[3380,520])]
		12: return [entry("elder","elder_guardian",135,[690,520]),entry("guard","shell_guard",100,[1250,520]),entry("mender","nest_mender",104,[3980,520]),entry("resident","resident_settled",88,[1090,520]),entry("carrier","resident_carrier",65,[1180,520])]
	return []

static func entry(key: String, id: String, height: float, at: Array) -> Dictionary:
	return {"key":key,"id":id,"height":height,"at":Vector2(float(at[0]),float(at[1]))}

static func position_for(chapter: int, key: String, stage: String, fallback: Vector2, flags: Dictionary) -> Vector2:
	var positions: Dictionary={}
	match chapter:
		4:
			# 各轮廓按实机宽度留间距，避免宽壳搬运者和住户完全盖住守卫。
			if key=="keeper": positions={"ch04_03_agreement":1630,"ch04_04_limited_flow":2230,"ch04_05_tides":2780,"ch04_06_keep_limit":3220,"ch04_07_exit":3220}
			elif key=="guard": positions={"ch04_04_limited_flow":2100,"ch04_05_tides":2550,"ch04_06_keep_limit":3130,"ch04_07_exit":3130}
		5:
			if key=="mender": positions={"ch05_02_prepare_refuge":920,"ch05_03_eel":1260,"ch05_04_after_battle":2790,"ch05_05_carry_base":2870,"ch05_06_exit":3450}
		6:
			positions={"ch06_02_outside":810,"ch06_03_place_samples":2290,"ch06_04_tides":2820,"ch06_05_mark_limits":2860,"ch06_06_echo":3820,"ch06_07_exit":3820}
		7:
			if key=="elder": positions={"ch07_evidence":1080}
		8:
			if key=="beam": positions={"ch08_check_support":1010,"ch08_refusal":1590,"ch08_beam_fight":2140}
			elif key=="mender": positions={"ch08_check_support":840,"ch08_refusal":1450,"ch08_beam_fight":1120,"ch08_no_reply":2030,"ch08_receive_nests":3280,"ch08_exit":3370}
			elif key=="guard" and bool(flags.get("ch08_rope_restored",false)): return Vector2(2910,520)
			elif key in ["resident","migrant"] and bool(flags.get("ch08_nests_received",false)): return Vector2(3180 if key=="resident" else 3260,520)
		9:
			if key=="carrier" and bool(flags.get("ch09_stable_bed",false)): return Vector2(2180,520)
			if key=="migrant" and bool(flags.get("ch09_move_inside",false)): return Vector2(2990,520)
		12:
			if key=="elder": positions={"ch12_dispute_patch":1210,"ch12_elder_duel":2100}
			elif key=="guard": positions={"ch12_rescue_and_brace":2830,"ch12_limited_outflow":3010,"ch12_recovery_life":3820,"ch12_exit":3910}
	return Vector2(float(positions[stage]),fallback.y) if positions.has(stage) else fallback
