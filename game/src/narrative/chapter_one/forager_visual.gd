class_name WhaleForagerVisual
extends CorpseCrabVisual
## 样板复用既有逐帧动作；按当前招式真实阶段取帧，不增加形变或伪造新动画。

func present(actor: Node2D) -> void:
	super.present(actor)
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
