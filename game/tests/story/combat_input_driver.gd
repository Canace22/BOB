class_name CampaignStoryCombatInputDriver
extends RefCounted
## 只把可见敌人状态转为物理键事件；不调用攻击、伤害或结算接口。
var held: Dictionary={}
var inputs: Array[Dictionary]=[]
var last_red_serial: int=-1
var jump_until: int=0
var backstep_until: int=0
var heal_until: int=0

func key(code: Key, down: bool, frame: int) -> void:
	if bool(held.get(code,false))==down: return
	held[code]=down
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
	if inputs.size()<16000: inputs.append({"frame":frame,"key":OS.get_keycode_string(code),"pressed":down})

func release(frame: int=0) -> void:
	for code: Key in held.keys(): key(code,false,frame)

func apply(wanted: Array[int], frame: int) -> void:
	for code: Key in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_J,KEY_I,KEY_K,KEY_L,KEY_Q,KEY_E,KEY_Z,KEY_SPACE]: key(code,code in wanted,frame)

func drive(player: WhalebellyCampaignPlayer, enemy: EnemyLabEnemy, stage: Dictionary, frame: int, attempt: int) -> void:
	var wanted: Array[int]=[]
	var gap: float=enemy.position.x-player.position.x
	var direction: float=signf(gap)
	if is_zero_approx(direction): direction=player.facing
	var arena: Rect2=enemy.combat_space.arena
	var target: float=enemy.position.x
	var spacing: float=85.0
	if enemy is EnemyLabEel:
		target=enemy.position.x+enemy.facing*180.0
		spacing=12.0
	var target_gap: float=target-player.position.x
	var opening: bool=enemy.state in ["recover","hurt","reground"]
	var guard_phase: bool=enemy.state in ["tell","active","coil","emerge","reform","settle"]
	var red: bool=bool(enemy.spec.get("unblockable",false)) and enemy.state in ["tell","active"]
	var remaining: float=enemy.phase_duration()-enemy.timer
	var move: float=signf(target_gap) if absf(target_gap)>spacing else 0.0
	if str(stage.kind)=="escape":
		move=signf(float(stage.goal[0])-player.position.x)
		if enemy.state in ["tell","active"] and absf(gap)<210 and not red and remaining<0.20:
			wanted.append(KEY_I)
		if enemy.state=="active" and absf(gap)<160: jump_until=maxi(jump_until,frame+22)
	else:
		if red:
			move=-direction if absf(gap)<360 else 0.0
			var room_behind: float=player.position.x-arena.position.x if direction>0 else arena.end.x-player.position.x
			if room_behind<130 and absf(gap)<300:
				move=direction
				if remaining<0.30 and enemy.state=="tell": jump_until=maxi(jump_until,frame+24)
			if enemy.attack_serial!=last_red_serial and enemy.state=="tell" and remaining<0.24 and absf(gap)<230:
				last_red_serial=enemy.attack_serial
				backstep_until=frame+2
		elif enemy is EnemyLabBeamGuard and enemy.move_key=="beam_return" and guard_phase:
			if remaining<0.32 or enemy.state=="active": jump_until=maxi(jump_until,frame+15)
		elif guard_phase and (remaining<0.19 or enemy.state=="active" or enemy.state=="settle"):
			wanted.append(KEY_I)
			move=0.0
		if opening and absf(gap)<(195.0 if enemy is EnemyLabEel else 145.0):
			if frame%18<6:
				wanted.append(KEY_J)
				if float(player.cooldowns.get("wb_draw",0))<=0 and frame%180<48: wanted.append(KEY_S)
				elif attempt>0 and float(player.cooldowns.get("wb_flurry",0))<=0 and remaining>0.85: wanted.append(KEY_E)
		if player.facing!=direction and not player.skill_controller.active: move=direction
		if player.health<=2 and player.soul>=33 and absf(gap)>440 and enemy.state in ["idle","recover"]:
			heal_until=maxi(heal_until,frame+60)
		if frame<heal_until and absf(gap)>290:
			wanted=[KEY_E,KEY_I]
			move=0.0
	if frame<jump_until: wanted.append(KEY_SPACE)
	if frame<backstep_until: wanted.append(KEY_Z)
	if move<0 and player.position.x>arena.position.x+35: wanted.append(KEY_A)
	if move>0 and player.position.x<arena.end.x-35: wanted.append(KEY_D)
	apply(wanted,frame)
