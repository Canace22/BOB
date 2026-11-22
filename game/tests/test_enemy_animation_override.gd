extends TestSuite
## 用已存在的位图验证数据合同；这些裁片仅用于测试，不能登记为新增美术。

func adapter() -> EnemyLabAnimationOverride:
	var result: EnemyLabAnimationOverride=EnemyLabAnimationOverride.new()
	result.loaded=true
	return result

func authored_clip() -> Dictionary:
	return {"action":"sweep","state":"tell","texture":"res://art/enemy-lab-readability-v1/forager.png",
		"reference_height":128.0,"frames":[
			{"at":0.0,"rect":[0,0,100,100],"pivot":[50,90]},
			{"at":0.5,"rect":[100,0,100,100],"pivot":[40,90]}]}

func test_progress_samples_original_phase_without_own_clock() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	var clip: Dictionary=view._validate(authored_clip(),"forager","clips")
	view.enemies={"forager":{"clips":[clip]}}
	eq(view.sample("forager","sweep","tell",1,0.49).frame.rect[0],0,"前半段第一张")
	eq(view.sample("forager","sweep","tell",1,0.5).frame.rect[0],100,"精确阶段边界切帧")
	eq(view.sample("forager","sweep","tell",1,1.0).frame.rect[0],100,"阶段终点保持尾帧")
	eq(view.sample("forager","sweep","recover",1,0.1),{},"缺少整段时回退原图")

func test_exact_pulse_has_priority_over_shared_clip() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	var shared: Dictionary=view._validate(authored_clip(),"forager","clips")
	var specific: Dictionary=shared.duplicate(true)
	specific.pulse=2
	specific.frames=[specific.frames[1].duplicate(true)]
	specific.frames[0].at=0.0
	view.enemies={"forager":{"clips":[shared,specific]}}
	eq(view.sample("forager","sweep","tell",2,0.0).frame.rect[0],100,"续段专用片段优先")
	eq(view.sample("forager","sweep","tell",1,0.0).frame.rect[0],0,"首段仍用共用片段")

func test_incomplete_clip_rejects_whole_sequence() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	var broken: Dictionary=authored_clip()
	broken.frames[1].rect=[99999,0,100,100]
	eq(view._validate(broken,"forager","clips"),{},"越界尾帧拒绝整段")
	eq(view.diagnostics.size(),1,"拒绝原因可供诊断")

func test_warden_weakpoint_and_elder_copy_contracts() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	eq(view._validate(authored_clip(),"pump_warden","clips"),{},"无逐帧弱点不得替换泵庭")
	var clip: Dictionary=authored_clip()
	clip.action="elder_mimic"
	view.enemies={"elder_guardian":{"clips":[view._validate(clip,"elder_guardian","clips")]}}
	eq(view.sample("elder_guardian","elder_mimic","active",1,0.5),{},"完整复制归专用呈现拥有")
	eq(view.sample("elder_guardian","elder_mimic","tell",1,0.5).frame.rect[0],100,"只允许新施法准备帧")

func test_body_uses_authored_pivot_and_uniform_scale() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	var clip: Dictionary=view._validate(authored_clip(),"forager","clips")
	view.enemies={"forager":{"clips":[clip]}}
	var sprite: Sprite2D=Sprite2D.new()
	view.apply_body(sprite,view.sample("forager","sweep","tell",1,0.7),1.0,64.0)
	eq(sprite.offset,Vector2(-40,-90),"逐帧枢轴")
	eq(sprite.scale,Vector2(-0.5,0.5),"统一等比尺度与朝向")
	eq(sprite.region_rect,Rect2(100,0,100,100),"使用作者裁片")
	sprite.free()

func test_warmup_only_validates_requested_profile() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	var unrelated: Dictionary=authored_clip()
	unrelated.texture="res://art/does-not-exist.png"
	view.sources={"forager":{"clips":[authored_clip()]},"elder_guardian":{"clips":[unrelated]}}
	view.warmup("forager")
	eq(view.enemies.has("elder_guardian"),false,"入场不解码其它Boss")
	eq(view.diagnostics.size(),0,"无关资源尚未读取或验证")
	eq(view.enemies.forager.clips.size(),1,"当前profile已预热")

func test_windup_uses_explicit_preparation_state_without_active_fallback() -> void:
	var view: EnemyLabAnimationOverride=adapter()
	var clip: Dictionary=authored_clip()
	clip.action="eel_brood"
	clip.state="coil"
	clip.anchor=[0,-5]
	clip.scale=0.3
	view.enemies={"nest_eel":{"windups":[view._validate(clip,"nest_eel","windups")]}}
	eq(view.sample("nest_eel","eel_brood","coil",2,0.5,"windups").frame.rect[0],100,"续段准备态读取显式FX")
	eq(view.sample("nest_eel","eel_brood","active",2,0.5,"windups"),{},"出手无配置则不显示准备FX")
