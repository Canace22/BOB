class_name EnemyLabVisual
extends Sprite2D
## 独立位图轮廓和动作关键帧按真实阶段播放，保留各自的等比尺寸与枢轴。
const SHEETS: Dictionary={
	"elder_guardian":preload("res://art/enemy-lab-elder-v1/elder_guardian.png"),
	"beam_guard":preload("res://art/enemy-lab-beam-guard-v1/beam_guard.png"),
	"pump_warden":preload("res://art/enemy-lab-warden-v1/pump_warden.png"),
	"nest_eel":preload("res://art/enemy-lab-eel-v1/nest_eel.png"),
	"forager":preload("res://art/enemy-lab-readability-v1/forager.png"),
	"mudback":preload("res://art/enemy-lab-readability-v1/mudback.png"),
	"shell_guard":preload("res://art/enemy-lab-readability-v1/shell_guard.png"),
	"membrane_hunter":preload("res://art/enemy-lab-predator-squid-jelly-v1/membrane_hunter.png")}
const EEL_NEST: Texture2D=preload("res://art/enemy-lab-eel-nest-v2/nest_actions.png")
const WARDEN_WATER: Texture2D=preload("res://art/enemy-lab-warden-water-v3/water_actions.png")
const ELDER_IDLE_FIXED: Texture2D=preload("res://art/enemy-lab-elder-idle-fix-v1/elder_idle_fixed.png")
var metadata: Dictionary={}
var pose_id: int=0

func _ready() -> void:
	centered=false
	region_enabled=true
	region_filter_clip_enabled=true
	metadata=JSON.parse_string(FileAccess.get_file_as_string("res://art/enemy-lab-readability-v1/atlas.json"))

func present(enemy: EnemyLabEnemy) -> void:
	update_warning(enemy)
	visible=enemy.show_art
	var id: String=str(enemy.profile.id)
	var meta: Dictionary=metadata[id]
	texture=SHEETS[id]
	var factor: float=float(enemy.profile.height)/float(meta.reference_height)
	scale=Vector2(-enemy.facing*factor,factor)
	var duration: float=enemy.phase_duration()
	var progress: float=clampf(enemy.timer/maxf(0.001,duration),0.0,0.999)
	pose_id=0
	if enemy.state in ["tell","active","recover"]:
		var row: int=enemy.profile.moves.find(enemy.move_key)+1
		var phase: int=0 if enemy.state=="tell" and progress<0.55 else (1 if enemy.state=="tell" else (2 if enemy.state=="active" else 3))
		if enemy.move_key=="double" and enemy.state=="active": phase=1 if enemy.pulse==1 else 2
		pose_id=row*4+phase
	elif enemy.state=="idle" or enemy.outcome=="retreat":
		if id=="membrane_hunter": pose_id=((int(enemy.timer*4.0)%4)+4)%4
		elif absf(enemy.velocity.x)>5.0: pose_id=((int(enemy.timer*9.0)%4)+4)%4
	elif enemy.state=="escape_tell": pose_id=13
	elif enemy.state=="evade": pose_id=10
	elif enemy.state=="return": pose_id=1 if int(enemy.timer*5.0)%2==0 else 3
	elif enemy.state=="hurt" or enemy.state=="ended": pose_id=7
	if id=="nest_eel" and enemy.state in ["hurt","ended"]: pose_id=11
	if enemy is EnemyLabEel and enemy.nest!=null:
		var nest_pose: int=enemy.nest.pose()
		if nest_pose>=16: pose_id=nest_pose-16
		elif nest_pose>=0:
			meta=metadata.nest_eel_special
			texture=EEL_NEST
			pose_id=nest_pose
	if id=="pump_warden":
		var water_pose: int=enemy.water.pose() if enemy.water!=null else -1
		if water_pose>=16: pose_id=water_pose-16
		elif water_pose>=0:
			meta=metadata.pump_warden_water
			texture=WARDEN_WATER
			pose_id=water_pose
		elif enemy.move_key=="warden_double" and enemy.state in ["tell","active"]:
			pose_id=12+(0 if enemy.state=="tell" else 1) if enemy.pulse==1 else 14+(0 if enemy.state=="tell" else 1)
		elif enemy.state in ["recover","hurt","ended"]: pose_id=7
		elif enemy.state in ["tell","active"]:
			var row: int=1 if enemy.move_key=="warden_thrust" else 2
			pose_id=row*4+(0 if enemy.state=="tell" and progress<0.55 else (1 if enemy.state=="tell" else 2))
	if enemy is EnemyLabBeamGuard: pose_id=enemy.pose()
	if enemy is EnemyLabElder: pose_id=enemy.pose()
	var cell: Dictionary=meta.regions[pose_id]
	var r: Array=cell.rect
	region_rect=Rect2(r[0],r[1],r[2],r[3])
	if id=="elder_guardian" and pose_id==22:
		# 仅替换多画竖杆的立稳姿势，独立裁片保留原pivot和比例，其余动作仍用原图。
		texture=ELDER_IDLE_FIXED
		region_rect.position=Vector2.ZERO
	var pivot: Array=cell.pivot
	offset=Vector2(-float(pivot[0]),-float(pivot[1]))
	modulate=Color("a2b1b7") if enemy.state=="ended" else Color.WHITE
	if id=="pump_warden" and texture==WARDEN_WATER:
		var anchors: Dictionary={0:Vector2(327,143),1:Vector2(321,144),4:Vector2(323,138),5:Vector2(339,134),8:Vector2(332,167)}
		var anchor: Vector2=anchors.get(pose_id,Vector2(330,150))
		var mat: ShaderMaterial=material as ShaderMaterial
		mat.set_shader_parameter("weak_center",(region_rect.position+anchor)/texture.get_size())
		mat.set_shader_parameter("weak_radius",Vector2(28,25)/texture.get_size())

func update_warning(enemy: EnemyLabEnemy) -> void:
	var mat := material as ShaderMaterial
	if mat==null: return
	var warning: bool=enemy.state=="tell" and enemy.outcome.is_empty() and bool(enemy.spec.get("unblockable",false))
	var intensity: float=0.0
	if warning:
		var progress: float=clampf(enemy.timer/maxf(0.001,enemy.phase_duration()),0.0,1.0)
		intensity=0.45+0.35*progress+0.10*sin(enemy.timer*16.0)
	mat.set_shader_parameter("danger",intensity)
	var weak: bool=enemy is EnemyLabWarden and enemy.water!=null and enemy.water.weak_window()
	mat.set_shader_parameter("weak_glow",0.75+0.20*sin(enemy.timer*12.0) if weak else 0.0)
