class_name WhaleChapterForager
extends CampaignCorpseCrab
## 循环验证占位：复用尸蟹位图、碰撞、读招与命中反馈，受压后退回食物，不播放死亡。
var awake: bool = false
var withdrawing: bool = false
var pressure: int = 0
var feeding_x: float = 0.0
var lane: Vector2 = Vector2(720,950)
var contact_hits: int = 0
var attack_kind: String = "sweep"
var followup: bool = false
var cue: Label
var pressure_bar: ProgressBar
var phase_bar: ProgressBar
var rewarded_serial: int = -1
var counter_hits: int = 0
var opening_delay: float = 0.0
const RETREAT_PRESSURE: int = 6

const PATTERNS: Dictionary = {
	"sweep":{"tell":0.62,"active":0.20,"recover":0.85,"width":150.0,"height":34.0,"speed":0.0},
	"rush":{"tell":0.80,"active":0.38,"recover":1.10,"width":100.0,"height":76.0,"speed":390.0},
	"double":{"tell":0.48,"active":0.18,"recover":0.95,"width":120.0,"height":65.0,"speed":60.0}
}

func _ready() -> void:
	super._ready()
	feeding_x=home_x
	cue = WhaleUIStyle.label("",16,WhaleUIStyle.AMBER)
	cue.position=Vector2(-85,-126)
	add_child(cue)
	pressure_bar=_make_bar(-139.0,Color("e9c478"))
	pressure_bar.max_value=RETREAT_PRESSURE
	phase_bar=_make_bar(-103.0,Color("8bd9d1"))
	phase_bar.max_value=1.0

func create_visual() -> CorpseCrabVisual:
	return preload("res://src/narrative/chapter_one/forager_visual.gd").new()

