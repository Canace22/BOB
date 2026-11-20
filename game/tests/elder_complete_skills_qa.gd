extends "res://tests/enemy_lab_elder_mimic_qa.gd"
## 新辅助/强化能力的真实输入验证；明确生命夹具只用于治疗，不作为通关。
func wait_replay(e: EnemyLabElder) -> void:
	for frame: int in 100:
		await tick(1)
		if e.state=="active" and e.timer>=0.06: break

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	check("advanced skill practice starts explicit off",not lab.player.skill_unlocked("chapter"))
	await tap(KEY_F7)
	check("actual F7 unlocks all skills locally",lab.all_skill_practice and lab.player.skill_unlocked("chapter"))
	var e: EnemyLabElder=await setup_elder(95)
	await release_source(e,[KEY_I])
	check("actual I teaches guard despite no damage",e.mimic.repertoire.learned.has("parry"))
	e.begin_attack("elder_mimic")
	await wait_replay(e)
	await pad([KEY_J])
	await tick(10)
	check("copied guard actually blocks real front J",e.health==24 and e.mimic.repertoire.shields==1)
	await shot("elder-full-copy-guard")
	e=await setup_elder(180)
	await release_source(e,[KEY_L])
	check("actual L teaches nonattacking dash",e.mimic.repertoire.learned.has("A1_dash"))
	e.begin_attack("elder_mimic")
	var start: float=e.position.x
	await wait_replay(e)
	check("copied dash moves and has finite evade state",absf(e.position.x-start)>15.0 and not e.can_receive_hit())
	await shot("elder-full-copy-dash")
	await tick(35)
	check("dash evade ends rather than staying invincible",e.can_receive_hit())
	e=await setup_elder(180)
	await pad([KEY_Z])
	await tick(25)
	check("actual Z teaches backstep",e.mimic.repertoire.learned.has("backstep"))
	e.begin_attack("elder_mimic")
	start=e.position.x
	await wait_replay(e)
	await tick(9)
	check("copied backstep retreats and jumps physically",e.position.x>start+30 and e.position.y<510)
	await shot("elder-full-copy-backstep")
	e=await setup_elder(330)
	lab.player.health=4
	key(KEY_E,true)
	key(KEY_I,true)
	for frame: int in 160:
		await tick(1)
		if e.mimic.repertoire.learned.has("recover"): break
	key(KEY_E,false)
	key(KEY_I,false)
	check("actual held E+I completion teaches healing",e.mimic.repertoire.learned.has("recover") and lab.player.health==5)
	e.health=20
	e.begin_attack("elder_mimic")
	await tick(90)
	check("copied healing actually restores bounded health",e.health==22 and e.mimic.repertoire.healing==2)
	await shot("elder-full-copy-heal")
	e=await setup_elder(180)
	await release_source(e,[KEY_Q,KEY_E,KEY_J])
	check("actual Q+E+J teaches scan",e.mimic.repertoire.learned.has("scan"))
	e.begin_attack("elder_mimic")
	await tick(75)
	check("copied scan grants real pursuit boost without fake damage",e.boosted_chase>0.0 and e.mimic.repertoire.scans==1 and lab.player.health==5)
	await shot("elder-full-copy-scan")
	e=await setup_elder(330)
	await release_source(e,[KEY_E,KEY_L])
	check("F7 upgraded E+L really teaches shadow orb",e.mimic.repertoire.learned.has("shadow_orb"))
	await tick(75)
	e.begin_attack("elder_mimic")
	for frame: int in 110:
		await tick(1)
		if not e.mimic.orb_refs.is_empty(): break
	print("UPGRADED_ORB key=",e.mimic.source_key," interrupted=",e.mimic.interrupted," casts=",e.mimic.casts," received=",e.reactions.received," health=",e.health," state=",e.state)
	check("upgraded projectile replays as real owned shot",not e.mimic.orb_refs.is_empty() and e.mimic.source_key=="shadow_orb")
	await shot("elder-full-copy-upgraded-orb")
	e=await setup_elder(200)
	await release_source(e,[KEY_W,KEY_E,KEY_L])
	check("real upward combination teaches upgraded scream",e.mimic.repertoire.learned.has("abyss_scream"))
	e.begin_attack("elder_mimic")
	await tick(100)
	check("upgraded upward spell keeps all three pulses",e.mimic.times.size()==3 and e.mimic.emitted==3)
	await shot("elder-full-copy-upgraded-scream")
	e=await setup_elder(95)
	await release_source(e,[KEY_J])
	check("real basic attack is also learned",e.mimic.repertoire.learned.has("strike_01") or e.mimic.repertoire.learned.has("strike2"))
	await tap(KEY_F7)
	await tap(KEY_R)
	await tick(14)
	check("turning practice off and R restores locks and clears bank",not lab.player.skill_unlocked("chapter") and (lab.enemies[0] as EnemyLabElder).mimic.repertoire.learned.is_empty())
	print("ELDER_COMPLETE_SKILLS failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
