extends TestSuite
## Visual contracts use existing library textures as fixtures, not new art approval.
const Frames = preload("res://src/campaign/enemies/kit_clam_visual.gd")
const Visuals = preload("res://src/campaign/enemies/kit_encounter_visual.gd")

class VisualPlayer extends Node2D:
	var health: int = 5
	func take_damage(_amount: int, _center: Vector2) -> bool: return false

class VisualHost extends Node2D:
	var player: VisualPlayer
	var reference_visible: bool = false
	var layer_solo: int = -1
	var capture_path: String = ""
	func damage_enemy(_data: Dictionary, _amount: int) -> void: pass
	func sfx(_sound: String) -> void: pass

func make_host() -> VisualHost:
	var host := VisualHost.new()
	host.player = VisualPlayer.new()
	host.add_child(host.player)
	add(host)
	return host

func clam_config() -> Dictionary:
	return {"kind":"clam", "hits":26, "rest":99.0, "tell":0.9, "act":0.25, "recover":0.6,
		"sprites":{"body":{"path":"res://art/tide-picker-action36/idle-body.png", "scale":0.5, "columns":4, "rows":2},
		"tell":{"path":"res://art/world-kit/fx-pearl-rings.png", "scale":0.2},
		"shot":{"path":"res://art/world-kit/ringed-calcium-pearl.png", "scale":0.1}}}

func encounter(host: VisualHost, config: Dictionary) -> KitEncounter:
	var value := KitEncounter.new()
	value.host = host
	value.data = {"key":"visual-fixture:0", "pos":Vector2(400,300), "boss":true, "alive":true, "config":config}
	host.add_child(value)
	value.set_physics_process(false)
	return value

func test_clam_authored_frames_follow_the_four_existing_combat_phases() -> void:
	eq(Frames.frame_for("rest", 5.0, 1.0), 0, "Rest is closed")
	var selected: Array[int] = []
	for time: float in [0.0,0.26,0.51,0.99]: selected.append(Frames.frame_for("tell",time,1.0))
	eq(selected, [1,2,3,4], "Tell advances through four authored opening poses")
	eq(Frames.frame_for("act",0.2,0.25), 4, "Emission keeps its open pose")
	selected.clear()
	for time: float in [0.0,0.21,0.41]: selected.append(Frames.frame_for("recover",time,0.6))
	eq(selected, [5,6,7], "Recovery plays the three closing poses")
	eq(Frames.frame_for("rest",0.0,1.0), 0, "Completion returns to the closed pose")

func test_clam_atlas_anchors_using_cell_height_and_missing_atlas_keeps_static_fallback() -> void:
	var config: Dictionary = clam_config()
	config.offset = [12,-10]
	var body := Visuals.single_body(config,"clam")
	eq(body.hframes,4,"Atlas columns are read from metadata")
	eq(body.vframes,2,"Atlas rows are read from metadata")
	eq(body.position,Vector2(12,-10 - body.texture.get_height() * 0.5 / 2.0 * 0.5),"Foot anchor uses one cell, not the whole sheet")
	body.update_pose("recover",0.6,0.6)
	eq(body.frame,7,"A full atlas can display the final authored frame")
	body.free()
	config.sprites.body.path = "res://art/world-kit/missing-clam-atlas-test.png"
	config.sprites.body.fallback_path = "res://art/world-kit/resonant-clam.png"
	config.sprites.body.fallback_scale = 0.2
	body = Visuals.single_body(config,"clam")
	check(not body.has_method("update_pose"),"Unavailable animation keeps a static body")
	eq(body.hframes,1,"Fallback never cuts the old static artwork into atlas cells")
	eq(body.texture.resource_path,str(config.sprites.body.fallback_path),"Fallback uses the existing bitmap")
	eq(body.scale,Vector2.ONE * 0.2,"Fallback retains its own authored scale")
	body.free()

