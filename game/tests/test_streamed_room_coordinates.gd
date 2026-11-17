extends TestSuite
## 房间根平移后，视差与物理查询必须保持房内含义，伤害来源必须保持世界含义。

class CoordinateHost extends Node2D:
	var player: Node2D
	var camera: Camera2D
	var scenery: Node2D
	var reference_visible: bool = false
	var layer_solo: int = -1
	var capture_path: String = ""
	var room: Dictionary = {"size":[1600,1200]}
	func point(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))

class PlayerProbe extends WhalebellyCampaignPlayer:
	func _ready() -> void: pass
	func _physics_process(_dt: float) -> void: pass

class CrabProbe extends CampaignCorpseCrab:
	func _ready() -> void: pass
	func _physics_process(_dt: float) -> void: pass

class EncounterProbe extends KitEncounter:
	func _ready() -> void: pass
	func _physics_process(_dt: float) -> void: pass

class DamageProbe extends Node2D:
	var last_source: Vector2 = Vector2.INF
	var hits: int = 0
	func take_damage(_amount: int, source: Vector2) -> bool:
		last_source = source
		hits += 1
		return true

func translated_room() -> Node2D:
	var room := Node2D.new()
	room.position = Vector2(5600,-1200)
	add(room)
	return room

func test_kit_parallax_removes_room_world_translation() -> void:
	var room := translated_room()
	var layer := KitParallaxLayer.new()
	layer.room_center = Vector2(800,600)
	layer.factor = 0.25
	room.add_child(layer)
	var camera := Camera2D.new()
	add(camera)
	camera.global_position = room.to_global(Vector2(1000,700))
	camera.make_current()
	camera.force_update_scroll()
	layer._process(0.0)
	eq(layer.position,Vector2(150,75),"Parallax derives its offset from camera room coordinates")
	var translation := Vector2(12000,8000)
	room.position += translation
	camera.global_position += translation
	camera.force_update_scroll()
	layer._process(0.0)
	eq(layer.position,Vector2(150,75),"Translating room and camera together does not change parallax")
	eq(layer.offset_for(Vector2(1000,700)),Vector2(150,75),"offset_for preserves its local-coordinate contract")

func test_crab_floor_probe_and_target_comparison_use_world_coordinates() -> void:
	var room := translated_room()
	var crab := CrabProbe.new()
	crab.position = Vector2(200,100)
	crab.home_x = 200
	room.add_child(crab)
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(230,110)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60,10)
	collider.shape = shape
	floor_body.add_child(collider)
	room.add_child(floor_body)
	await physics_frames(2)
	check(crab.floor_ahead(230),"Floor probe finds the translated collision floor")
	check(not crab.floor_ahead(330),"Floor probe still detects the end of the ledge")
	var player := PlayerProbe.new()
	# 父类的@onready仍会解析真实节点，即使探针覆写_ready也必须提供这些依赖。
	var visual := Node2D.new()
	visual.name="Visual"
	var body := Sprite2D.new()
	body.name="Body"
	visual.add_child(body)
	player.add_child(visual)
	var animation := AnimationPlayer.new()
	animation.name="AnimationPlayer"
	player.add_child(animation)
	var animation_tree := AnimationTree.new()
	animation_tree.name="AnimationTree"
	player.add_child(animation_tree)
	add(player)
	player.global_position = crab.global_position + Vector2(80,0)
	crab.target = player
	crab._decide(0.1)
	eq(crab.state,"tell","Player in another parent is detected in world space")
	eq(crab.facing,1.0,"Crab faces the world-space target")

func test_kit_touch_and_projectile_report_world_damage_sources() -> void:
	var room := translated_room()
	var player := DamageProbe.new()
	add(player)
	var host := CoordinateHost.new()
	host.player = player
	add(host)
	var encounter := EncounterProbe.new()
	encounter.host = host
	room.add_child(encounter)
	var source_local := Vector2(240,100)
	player.global_position = room.to_global(source_local + Vector2(0,45))
	encounter.touch(source_local,80)
	eq(player.hits,1,"Translated touch still reaches the player")
	eq(player.last_source,room.to_global(source_local),"Touch passes a world-space source to damage and parry")
	var shot := Sprite2D.new()
	shot.position = Vector2(360,100)
	room.add_child(shot)
	player.global_position = shot.global_position + Vector2(0,45)
	var source_world: Vector2 = shot.global_position
	encounter.shots.append({"node":shot,"velocity":Vector2.ZERO,"life":1.0})
	encounter.move_shots(0.0)
	eq(player.hits,2,"Translated projectile still reaches the player")
	eq(player.last_source,source_world,"Projectile passes its world-space source to damage and parry")
	check(encounter.shots.is_empty(),"Projectile releases after the hit")

func test_continuous_depth_uses_current_room_local_camera_center() -> void:
	var room := translated_room()
	var host := CoordinateHost.new()
	host.scenery = room
	add(host)
	var camera := Camera2D.new()
	add(camera)
	host.camera = camera
	var depth := XumenContinuousDepth.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float clock = 0.0;"
	var material := ShaderMaterial.new()
	material.shader = shader
	depth.material = material
	depth.position = Vector2(-16,-16)
	depth.host = host
	room.add_child(depth)
	camera.global_position = room.to_global(Vector2(1000,700))
	depth._process(0.0)
	var expected: Vector2 = depth.base_position + Vector2(1.2,0.6)
	check(depth.position.is_equal_approx(expected),"Depth offset derives from camera position inside this room")
	var translation := Vector2(12000,8000)
	room.position += translation
	camera.global_position += translation
	depth._process(0.0)
	check(depth.position.is_equal_approx(expected),"Room translation does not change depth parallax")
