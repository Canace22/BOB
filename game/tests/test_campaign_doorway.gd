extends TestSuite
## Restriction presentation cannot grant progress or change interaction rules.
class DoorPlayer extends WhalebellyCampaignPlayer:
	func _ready() -> void: pass
	func _process(_dt: float) -> void: pass
	func _physics_process(_dt: float) -> void: pass

class DoorHost extends Node2D:
	var streaming: Dictionary = {"enabled":false}
	var player: WhalebellyCampaignPlayer
	var enemies: Array = []
	var abilities: Dictionary = {}
	var reference_visible: bool = false
	var layer_solo: int = -1
	var capture_path: String = ""
	func _init() -> void:
		player = load("res://content/whalebelly/CampaignPlayer.tscn").instantiate()
		player.set_script(DoorPlayer)
	func point(value: Array) -> Vector2: return Vector2(float(value[0]), float(value[1]))
	func ground_y(_x: float, _near_y: float) -> float: return 820.0
	func has_ability(id: String) -> bool: return bool(abilities.get(id, false))

func fixture(kind: String, data: Dictionary) -> Dictionary:
	var host := DoorHost.new()
	add(host)
	host.add_child(host.player)
	var entrance := CampaignDoorway.new()
	entrance.kind = kind
	entrance.height = 170.0
	host.add_child(entrance)
	entrance.bind(host, data)
	return {"host":host, "door":entrance}

func check_visible_gate_foot(door: CampaignDoorway) -> void:
	var image: Image = door.barrier.texture.get_image()
	var top: int = image.get_height()
	var bottom: int = 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x,y).a >= 32.0/255.0:
				top = mini(top,y)
				bottom = maxi(bottom,y+1)
	var base_y: float = door.position.y + door.barrier.position.y + bottom * door.barrier.scale.y
	check(absf(base_y - 820.0) < 0.01, "Visible latch base touches the floor, ignoring transparent padding and faint specks")
	check(absf((bottom-top) * door.barrier.scale.y - door.height) < 0.01, "Visible gate retains its authored height")

func test_sealed_latch_is_an_opaque_bitmap_on_the_ground_and_stays_closed() -> void:
	var data: Dictionary = {"to":-2, "pos":[500,800]}
	var result := fixture("sealed", data)
	var door: CampaignDoorway = result.door
	check(door.barrier != null and door.barrier.visible, "Sealed doorway has a visible actual latch")
	eq(door.barrier.texture.resource_path, "res://art/world-kit/blowhole-latch-closed.png", "The latch comes from the synced library")
	check(not door.inset.visible and not door.lip.visible, "Closed latch hides the open tunnel")
	check(door.barrier.scale.x == door.barrier.scale.y, "Closed bitmap retains uniform scale")
	check_visible_gate_foot(door)
	door.armed = true
	check(door.prompt().contains("未开放") and not door.update_entry(), "Visible latch preserves refusal and cannot auto-enter")
	eq(data, {"to":-2, "pos":[500,800]}, "Presentation cannot rewrite the room graph")

func test_boss_gate_switches_from_closed_bitmap_to_existing_open_tunnel() -> void:
	var result := fixture("door", {"to":4, "pos":[500,800], "ability":"boss"})
	var door: CampaignDoorway = result.door
	result.host.enemies = [{"boss":true,"alive":true,"name":"负壳守卫"}]
	door.update_art()
	check(door.barrier.visible and not door.inset.visible and not door.lip.visible, "Live boss owns a visible closed gate")
	check_visible_gate_foot(door)
	check(door.restriction().contains("负壳守卫"), "Boss requirement remains unchanged")
	result.host.enemies[0].alive = false
	door.update_art()
	check(not door.barrier.visible and door.inset.visible and door.lip.visible, "Defeat reveals the existing tunnel and foreground threshold")
	check(door.restriction().is_empty() and result.host.abilities.is_empty(), "Visual state never grants an ability")

func test_authored_kit_states_do_not_receive_a_duplicate_gate() -> void:
	var host := DoorHost.new()
	add(host)
	host.add_child(host.player)
	var door := CampaignDoorway.new()
	door.height = 0.0
	for state: String in ["Closed", "Open"]:
		var sprite := Sprite2D.new()
		sprite.name = state
		door.add_child(sprite)
	host.add_child(door)
	door.bind(host, {"to":4,"pos":[500,800],"requires":["pressure"]})
	door.update_art()
	check(door.barrier == null and door.inset == null, "Custom kit art remains the sole visual owner")
	check(door.get_node("Closed").visible and not door.get_node("Open").visible, "Missing pressure shows the authored closed state")
	host.abilities.pressure = true
	door.update_art()
	check(not door.get_node("Closed").visible and door.get_node("Open").visible, "Earned pressure reveals the authored open state")

func test_built_exit_has_an_open_tunnel_and_unbuilt_chapter_exit_keeps_its_semantics() -> void:
	var result := fixture("exit", {"to":7,"pos":[500,820],"completes":true})
	var door: CampaignDoorway = result.door
	check(door.inset != null and door.inset.visible and door.lip.visible, "An exit into a built region has a visible open tunnel")
	check(door.barrier == null and door.restriction().is_empty(), "A built exit acquires no new lock or gate")
	var base_y: float = door.position.y + door.lip.position.y + door.lip.region_rect.size.y * door.lip.scale.y
	check(absf(base_y - 820.0)<0.01,"Open exit threshold meets its authored floor")
	eq(door.data,{"to":7,"pos":[500,820],"completes":true},"Exit destination and milestone remain unchanged")
	var old := fixture("exit", {"to":-1,"pos":[500,820]})
	check(old.door.inset == null and old.door.barrier == null, "An unbuilt chapter exit keeps its prior presentation")
	eq(int(old.door.data.to),-1,"An unbuilt chapter exit is never redirected into another room")

func test_original_frame_uses_its_own_alpha_bounds_and_threshold_and_keeps_gate_rules() -> void:
	var host := DoorHost.new()
	add(host)
	host.add_child(host.player)
	var door := CampaignDoorway.new()
	door.height = 170.0
	door.tunnel_texture = load("res://art/whalebelly/motion_elements/PORTAL.png")
	door.texture_bounds = Rect2(0,4,126,155)
	door.threshold_region = Rect2(0,145,130,14)
	host.add_child(door)
	var data := {"to":4,"pos":[500,820],"ability":"boss"}
	host.enemies = [{"boss":true,"alive":true}]
	door.bind(host,data)
	check(not door.inset.visible and door.barrier.visible,"Original-frame override still waits for the original Boss condition")
	host.enemies[0].alive = false
	door.update_art()
	eq(door.inset.texture,door.tunnel_texture,"The original warm shell/red-rope pixels actually reach the door")
	eq(door.lip.region_rect,door.threshold_region,"Native source dimensions do not reuse the generic threshold crop")
	var base_y: float = door.position.y+door.inset.position.y+159.0*door.inset.scale.y
	check(absf(base_y-820.0)<.01,"Native alpha base, not padded canvas, touches the floor")
	check(door.inset.visible and door.lip.visible and not door.barrier.visible,"Original frame opens after the same Boss condition")
	eq(door.data,data,"Texture substitution leaves destination and condition unchanged")
	check(host.abilities.is_empty(),"Original art grants no progress")
