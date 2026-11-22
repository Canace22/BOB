class_name WhaleForagerVisual
extends CorpseCrabVisual
## 样板复用既有逐帧动作；按当前招式真实阶段取帧，不增加形变或伪造新动画。
var animation_override: EnemyLabAnimationOverride=EnemyLabAnimationOverride.new()
var windup_view: EnemyLabWindupView

func _ready() -> void:
	animation_override.warmup("forager")
	super._ready()

func present(actor: Node2D) -> void:
	# 原图用4×2整格；上帧若采用独立裁片，必须先完整恢复原图合同。
	region_enabled=false
	texture=SHEETS.attack
	hframes=4
	vframes=2
	offset=Vector2(-144,-224)
	super.present(actor)
	if windup_view==null:
		windup_view=EnemyLabWindupView.new()
		add_child(windup_view)
		windup_view.z_index=1
	windup_view.visible=false
	if actor.state not in ["tell","active","recover"]: return
	var spec: Dictionary=actor.PATTERNS[actor.attack_kind]
	var duration: float=float(spec[actor.state])
	if actor.state=="tell" and actor.followup: duration=0.30
	var phase: float=clampf(actor.timer/duration,0.0,0.999)
	var ids: Array=[]
	texture=SHEETS.attack
	match actor.state:
		"tell":
			# 冲撞收低待发、低扫抬钳、二连先高举；均来自已有攻击图集。
			ids=[0,0,1] if actor.attack_kind=="rush" else ([0,1,2] if actor.attack_kind=="sweep" else [2,2,2])
		"active":
			ids=[3,4,5]
			if actor.attack_kind=="rush":
				texture=SHEETS.walk
				ids=[0,1,2,3,4,5,6,7]
		"recover": ids=[6,7]
	frame_index=int(ids[mini(ids.size()-1,int(phase*ids.size()))])
	frame=frame_index
	var replacement: Dictionary=animation_override.sample("forager",actor.attack_kind,actor.state,2 if actor.followup else 1,phase)
	# 首章的可见高度不等于碰撞高度；由已验收素材显式提供 chapter_height。
	if not replacement.is_empty() and float(replacement.clip.get("chapter_height",0.0))>0.0:
		# 首章与试验场的旧待机来源不同，保留该入口原本独立配准的世界尺寸。
		var height: float=float(replacement.clip.chapter_height)
		var reference: float=float(replacement.clip.get("chapter_reference_height",replacement.clip.reference_height))
		height*=float(replacement.clip.reference_height)/reference
		animation_override.apply_body(self,replacement,actor.facing,height)
		# 旧整格脚底比actor原点低；新裁片保持相同世界脚底，不挪动碰撞体。
		offset.y+=float(replacement.clip.get("chapter_ground_offset",0.0))/scale.y
	if actor.state=="tell":
		windup_view.present(animation_override.sample("forager",actor.attack_kind,actor.state,2 if actor.followup else 1,phase,"windups"),actor.global_position,actor.facing)
