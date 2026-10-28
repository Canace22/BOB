extends CharacterBody2D
class_name TidePlayer

signal stats_changed(health: int, soul: int)
signal cooldowns_changed(values: Dictionary)
signal availability_changed(double_jump: bool, dash: bool)
signal notification(text: String)
signal hit_confirmed
signal damaged
signal died
signal interaction_requested(target: Node)
signal animation_tag(tag: String)

@export_category("Movement")
@export var max_speed: float = 180.0
@export var acceleration: float = 2200.0
@export var friction: float = 1600.0
@export var gravity: float = 1200.0
@export var fall_multiplier: float = 1.35
@export var air_control: float = 0.7
@export var jump_height: float = 480.0
@export var short_jump_height: float = 320.0
@export var double_jump_speed: float = 350.0
@export var apex_hold: float = 0.08
@export var jump_buffer_time: float = 0.15
@export var coyote_time: float = 0.1
@export var wall_slide_speed: float = 60.0
@export var wall_jump_x: float = 180.0
@export var wall_jump_height: float = 300.0
@export_category("Skills")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6
@export var slit_speed: float = 900.0
@export var slit_duration: float = 0.3
@export var slit_cooldown: float = 2.0
@export var orb_speed: float = 400.0
@export var orb_lifetime: float = 1.5
@export var orb_cooldown: float = 1.0
@export var heavy_radius: float = 80.0
@export var heavy_cooldown: float = 2.0
@export var heal_time: float = 1.5
@export var heal_cooldown: float = 5.0
@export var heal_amount: int = 90
@export var skill_cost: int = 33
@export_category("Combat")
@export var max_health: int = 100
@export var max_soul: int = 99
@export var melee_damage: int = 10
@export var orb_damage: int = 20
@export var heavy_damage: int = 15
@export var soul_per_hit: int = 11
@export var contact_damage: int = 15
@export var hurt_soul_loss: int = 33
@export var hurt_invulnerability: float = 0.5
@export var hurt_stun: float = 0.2
@export var knockback: float = 150.0
@export var pogo_height: float = 280.0
@export var jump_invulnerability: float = 0.1
@export var hitstop_duration: float = 3.0 / 60.0
@export var attack_recovery: float = 0.1
@export var collision_size := Vector2(24, 32)
@export_category("Presentation")
@export var visual_scale: float = 0.22
@export var animation_fps: float = 12.0
@export var run_cycle_distance: float = 96.0
@export var preload_actions: bool = true
@export var world_bounds := Rect2(0, 0, 1000, 1100)

const PRIORITY := {"idle":0,"run":1,"jump_land":2,"strike_02":3,"interact":4,"strike_01":5,"A3_anchor":6,"A4_parry":7,"heavy":8,"recover":9,"A1_dash":10,"A5_slit":11,"hit":12,"defeat":13}
const CLIPS := {
	"idle":["idle",0,35], "run":["run",6,29], "jump_land":["jump_land",9,24],
	"strike_02":["strike_02",9,24], "strike_01":["strike_01",8,30],
	"heavy":["heavy",14,28], "hit":["hit",6,15], "recover":["recover",5,30],
	"interact":["interact",6,30], "defeat":["defeat",0,35],
	"A1_dash":["A1_dash",6,17], "A2_float":["A2_float",10,23],
	"A3_anchor":["A3_anchor",10,24], "A4_parry":["A4_parry",6,23], "A5_slit":["A5_slit",7,28]
}
var health: int = 100
var soul: int = 99
var facing: float = 1.0
var state: String = "idle"
var state_time: float = 0.0
var state_duration: float = 0.0
var invulnerable: float = 0.0
var armor: float = 0.0
var hitstop: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var jump_count: int = 0
var jump_start_y: float = 0.0
var short_jump: bool = false
var apex_left: float = 0.0
var apex_used: bool = false
var wall_lock: float = 0.0
var event_done: bool = false
var dead_signal_sent: bool = false
var controls_enabled: bool = true
var interacted_target: Node
var spawn_point := Vector2.ZERO
var cooldowns := {"dash":0.0,"slit":0.0,"orb":0.0,"heavy":0.0,"heal":0.0}
var hit_targets: Dictionary = {}
var pending_action: String = ""
var pending_left: float = 0.0
var was_grounded: bool = false
var animation_state: String = ""
var visual_frame: int = 0:
	set(value):
		visual_frame = value
		if is_node_ready(): _set_texture(value)
var display_action: String = "idle":
	set(value):
		if not CLIPS.has(value):return
		display_action=value
		if is_node_ready():
			_cache_clip(value)
			_set_texture(visual_frame)