func _make_bar(y: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position=Vector2(-70,y)
	bar.size=Vector2(140,5)
	bar.show_percentage=false
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color=color
	fill.set_content_margin_all(0.0)
	var background := StyleBoxFlat.new()
	background.bg_color=Color(0.04,0.08,0.10,0.8)
	background.set_content_margin_all(0.0)
	bar.add_theme_stylebox_override("fill",fill)
	bar.add_theme_stylebox_override("background",background)
	add_child(bar)
	# 默认主题曾先把size钳到28px；换主题后须重新设尺寸，清掉已生效的最小高度。
	bar.size=Vector2(140,4)
	return bar

func _physics_process(dt: float) -> void:
	if is_instance_valid(cue):
		cue.visible = awake and not withdrawing and state in ["tell","recover"]
		cue.text = "破绽 · 反击加压" if state=="recover" else ({"sweep":"低扫 · 跳跃 / 格挡","rush":"冲撞 · 后跳 / 越身","double":"二连钳 · 第二下" if followup else "二连钳 · 还有一下"}[attack_kind])
		pressure_bar.visible=awake and not withdrawing
		pressure_bar.value=pressure
		phase_bar.visible=cue.visible
		if cue.visible:
			var duration: float=0.30 if state=="tell" and followup else float(PATTERNS[attack_kind][state])
			phase_bar.value=clampf(timer/duration,0.0,1.0) if state=="tell" else 1.0-clampf(timer/duration,0.0,1.0)
	if not awake or withdrawing:
		if not is_instance_valid(target) or not target.controls_enabled: return
		if feedback.frozen(dt): return
		var previous: float=position.x
		velocity.x=move_toward(position.x,feeding_x,70.0*dt)-position.x
		velocity.x/=maxf(dt,0.001)
		velocity.y=minf(velocity.y+1000.0*dt,700.0)
		if not is_zero_approx(velocity.x): facing=signf(velocity.x)
		move_and_slide()
		moving=absf(position.x-previous)>0.01
		walk_distance+=absf(position.x-previous)
		idle_clock+=dt
		state="idle"
		_sync()
		visual.present(self)
		return
	super._physics_process(dt)

func _decide(dt: float) -> void:
	var gap: Vector2=target.global_position-global_position
	timer+=dt
	opening_delay=maxf(0.0,opening_delay-dt)
	facing=signf(gap.x) if not is_zero_approx(gap.x) else facing
	# 接近聚食点会主动迎上驱逐；两只共享通路，走进中间会受到两侧真实攻击。
	if opening_delay<=0.0 and absf(gap.y)<100.0 and absf(gap.x)<330.0:
		attack_serial+=1
		# 距离决定突进，近身轮换单扫/二连；起手后锁朝向，不追踪玩家转身。
		attack_kind="rush" if absf(gap.x)>175.0 else ("double" if attack_serial%2==0 else "sweep")
		followup=false
		change("tell")
		return
	if absf(gap.x)<480.0 and absf(gap.y)<140.0:
		var next_x: float=clampf(position.x+facing*185.0*dt,lane.x,lane.y)
		if floor_ahead(next_x): velocity.x=(next_x-position.x)/maxf(dt,0.001)

func advance_action(dt: float) -> void:
	var remaining: float=dt
	for guard: int in 10:
		if state not in ["tell","active","recover","hurt"] or remaining<=0.0: break
		var duration: float=0.22 if state=="hurt" else float(PATTERNS[attack_kind][state])
		if state=="tell" and followup: duration=0.30
		var step: float=minf(remaining,maxf(0.0,duration-timer))
		timer+=step
		remaining-=step
		if state=="active" and not hit_sent and timer>=HIT_TIME: _sweep()
		if timer+0.000001<duration: break
		match state:
			"tell":
				change("active")
				host.record_event("enemy_attack_active",{"id":data.key,"kind":attack_kind,"followup":followup,"instance":attack_serial})
			"active":
				if attack_kind=="double" and not followup:
					followup=true
					change("tell")
				else: change("recover")
			_: change("idle")
	# 只在有效段推进；地形/活动通路边界仍拥有最终运动约束。
	if state=="active":
		var speed: float=float(PATTERNS[attack_kind].speed)
		var next_x: float=position.x+facing*speed*dt
		if next_x>=lane.x and next_x<=lane.y and floor_ahead(next_x): velocity.x=facing*speed

func attack_rect() -> Rect2:
	var spec: Dictionary=PATTERNS[attack_kind]
	var width: float=spec.width
	var height: float=spec.height
	return Rect2(global_position+Vector2(8 if facing>0 else -width-8,-height),Vector2(width,height))

func take_hit(amount: int) -> void:
	if not can_receive_hit() or amount<=0: return
	pressure+=amount
	# 一次完整攻击只奖励一次破绽反击，后续多段不能重复领取同一破绽。
	if state=="recover" and rewarded_serial!=attack_serial:
		rewarded_serial=attack_serial
		pressure+=2
		counter_hits+=1
		host.record_event("chapter_forager_counter",{"id":data.key,"kind":attack_kind,"pressure":pressure})
	# 伤害仍通过主线结算和反馈入口，但压力达到阈值即撤退，不制造击杀奖励。
	host.damage_enemy(data,mini(amount,maxi(0,int(data.hp)-1)))
	if pressure>=RETREAT_PRESSURE: withdraw()

func can_receive_hit() -> bool:
	return awake and not withdrawing and data.alive

func withdraw() -> void:
	if withdrawing: return
	withdrawing=true
	change("idle")
	hit_sent=true
	launch_left=0.0
	hold_left=0.0
	collision_layer=0
	if is_in_group("tide_targets"): remove_from_group("tide_targets")
	host.record_event("chapter_forager_withdraw",{"id":data.key,"pressure":pressure})

func reset_feeding() -> void:
	awake=false
	withdrawing=false
	pressure=0
	rewarded_serial=-1
	counter_hits=0
	data.hp=data.max_hp
	feeding_x=home_x
	collision_layer=4
	if not is_in_group("tide_targets"): add_to_group("tide_targets")
	change("idle")

func _sweep() -> void:
	# 突进在整个有效段内检查首次接触，不能在刚起步且够不到人时就耗掉攻击。
	if attack_kind=="rush":
		var player_rect := Rect2(target.global_position-Vector2(14,65),Vector2(28,65))
		if not attack_rect().intersects(player_rect): return
	var hp: int=target.health
	var guarded: bool=target.skill_controller.parried
	super._sweep()
	if target.health<hp: contact_hits+=1
	if not guarded and target.skill_controller.parried:
		# 只认本次攻击实际触发的正面格挡，不把无敌或跳开误算成格挡。
		change("recover")
		host.record_event("chapter_forager_guard_break",{"id":data.key,"kind":attack_kind})
