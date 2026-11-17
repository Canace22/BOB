class_name TideCombatAfterimage
extends Node2D
## 后跳触发时复制当前位图帧，固定世界变换；不读取GPU像素、不生成新贴图。

const LIFETIME: float = 0.20
const OPACITY: float = 0.62
var actor: TideCombatPlayer
var ghosts: Array[Dictionary] = []
var material_shared: ShaderMaterial
var captured: Dictionary = {}

func setup(player: TideCombatPlayer) -> void:
	actor = player
	material_shared = ShaderMaterial.new()
	material_shared.shader = preload("afterimage.gdshader")
	actor.backstep_started.connect(spawn)

func capture_pose() -> void:
	var source: Sprite2D = actor.action_visual.sprite
	captured.clear()
	if source.texture == null or not source.visible: return
	captured = {"texture":source.texture,"centered":source.centered,"offset":source.offset,"transform":source.global_transform}

func spawn() -> void:
	if captured.is_empty(): return
	var ghost := Sprite2D.new()
	ghost.texture = captured.texture
	ghost.centered = bool(captured.centered)
	ghost.offset = captured.offset
	ghost.material = material_shared
	ghost.top_level = true
	ghost.z_index = -1
	ghost.modulate.a = OPACITY
	add_child(ghost)
	# 使用触发前的画面姿势；后跳后角色再远离，残影也不跟随。
	ghost.global_transform = captured.transform
	ghosts.append({"node":ghost,"age":0.0})
	captured.clear()

func _process(dt: float) -> void:
	for i: int in range(ghosts.size()-1,-1,-1):
		var item: Dictionary = ghosts[i]
		item.age = float(item.age)+dt
		var ghost: Sprite2D = item.node
		if float(item.age) >= LIFETIME:
			ghost.queue_free()
			ghosts.remove_at(i)
			continue
		ghost.modulate.a = OPACITY*pow(1.0-float(item.age)/LIFETIME,0.7)

func clear() -> void:
	captured.clear()
	for item: Dictionary in ghosts:
		(item.node as Sprite2D).queue_free()
	ghosts.clear()