var textures: Dictionary = {}
var effect_textures: Dictionary = {}
@onready var body: Sprite2D = $Visual/Body
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var tree: AnimationTree = $AnimationTree
var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	preload("res://scripts/tide_input.gd").install()
	health = max_health
	soul = max_soul
	spawn_point = position
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 5.0
	floor_stop_on_slope = true
	safe_margin = 0.05
	($CollisionShape2D.shape as RectangleShape2D).size = collision_size
	$CollisionShape2D.position.y = -collision_size.y / 2.0
	$Visual.scale = Vector2.ONE * visual_scale
	if preload_actions:
		for id in CLIPS:_cache_clip(id)
	_build_animation_tree()
	stats_changed.emit(health, soul)

func _build_animation_tree() -> void:
	var machine := AnimationNodeStateMachine.new()
	var index := 0
	for id in CLIPS:
		var node := AnimationNodeAnimation.new()
		node.animation = StringName("game/" + id)
		machine.add_node(id, node, Vector2(index%4*190,index/4*95))
		index += 1
	for a in CLIPS:
		for b in CLIPS:
			if a == b: continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.05 if a in ["idle","run"] and b == "strike_01" else 0.0
			machine.add_transition(a,b,transition)
	var blend := AnimationNodeBlendTree.new()
	blend.add_node("States",machine)
	blend.add_node("Speed",AnimationNodeTimeScale.new())
	blend.connect_node("Speed",0,"States")
	blend.connect_node("output",0,"Speed")
	tree.tree_root = blend
	tree.anim_player = NodePath("../AnimationPlayer")
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	playback = tree.get("parameters/States/playback")
	_choose_animation("idle")

func _choose_animation(id: String) -> void:
	if animation_state == id: return
	animation_state = id
	var source_id: String = CLIPS[id][0]
	display_action=source_id
	_cache_clip(source_id)
	playback.travel(id)
	tree.advance(0)
	_set_texture(visual_frame)

func _cache_clip(source_id: String) -> void:
	if not CLIPS.has(source_id):return
	if not textures.has(source_id):
		var frames: Array[Texture2D] = []
		for i in range(36): frames.append(load("res://assets/animations/player/body/%s/%03d.png" % [source_id,i]))
		textures[source_id] = frames
		if source_id in ["heavy","A1_dash","A2_float","A3_anchor","A4_parry"]:
			var effects: Array[Texture2D] = []
			for i in range(36):effects.append(load("res://assets/animations/player/effects/%s/%03d.png" % [source_id,i]))
			effect_textures[source_id]=effects

func _set_texture(value: int) -> void:
	if animation_state.is_empty(): return
	var source_id: String = display_action
	if textures.has(source_id): body.texture = textures[source_id][clampi(value,0,35)]
	if has_node("Visual/Effect"):
		$Visual/Effect.texture=effect_textures[source_id][clampi(value,0,35)] if effect_textures.has(source_id) else null

func _physics_process(dt: float) -> void:
	if not controls_enabled: return
	if hitstop > 0:
		hitstop = maxf(0,hitstop-dt)
		return
	for key in cooldowns: cooldowns[key] = maxf(0,cooldowns[key]-dt)
	invulnerable = maxf(0,invulnerable-dt)
	armor = maxf(0,armor-dt)
	wall_lock = maxf(0,wall_lock-dt)
	jump_buffer = maxf(0,jump_buffer-dt)
	pending_left = maxf(0,pending_left-dt)
	if pending_left <= 0: pending_action = ""
	var grounded: bool = is_on_floor() and ($Foot0.is_colliding() or $"Foot-10".is_colliding() or $Foot10.is_colliding())
	if grounded:
		coyote = coyote_time
		jump_count = 0
		if not was_grounded: cooldowns.dash = 0.0
	else: coyote = maxf(0,coyote-dt)
	was_grounded = grounded
	if health > 0:
		_read_input()
		if not pending_action.is_empty() and request_action(pending_action): pending_action = ""
		if jump_buffer > 0 and _can_jump_cancel(): _try_jump()
	state_time += dt
	_update_action_events()
	var axis := Input.get_axis("tp_left","tp_right")
	var locked := state in ["recover","interact","hit","defeat"]
	if absf(axis)>0.1 and state not in ["A1_dash","A5_slit"] and not locked: facing=signf(axis)
	if state in ["A1_dash","A5_slit"]:
		velocity = Vector2(facing*(dash_speed if state=="A1_dash" else slit_speed),0)
	else:
		if state != "hit":
			var control := 1.0 if grounded else air_control
			if wall_lock <= 0: velocity.x = move_toward(velocity.x,0.0 if locked else axis*max_speed,(friction if is_zero_approx(axis) or locked else acceleration)*control*dt)
		if not grounded:
			if short_jump and velocity.y<0:
				var remaining := maxf(0, short_jump_height-(jump_start_y-position.y))
				velocity.y = maxf(velocity.y,-sqrt(2*gravity*remaining))
			if velocity.y>=0 and not apex_used:
				apex_left=apex_hold
				apex_used=true
			if apex_left>0:
				apex_left-=dt
				velocity.y=0
			else: velocity.y=minf(velocity.y+gravity*(fall_multiplier if velocity.y>0 else 1.0)*dt,1500)
			if _wall_direction()!=0 and velocity.y>0 and axis==_wall_direction(): velocity.y=minf(velocity.y,wall_slide_speed)
	move_and_slide()
	if position.y > world_bounds.end.y+100: take_damage(max_health,Vector2.ZERO,true)
	$Visual.scale.x = visual_scale*facing
	body.material.set_shader_parameter("flash",1.0 if invulnerable>0 and int(invulnerable*30)%2==0 else 0.0)
	if state_duration <= 0:
		var desired := "idle"
		if absf(velocity.x)>5: desired="run"
		if not is_on_floor(): desired="A2_float" if _wall_direction()!=0 and velocity.y>0 else "jump_land"
		state=desired
	_choose_animation(state)
	var rate := (maxf(.3,absf(velocity.x)*anim.get_animation("game/run").length/run_cycle_distance) if state=="run" else 1.0)*animation_fps/12.0
	tree.set("parameters/Speed/scale",rate)
	tree.advance(dt)
	cooldowns_changed.emit(cooldowns.duplicate())
	availability_changed.emit(jump_count<2,cooldowns.dash<=0)

