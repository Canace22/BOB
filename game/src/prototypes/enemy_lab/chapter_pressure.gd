class_name ChapterCombatPressure
extends RefCounted
## 仅章节入口显式启用；试验场原参数、正式主线和玩家伤害均保持原值。
const PROFILES: Dictionary={
	"shell_guard":{"hp":30,"speed":155.0,"idle":0.20,"links":2},
	"mudback":{"hp":28,"speed":160.0,"idle":0.24,"links":2},
	"membrane_hunter":{"hp":24,"speed":165.0,"idle":0.42,"links":0},
	"nest_eel":{"hp":44,"speed":135.0,"idle":0.20,"links":1},
	"pump_warden":{"hp":42,"speed":190.0,"idle":0.22,"links":2},
	"beam_guard":{"hp":48,"speed":185.0,"idle":0.22,"links":2},
	"elder_guardian":{"hp":64,"speed":230.0,"idle":0.13,"links":1}
}
const LINKS: Dictionary={
	"poke":"shell_push", "shell_push":"realign",
	"ambush":"press", "press":"flip",
	"eel_burrow":"eel_bite", "eel_bite":"eel_tail",
	"warden_barrage":"warden_thrust", "warden_vortex":"warden_thrust",
	"warden_waterstep":"warden_push", "warden_thrust":"warden_double", "warden_push":"warden_double",
	"beam_press":"beam_return", "beam_return":"beam_brace",
	"elder_sweep":"elder_thrust", "elder_thrust":"elder_grip"
}
var enemy: EnemyLabEnemy
var settings: Dictionary={}
var queued: String=""
var links: int=0
var chains: int=0
var cancelled: int=0
var starts: int=0
var age: float=0.0
var recovery_left: float=0.0
var terminal_recovery: float=0.0
var events: Array[Dictionary]=[]

static func apply(profile: Dictionary) -> Dictionary:
	var result: Dictionary=profile.duplicate(true)
	var options: Dictionary=PROFILES.get(str(result.id),{})
	if options.is_empty(): return result
	result.hp=int(options.hp)
	result.speed=float(options.speed)
	result.chapter_pressure=options.duplicate(true)
	return result

func enabled() -> bool: return not settings.is_empty()
func idle(default_value: float) -> float: return float(settings.get("idle",default_value))
func seconds(original: float, challenge: float) -> float: return challenge if enabled() else original

func action(key: String) -> Dictionary:
	var result: Dictionary=EnemyLabCatalog.action(key)
	# 复制招式的身体、释放和伤害沿用完整执行器，不二次压缩复制时间轴。
	if not enabled() or key=="elder_mimic": return result
	result.tell=minf(float(result.tell),maxf(0.68 if bool(result.get("unblockable",false)) else 0.48,float(result.tell)*0.80))
	result.lock=minf(float(result.get("lock",0.0)),float(result.tell)*0.70)
	result.recover=maxf(0.70,float(result.recover)*0.90)
	if result.has("second"): result.second=maxf(0.30,float(result.second)*0.72)
	return result

func started(key: String) -> void:
	if not enabled(): return
	if queued!=key: links=0
	queued=""
	starts+=1
	_record("attack",key)

func entering(previous: String, next: String) -> void:
	if not enabled(): return
	if next=="hurt" and previous not in ["recover","hurt"]:
		cancel("attack_interrupted")
		recovery_left=maxf(0.35,float(enemy.spec.get("recover",0.90)))
	if next=="hurt" and not queued.is_empty():
		# 连段短收招能被真正打断；打断后恢复完整破绽，而不是抖一下继续追打。
		cancel("link_interrupted")
		enemy.spec.recover=maxf(0.90,terminal_recovery)
		recovery_left=float(enemy.spec.recover)
		if enemy is EnemyLabEel or enemy is EnemyLabWarden or enemy is EnemyLabBeamGuard or enemy is EnemyLabElder:
			enemy.set("opening_left",recovery_left)
	if next=="recover" and previous!="hurt":
		terminal_recovery=float(enemy.spec.get("recover",0.90))
		var candidate: String=str(LINKS.get(enemy.move_key,""))
		var close: bool=enemy.player.health>0 and absf(enemy.player.position.x-enemy.position.x)<460.0
		if previous=="active" and enemy.auto_attack and enemy.forced_move.is_empty() and enemy.outcome.is_empty() and not enemy.followup_cancelled and close and not candidate.is_empty() and links<int(settings.links):
			queued=candidate
			links+=1
			chains+=1
			enemy.spec.recover=0.22
			_record("link",candidate)
		else:
			queued=""
			links=0
			if previous=="active": enemy.spec.recover=maxf(0.70,terminal_recovery)
		recovery_left=float(enemy.spec.get("recover",0.90))
	if next=="ended": cancel("ended")

func cancel(reason: String) -> void:
	if not enabled(): return
	if not queued.is_empty() or links>0:
		cancelled+=1
		_record("cancel",reason)
	queued=""
	links=0
	# 本次动作被防守/弱点打断后不能在同一次recover里重新接出连段。
	if enemy!=null: enemy.followup_cancelled=true

func tick(dt: float) -> void:
	if not enabled(): return
	age+=dt
	if enemy.state in ["recover","hurt"]: recovery_left=maxf(0.0,recovery_left-dt)

func reset() -> void:
	queued=""
	links=0
	recovery_left=0.0
	terminal_recovery=0.0

func _record(kind: String, detail: String) -> void:
	# 有界采样供站桩/防守驱动复核，不在高频路径打印日志。
	if events.size()>=96: events.pop_front()
	events.append({"seconds":snappedf(age,0.001),"kind":kind,"detail":detail,"hp":enemy.health})

func snapshot() -> Dictionary:
	return {"enabled":enabled(),"attacks":starts,"links":chains,"cancelled":cancelled,"queued":queued,"seconds":snappedf(age,0.001),"events":events.duplicate(true)}
