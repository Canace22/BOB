class_name EnemyLabPumpCourt
extends Node2D
## 场景膜泵拥有压力节拍与水路；玩家运动仍由角色自身执行。
var lab: EnemyLab
var warden: EnemyLabWarden
var view: EnemyLabPumpVisual
var phase: String="fill"
var timer: float=0.0
var clock: float=0.0
var vent_left: float=0.0
var pull_delay: float=0.0
var pull_left: float=0.0
var stopped: bool=false
var manual: bool=false
var contact: bool=false
var cycles: int=0
var vents: int=0
var hits: int=0
var blocks: int=0
const VALVE: Vector2=Vector2(600,480)
const PULL_X: float=860.0
const JET: Rect2=Rect2(940,300,80,220)
const PHASE_TIME: Dictionary={"fill":2.4,"stroke":0.85,"release":1.5}

func _ready() -> void:
	view=EnemyLabPumpVisual.new()
	view.court=self
	add_child(view)

func request(mode: String) -> bool:
	if stopped or vent_left>0.0: return false
	manual=true
	phase="fill"
	contact=false
	if mode=="siphon":
		timer=0.0
		pull_delay=0.70
		pull_left=0.0
	else:
		timer=1.60
		pull_delay=0.0
		pull_left=0.0
	return true

func _physics_process(dt: float) -> void:
	if not is_instance_valid(lab.player): return
	lab.player.pump_drift=0.0
	if stopped:
		clock+=dt
		_advance(dt)
		view.present()
		return
	clock+=dt
	var p: EnemyLabPlayer=lab.player
	if p.health>0 and p.is_on_floor() and p.global_position.distance_to(VALVE)<90.0 and Input.is_action_just_pressed("tp_interact"):
		vent()
	if vent_left>0.0:
		vent_left=maxf(0.0,vent_left-dt)
	elif lab.auto_attack or manual:
		_advance(dt)
		_apply_flow()
	view.present()

func _advance(dt: float) -> void:
	timer+=dt
	if timer>=float(PHASE_TIME[phase]):
		timer=0.0
		match phase:
			"fill":
				phase="stroke"
				cycles+=1
				contact=false
			"stroke": phase="release"
			"release":
				phase="fill"
				manual=false
	if pull_delay>0.0:
		pull_delay=maxf(0.0,pull_delay-dt)
		if pull_delay<=0.0: pull_left=1.0
	elif pull_left>0.0: pull_left=maxf(0.0,pull_left-dt)

func _apply_flow() -> void:
	var p: EnemyLabPlayer=lab.player
	if p.health<=0: return
	var guard: EnemyLabSkills=p.skill_controller as EnemyLabSkills
	if pull_left>0.0 and p.global_position.y>=450.0 and p.position.x>650.0 and p.position.x<1030.0:
		p.pump_drift=signf(PULL_X-p.position.x)*(65.0 if guard.guard_open() else 220.0)
	if phase!="stroke": return
	var body := Rect2(p.global_position-Vector2(14,65),Vector2(28,65))
	if not JET.intersects(body): return
	if p.global_position.y>=450.0: p.pump_drift=-55.0 if guard.guard_open() else -240.0
	if contact or timer<0.10: return
	contact=true
	var before: int=guard.guard_count
	guard.incoming_pressure=42.0
	if p.take_damage(1,Vector2(1040,p.global_position.y-30)): hits+=1
	elif guard.guard_count>before: blocks+=1
	guard.incoming_pressure=28.0

func vent() -> bool:
	if stopped or vent_left>0.0: return false
	vents+=1
	vent_left=3.0
	phase="release"
	timer=0.0
	pull_delay=0.0
	pull_left=0.0
	contact=true
	manual=false
	lab.player.pump_drift=0.0
	if is_instance_valid(warden) and warden.outcome.is_empty(): warden.release_pressure()
	lab.record("泄压瓣已打开 · 压力卸除，趁失衡前进")
	view.present()
	return true

func stop() -> void:
	stopped=true
	pull_delay=0.0
	pull_left=0.0
	if is_instance_valid(lab.player): lab.player.pump_drift=0.0
	if is_instance_valid(view): view.present()

func snapshot() -> Dictionary:
	return {"phase":phase,"time":timer,"duration":PHASE_TIME[phase],"vent":vent_left,"pull_warning":pull_delay,"pull":pull_left,"cycles":cycles,"vents":vents,"hits":hits,"blocks":blocks,"stopped":stopped}