func _read_input() -> void:
	if Input.is_action_just_pressed("tp_jump"): jump_buffer=jump_buffer_time
	if Input.is_action_just_released("tp_jump"): short_jump=true
	var mapping := {"tp_attack":"A3_anchor" if Input.is_action_pressed("tp_down") and not is_on_floor() else "strike_01","tp_dash":"A1_dash","tp_slit":"A5_slit","tp_orb":"A4_parry","tp_heavy":"heavy","tp_heal":"recover","tp_interact":"interact"}
	for action in mapping:
		if Input.is_action_just_pressed(action):
			if not request_action(mapping[action]):
				pending_action=mapping[action]
				pending_left=jump_buffer_time

func _can_jump_cancel() -> bool:
	return state_duration<=0 or state=="strike_02" or (state in ["strike_01","A3_anchor"] and state_time>=2.0/animation_fps+1.0/animation_fps+attack_recovery*.5)

func _try_jump() -> void:
	var wall := _wall_direction()
	if wall!=0 and not is_on_floor():
		velocity=Vector2(-wall*wall_jump_x,-sqrt(2*gravity*wall_jump_height))
		wall_lock=.15
		facing=-wall
		jump_count=1
	elif coyote>0:
		velocity.y=-sqrt(2*gravity*jump_height)
		jump_count=1
	elif jump_count<2:
		velocity.y=-double_jump_speed
		jump_count=2
		_enter("strike_02",.35)
	else: return
	if state!="strike_02": state_duration=0
	jump_start_y=position.y
	short_jump=false
	apex_used=false
	apex_left=0
	invulnerable=maxf(invulnerable,jump_invulnerability)
	jump_buffer=0
	coyote=0
	animation_tag.emit("jump")

func _wall_direction() -> float:
	if $WallLeft.is_colliding(): return -1.0
	if $WallRight.is_colliding(): return 1.0
	return 0.0

func request_action(action: String) -> bool:
	if health<=0 or not controls_enabled: return false
	if state_duration>0:
		if action==state: return false
		if PRIORITY.get(action,0)<=PRIORITY.get(state,0): return false
		if state in ["strike_01","A3_anchor"] and action=="A1_dash" and not _can_jump_cancel(): return false
	var key: String = {"A1_dash":"dash","A5_slit":"slit","A4_parry":"orb","heavy":"heavy","recover":"heal"}.get(action,"")
	if not key.is_empty() and cooldowns[key]>0:
		notification.emit("技能冷却中")
		return false
	if action in ["A4_parry","heavy","recover"] and soul<skill_cost:
		notification.emit("魂量不足 · 需要33点")
		return false
	if action=="recover" and (not is_on_floor() or health>=max_health):
		notification.emit("调息需落地且生命未满")
		return false
	if action=="interact" and not is_instance_valid(interacted_target): return false
	if action=="A3_anchor" and is_on_floor(): return false
	var duration: float = {"strike_01":3.0/animation_fps+attack_recovery,"A3_anchor":3.0/animation_fps+attack_recovery,"A1_dash":dash_duration,"A5_slit":slit_duration,"A4_parry":.5,"heavy":.55,"recover":heal_time,"interact":.5}.get(action,.35)
	if action in ["A4_parry","heavy","recover"]:
		soul-=skill_cost
		stats_changed.emit(health,soul)
	if not key.is_empty(): cooldowns[key]={"dash":dash_cooldown,"slit":slit_cooldown,"orb":orb_cooldown,"heavy":heavy_cooldown,"heal":heal_cooldown}[key]
	_enter(action,duration)
	if action in ["A1_dash","A5_slit"]: invulnerable=maxf(invulnerable,duration)
	return true

