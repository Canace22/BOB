class_name CombatWhiteboxEnemyVisual
extends CorpseCrabVisual
## 复用尸蟹现有图集；白盒浮空/倒地复用受击姿势，不冒充新增独立动作。

const POSES: Dictionary = {"idle":"idle","tell":"tell","active":"active","recover":"recover","stagger":"hurt","airborne":"hurt","down":"hurt","dead":"dead"}

func _ready() -> void:
	super._ready()
	var flash := ShaderMaterial.new()
	flash.shader = preload("hit_flash.gdshader")
	material = flash

func _process(_dt: float) -> void:
	present(get_parent())

func present(actor: Node2D) -> void:
	if clips.is_empty(): return
	action_id = str(POSES.get(str(actor.get("state")),"idle"))
	var age: float = float(actor.get("feedback_age"))
	var armored: bool = bool(actor.get("armored")) and str(actor.get("state")) in ["tell","active"]
	var flinch: bool = age < 0.18 and not armored and int(actor.get("health")) > 0
	if flinch: action_id = "hurt"
	var spec: Dictionary = clips[action_id]
	var ids: Array = spec.frames
	var time: float = float(actor.get("elapsed"))
	if flinch: time = age
	var index: int
	if action_id == "idle": index = int(time*float(spec.fps)) % ids.size()
	else: index = mini(ids.size()-1,int(time/maxf(float(spec.get("duration",0.2)),0.01)*ids.size()))
	frame_index = int(ids[index])
	texture = SHEETS[str(spec.sheet)]
	frame = frame_index
	scale = Vector2(-float(actor.get("facing"))*0.42,0.42)
	modulate = Color(1.1,1.0,0.85) if str(actor.get("state")) == "tell" else Color.WHITE
	position.x = float(actor.get("feedback_direction"))*float(actor.get("feedback_power"))*exp(-age*25.0)
	if material != null: material.set_shader_parameter("flash",clampf(1.0-age/0.075,0.0,1.0))
