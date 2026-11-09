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

func test_dead_zone_and_smooth_reversal() -> void:
	var camera: WhalebellyCampaignCamera = fixture()
	var host: Host = camera.host
	var initial: Vector2 = camera.position
	host.player.position += Vector2(10,40)
	camera.update_follow(1.0/60.0)
	check(camera.position.distance_to(initial) < .01, "small horizontal/vertical movement stays inside dead zone")
	host.player.facing = -1.0
	camera.update_follow(1.0/60.0)
	check(camera.position.distance_to(initial) < 5.0, "facing reversal does not jump the camera")
	check(camera.smoothed_lookahead > 0.0, "lookahead eases through zero instead of snapping")
	host.player.position.y += 200
	var before: float = camera.position.y
	camera.update_follow(1.0/60.0)
	check(camera.position.y > before and camera.position.y < before + 30, "large jump follows with vertical lag")

func test_shake_and_zoom_stay_inside_room() -> void:
	var camera: WhalebellyCampaignCamera = fixture()
	var host: Host = camera.host
	for corner: Vector2 in [Vector2.ZERO, Vector2(4096,2400)]:
		host.player.position = corner
		camera.tracked_room = "reset"
		host.camera_feedback = 20.0
		camera.update_follow(.016)
		var half: Vector2 = camera.get_viewport_rect().size / (2 * camera.zoom)
		var center: Vector2 = camera.position + camera.offset
		check(center.x - half.x >= -.01 and center.x + half.x <= 4096.01, "shake respects horizontal room bounds")
		check(center.y - half.y >= -.01 and center.y + half.y <= 2400.01, "shake respects vertical room bounds")
		check(camera.offset.length() <= camera.shake_pixels * sqrt(2.0) + .01, "feedback intensity is bounded")
	host.room = {"id":"small", "size":[1280,720]}
	host.player.position = Vector2(30,650)
	host.player.state = "A1_dash"
	camera.update_follow(.016)
	check(camera.zoom.x >= 1.0, "dash cannot zoom out beyond a viewport-size room")
	eq(camera.position, Vector2(640,360), "room change snaps to the new clamped center")

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