func _enter(action: String,duration: float) -> void:
	state=action
	state_time=0
	state_duration=duration
	event_done=false
	hit_targets.clear()
	_choose_animation(action)
	playback.start(action,true)
	tree.advance(0)
	animation_tag.emit(action+":start")

func _update_action_events() -> void:
	if state_duration<=0: return
	if state=="defeat" and dead_signal_sent:return
	var clip := anim.get_animation("game/"+state)
	var marker := "damage" if state in ["strike_01","A3_anchor"] else "release"
	var trigger := clip.get_marker_time(marker)*12.0/animation_fps if clip.has_marker(marker) else 2.0/animation_fps
	if state in ["strike_01","A3_anchor"] and state_time>=trigger and state_time<trigger+1.0/animation_fps:
		_melee(state=="A3_anchor")
	if not event_done and state_time>=trigger:
		event_done=true
		animation_tag.emit(state+":release")
		if state=="A4_parry": _spawn_orb()
		if state=="heavy":
			armor=.1
			for enemy in get_tree().get_nodes_in_group("tide_targets"):
				if global_position.distance_to(enemy.global_position)<heavy_radius: _hit(enemy,heavy_damage,false)
	if state_time+0.00001>=state_duration:
		animation_tag.emit(state+":end")
		if state=="recover":
			health=mini(max_health,health+heal_amount)
			stats_changed.emit(health,soul)
		if state=="interact" and is_instance_valid(interacted_target): interaction_requested.emit(interacted_target)
		if state=="defeat":
			if not dead_signal_sent:
				dead_signal_sent=true
				died.emit()
			return
		state_duration=0

func _melee(downward: bool) -> void:
	var area := Rect2(global_position+Vector2(12 if facing>0 else -32,-34),Vector2(20,34))
	if downward: area=Rect2(global_position+Vector2(-15,0),Vector2(30,20))
	for enemy in get_tree().get_nodes_in_group("tide_targets"):
		if not hit_targets.has(enemy.get_instance_id()) and area.intersects(enemy.hurt_rect()):
			_hit(enemy,melee_damage,true)
			if downward:
				velocity.y=-sqrt(2*gravity*pogo_height)
				jump_count=0
				cooldowns.dash=0.0
				short_jump=false
				apex_used=false

func _hit(enemy: Node,amount: int,gain_soul: bool) -> void:
	if hit_targets.has(enemy.get_instance_id()): return
	hit_targets[enemy.get_instance_id()]=true
	enemy.take_hit(amount)
	if gain_soul: soul=mini(max_soul,soul+soul_per_hit)
	stats_changed.emit(health,soul)
	hitstop=hitstop_duration
	hit_confirmed.emit()

func _spawn_orb() -> void:
	var projectile := preload("res://scripts/tide_orb.gd").new()
	projectile.position=global_position+Vector2(facing*24,-24)
	projectile.direction=facing
	projectile.speed=orb_speed
	projectile.life=orb_lifetime
	projectile.damage=orb_damage
	projectile.caster=self
	get_parent().add_child(projectile)

func take_damage(amount: int=15,source: Vector2=Vector2.ZERO,force: bool=false) -> bool:
	if health<=0 or (invulnerable>0 and not force): return false
	health=maxi(0,health-amount)
	soul=maxi(0,soul-hurt_soul_loss)
	invulnerable=hurt_invulnerability
	stats_changed.emit(health,soul)
	damaged.emit()
	if health<=0:
		_enter("defeat",3.0)
		velocity.x=0
		return true
	if armor<=0:
		_enter("hit",hurt_stun)
		velocity.x=knockback*(signf(global_position.x-source.x) if source!=Vector2.ZERO else -facing)
	return true

func respawn() -> void:
	position=spawn_point
	facing=1.0
	wall_lock=0
	apex_left=0
	apex_used=true
	short_jump=false
	hitstop=0
	velocity=Vector2.ZERO
	health=max_health
	soul=max_soul
	state="idle"
	state_duration=0
	state_time=0
	jump_count=0
	jump_buffer=0
	pending_action=""
	dead_signal_sent=false
	invulnerable=.5
	for key in cooldowns: cooldowns[key]=0.0
	stats_changed.emit(health,soul)
