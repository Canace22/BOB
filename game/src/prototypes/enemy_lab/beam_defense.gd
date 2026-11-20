class_name EnemyLabBeamDefense
extends Node2D
## 封梁卫的短时主动格挡；拦截成功不进入伤害结算，破防仍回到共用入口。
const KEYS: Array[String]=["beam_guard","beam_riposte"]
var enemy: EnemyLabBeamGuard
var blocks: int=0
var breaks: int=0
var ripostes: int=0
var capacity: int=2
var blocked_feedback: bool=false
var impact_age: float=1.0
var ring: Sprite2D
var audio: AudioStreamPlayer

func _ready() -> void:
	var tex := AtlasTexture.new()
	tex.atlas=preload("res://art/tide-picker-action36/ground-ring-fx.png")
	var frame: Array=enemy.player.action_visual.manifest.heavy.fx.frames[4]
	tex.region=Rect2(frame[0],frame[1],frame[2],frame[3])
	ring=Sprite2D.new()
	ring.texture=tex
	ring.rotation=PI*0.5
	ring.z_index=8
	add_child(ring)
	ring.hide()
	audio=AudioStreamPlayer.new()
	audio.stream=preload("res://art/whalebelly/runtime/audio/hit_3.wav")
	audio.volume_db=-8.0
	add_child(audio)

func handles() -> bool:
	return enemy.move_key in KEYS

func guarding() -> bool:
	return enemy.outcome.is_empty() and enemy.state in ["guarding","guard_contact"]

func begin() -> void:
	capacity=2
	blocked_feedback=false

func intercept(amount: int) -> bool:
	blocked_feedback=false
	if amount<=0 or not guarding(): return false
	var front: bool=(enemy.player.global_position.x-enemy.global_position.x)*enemy.facing>=0.0
	var guard: EnemyLabSkills=enemy.player.skill_controller as EnemyLabSkills
	var counter_reward: bool=guard.counter_left>0.0 and guard.counter_bonus>0
	# 重击和玩家赢得的迎击奖励可以破架，不能被新防御吞掉。
	if not front or amount>=3 or counter_reward or capacity<=1:
		breaks+=1
		impact_age=1.0
		ring.hide()
		blocked_feedback=false
		enemy.followup_cancelled=true
		enemy._open(1.25,"防守被破 · 反击取消")
		return false
	capacity-=1
	blocks+=1
	enemy.reactions.received+=1
	blocked_feedback=true
	impact_age=0.0
	ring.position=Vector2(enemy.facing*48.0,-53.0)
	if DisplayServer.get_name()!="headless": audio.play()
	if enemy.state=="guarding": enemy.set_state("guard_contact")
	enemy.last_result="弧刃格挡 · 轻击无伤 · 即将回斩"
	enemy.changed.emit(enemy.last_result)
	return true

func tick(dt: float) -> void:
	enemy.timer+=dt
	if enemy.timer<enemy.phase_duration(): return
	match enemy.state:
		"tell": enemy.set_state("guarding")
		"guarding":
			enemy.followup_cancelled=true
			enemy._open(0.65,"格挡落空 · 收刃破绽")
		"guard_contact":
			ripostes+=1
			enemy.move_key="beam_riposte"
			enemy.spec=EnemyLabCatalog.action("beam_riposte")
			enemy.set_state("tell")
			enemy.changed.emit("防御反击 · 回刃准备")

func pose() -> int:
	if enemy.state=="guarding": return 12
	if enemy.state=="guard_contact": return 13
	if enemy.move_key=="beam_guard" and enemy.state=="tell": return 12 if enemy.timer>0.11 else 0
	if enemy.move_key=="beam_riposte" and enemy.state in ["tell","active"]:
		return (4 if enemy.timer<0.25 else 5) if enemy.state=="tell" else 6
	return 15

func segments() -> Array[Dictionary]:
	if enemy.move_key=="beam_riposte":
		return [{"phase":"tell","pulse":1,"start":0.0,"end":0.55},{"phase":"active","pulse":1,"start":0.55,"end":0.75},{"phase":"recover","pulse":1,"start":0.75,"end":0.75+float(enemy.spec.recover)}]
	if enemy.state in ["recover","hurt"]:
		return [{"phase":"recover","pulse":1,"start":0.0,"end":float(enemy.spec.recover)}]
	if enemy.state=="guard_contact": return [{"phase":"guard_contact","pulse":1,"start":0.0,"end":0.22}]
	return [{"phase":"tell","pulse":1,"start":0.0,"end":0.22},{"phase":"guarding","pulse":1,"start":0.22,"end":0.97}]

func _physics_process(dt: float) -> void:
	impact_age+=dt
	ring.visible=impact_age<0.24 and enemy.outcome.is_empty()
	if ring.visible:
		ring.scale=Vector2.ONE*lerpf(0.22,0.48,impact_age/0.24)
		ring.modulate=Color(0.65,0.95,1.0,1.0-impact_age/0.24)