func test_authored_pivot_can_place_the_feet_above_the_cell_bottom() -> void:
	var config: Dictionary = clam_config()
	config.offset = [12,-10]
	config.sprites.body.pivot = [30,80]
	var body := Visuals.single_body(config,"clam")
	var cell_size: Vector2 = body.texture.get_size() / Vector2(4,2)
	var authored_foot := Vector2(30,80)
	check((body.position + (authored_foot - cell_size * 0.5) * body.scale).is_equal_approx(Vector2(12,-10)),"Actual visible foot lands at the intended origin despite transparent canvas below it")
	body.free()
	config.sprites.body.path = "res://art/world-kit/missing-clam-atlas-test.png"
	config.sprites.body.fallback_path = "res://art/world-kit/resonant-clam.png"
	config.sprites.body.fallback_scale = 0.2
	body = Visuals.single_body(config,"clam")
	check(body.position.is_equal_approx(Vector2(12,-10 - body.texture.get_height() * 0.2 * 0.5)),"Atlas pivot is not applied to the unrelated static fallback")
	body.free()

func test_encounter_drives_clam_frames_and_pause_holds_pose_without_changing_combat() -> void:
	var host := make_host()
	var value := encounter(host,clam_config())
	var hit_box: Rect2 = value.hurt_rect()
	eq(value.data.hp,26,"Visual attachment preserves configured health")
	value.enter("tell")
	value.timer = 0.5
	value._physics_process(0.0)
	eq(value.body.frame,3,"The live encounter clock selects the pose")
	eq(value.hurt_rect(),hit_box,"Changing animation never changes its damage receiver")
	value.set_physics_process(true)
	tree.paused = true
	var before: float = value.timer
	var frame: int = value.body.frame
	for i: int in 3: await tree.process_frame
	eq(value.timer,before,"Paused encounter does not advance the combat clock")
	eq(value.body.frame,frame,"Paused encounter holds the authored pose")
	tree.paused = false
	value.set_physics_process(false)
	value.enter("recover")
	eq(value.body.frame,5,"Entering recovery starts its first authored pose immediately")
	value.timer = 0.59
	value._physics_process(0.0)
	eq(value.body.frame,7,"Recovery reaches its last pose")
	eq(value.data.hp,26,"Playback does not mutate health")

func test_swarm_core_is_optional_and_shares_death_cleanup_with_its_cluster() -> void:
	var host := make_host()
	var config: Dictionary = {"kind":"swarm", "hits":24, "count":4, "radius":88.0,
		"lane":[100,900], "sprites":{"body":{"path":"res://art/world-kit/amphipod-swarm.png","scale":0.2},
		"tell":{"path":"res://art/world-kit/fx-danger-line.png","scale":0.2}}}
	var plain := encounter(host,config.duplicate(true))
	check(plain.core == null,"Existing swarms need no new core")
	config.sprites.core = {"path":"res://art/world-kit/spine-resonant-clams.png","scale":0.15}
	var value := encounter(host,config)
	check(is_instance_valid(value.core) and value.core.get_parent() == value.body,"Core shares cluster transform and lifetime")
	var before: Rect2 = value.hurt_rect()
	Visuals.update(value.body,value.core,"tell",0.4,0.9,0.4)
	check(value.core.scale != Vector2.ONE * 0.15,"Allowed swarm core has a subtle independent pulse")
	eq(value.hurt_rect(),before,"Core shape is never used as collision geometry")
	eq(value.data.hp,24,"Optional core does not change combat health")
	value.add_mark(load(str(config.sprites.tell.path)),0.2,Vector2.ZERO)
	var mark: Sprite2D = value.marks[0]
	var shot := Sprite2D.new()
	host.add_child(shot)
	value.shots.append({"node":shot,"velocity":Vector2.ZERO,"life":1.0})
	value.data.alive = false
	value.on_defeated()
	eq(value.marks.size(),0,"Defeat clears all warning registrations")
	eq(value.shots.size(),0,"Defeat clears all projectile registrations")
	await tree.process_frame
	check(not is_instance_valid(mark) and not is_instance_valid(shot),"Defeat frees detached marks and projectiles")
	await tree.create_timer(0.8).timeout
	check(not value.body.visible and not value.core.is_visible_in_tree(),"Defeated core disappears with the cluster")
	value._physics_process(0.0)
	eq(value.collision_layer,0,"Defeat still disables the original collision layer")
