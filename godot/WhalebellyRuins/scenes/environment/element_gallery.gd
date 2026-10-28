extends Node2D
## Preview UI only. No player input, collisions or map logic.
const GROUPS=["垂须与植物","逐鱼摆尾与游动","气泡分层","海底光纹与光束","前景视差"]
var selected: int=0
var clock: float=0.0
var playing: bool=true
@onready var environment: Node2D=$ReferenceEnvironment
@onready var info: Label=$CanvasLayer/Info
func _ready() -> void:
	environment.set_process(false)
	apply_group()
func apply_group() -> void:
	for child in environment.get_children():
		if not child.has_method("update_at"):continue
		child.visible=matches(str(child.name))
func matches(id: String) -> bool:
	match selected:
		0:return id.begins_with("BALEEN") or id.begins_with("PLANT") or id.begins_with("VINE")
		1:return id.begins_with("FISH")
		2:return id.begins_with("BUBBLE")
		3:return id.begins_with("CAUSTIC") or id.begins_with("BEAM") or id=="LAMP"
		4:return id.begins_with("FRONT")
	return false
func _process(delta: float) -> void:
	if playing:clock+=delta
	for child in environment.get_children():
		if child.has_method("update_at") and matches(str(child.name)):
			if str(child.name).begins_with("BUBBLE"):child.update_at(clock)
			else:child.update_at(clock,Vector2(sin(clock*TAU/12.0)*45.0,0.0) if selected==4 else Vector2.ZERO)
	# Zoom reserves image edges for the foreground demonstration.
	$Camera2D.zoom=Vector2.ONE*(1.12 if selected==4 else 1.0)
	info.text="独立动画元素预览 · "+GROUPS[selected]+"\n← / → 切换组 · 空格 暂停 · 场景参数在 elements/*.tscn 编辑"
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:playing=not playing
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:
			selected=posmod(selected+(1 if event.keycode==KEY_RIGHT else -1),GROUPS.size())
			apply_group()
