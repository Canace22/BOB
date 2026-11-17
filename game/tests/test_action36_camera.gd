extends TestSuite

const Camera = preload("res://src/campaign/campaign_camera.gd")

class Actor extends Node2D:
	var facing: float = 1.0
	var state: String = "idle"

class Host extends Node2D:
	var player: Actor = Actor.new()
	var zoomed: bool = true
	var reference_visible: bool = false
	var capture_path: String = ""
	var layer_solo: int = -1
	var camera_feedback: float = 0.0
	var room: Dictionary = {"id":"camera-fixture", "size":[4096,2400], "layered_environment":true}
	func point(value: Array) -> Vector2:
		return Vector2(float(value[0]), float(value[1]))
	func reference_camera_active() -> bool:
		return false
	func _ready() -> void:
		add_child(player)

func fixture() -> WhalebellyCampaignCamera:
	var host: Host = Host.new()
	add(host)
	host.player.position = Vector2(2000,1200)
	var camera: WhalebellyCampaignCamera = Camera.new()
	host.add_child(camera)
	camera.host = host
	camera.update_follow(1.0/60.0)
	return camera

func test_player_stays_centered_during_motion_and_reversal() -> void:
	var camera: WhalebellyCampaignCamera = fixture()
	var host: Host = camera.host
	host.player.position += Vector2(10,40)
	camera.update_follow(1.0/60.0)
	eq(camera.global_position, host.player.global_position, "even small movement follows without a dead zone")
	host.player.facing = -1.0
	camera.update_follow(1.0/60.0)
	eq(camera.global_position, host.player.global_position, "facing reversal does not offset the center")
	eq(camera.smoothed_lookahead, 0.0, "normal gameplay has no lookahead")
	host.player.position.y += 200
	camera.update_follow(1.0/60.0)
	eq(camera.global_position, host.player.global_position, "vertical movement follows without lag")
	host.position = Vector2(-1700,825)
	camera.update_follow(1.0/60.0)
	eq(camera.global_position, host.player.global_position, "translated room uses world coordinates")
	check(camera.get_screen_center_position().is_equal_approx(host.player.global_position), "rendered viewport center matches player after translation")

func test_room_edges_and_dash_keep_the_same_center_and_zoom() -> void:
	var camera: WhalebellyCampaignCamera = fixture()
	var host: Host = camera.host
	for corner: Vector2 in [Vector2.ZERO, Vector2(4096,2400)]:
		host.player.position = corner
		camera.tracked_room = "reset"
		host.camera_feedback = 20.0
		camera.update_follow(.016)
		eq(camera.global_position, host.player.global_position, "room edge does not push the player off center")
		eq(camera.offset, Vector2.ZERO, "feedback cannot displace the strict centered camera")
		check(not camera.limit_enabled and not camera.position_smoothing_enabled, "room limits and camera smoothing are disabled")
	var before_zoom: Vector2 = camera.zoom
	host.room = {"id":"small", "size":[1280,720]}
	host.player.position = Vector2(30,650)
	host.player.state = "A1_dash"
	camera.update_follow(.016)
	eq(camera.zoom, before_zoom, "dash and room change preserve the same gameplay scale")
	eq(camera.global_position, host.player.global_position, "room change preserves the actual player center")
	host.zoomed = false
	camera.update_follow(.016)
	check(camera.was_following, "legacy Tab panorama flag cannot break normal center-follow")

func test_reference_fit_stays_unchanged_and_shake_free() -> void:
	var camera: WhalebellyCampaignCamera = fixture()
	var host: Host = camera.host
	host.reference_visible = true
	host.camera_feedback = 1.0
	camera.update_follow(.016)
	eq(camera.position, Vector2(2048,1200), "reference view keeps full-room center")
	eq(camera.offset, Vector2.ZERO, "reference view has no shake")
	var view: Vector2 = camera.get_viewport_rect().size
	check(is_equal_approx(camera.zoom.x, minf(view.x/4096.0,view.y/2400.0)), "reference fit zoom remains unchanged")
	host.reference_visible = false
	host.capture_path = "qa-fixture.png"
	camera.update_follow(.016)
	check(not camera.was_following, "capture stays in full-room view despite default follow")
	host.capture_path = ""
	host.layer_solo = 0
	camera.update_follow(.016)
	check(not camera.was_following, "layer inspection stays in full-room view despite default follow")
