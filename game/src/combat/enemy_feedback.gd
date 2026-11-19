class_name TideEnemyFeedback
extends Node
## 呈现只偏移位图；冻结由宿主显式检查，不暂停整个场景或改变碰撞体。
var visual: Node2D
var base_position: Vector2
var stop_left: float = 0.0
var stamp: int = -1
var age: float = 1.0
var direction: float = 1.0
var power: float = 0.0
var materials: Array[ShaderMaterial] = []
var sprites: Array[Sprite2D] = []

func setup(view: Node2D, install_flash: bool = true) -> void:
	visual = view
	base_position = view.position
	if install_flash: _install(view)

func _install(node: Node) -> void:
	if node is Sprite2D:
		var mat := ShaderMaterial.new()
		mat.shader = preload("hit_flash.gdshader")
		node.material = mat
		materials.append(mat)
		sprites.append(node)
	for child: Node in node.get_children(): _install(child)

func receive(seconds: float, toward: float, strength: float) -> void:
	stop_left = maxf(stop_left,seconds)
	stamp = Engine.get_physics_frames()
	age = 0.0
	direction = toward
	power = strength
	_present()

func frozen(dt: float) -> bool:
	var stopped: bool = stop_left > 0.0
	if Engine.get_physics_frames() != stamp: stop_left = maxf(0.0,stop_left-dt)
	age += dt
	_present()
	return stopped

func _present() -> void:
	if not is_instance_valid(visual): return
	visual.position.x = base_position.x+direction*power*exp(-age*25.0)
	# Streaming adds edge uniforms by duplicating materials. Drive the currently
	# displayed material rather than the one installed before room preparation.
	for i: int in sprites.size():
		var mat := sprites[i].material as ShaderMaterial
		if mat == null: continue
		materials[i] = mat
		mat.set_shader_parameter("flash",clampf(1.0-age/0.075,0.0,1.0))

func clear() -> void:
	stop_left = 0.0
	age = 1.0
	_present()
