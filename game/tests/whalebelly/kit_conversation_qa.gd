extends SceneTree
## Explicit isolated room fixtures; physical-key InputEvents drive conversations.
const OUT: String = "res://build/qa/npc-dialog"
const TestHost: GDScript = preload("res://tests/whalebelly/doorway_test_host.gd")
var host: WhalebellyMain
var ui: WhaleCampaignUI
var checks: Array[Dictionary] = []
var failures: int = 0

class BoneReadModel extends Node2D:
	func has_ability(id: String) -> bool: return id == "bone"

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for frame: int in count: await physics_frame

func key(code: Key, pressed: bool = true) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code)
	await tick(2)
	key(code,false)
	await tick(3)

func check(label: String, value: bool) -> void:
	checks.append({"name":label,"pass":value})
	if not value: failures += 1
	print("CONVERSATION ","PASS " if value else "FAIL ",label)

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))

func room_index(id: String) -> int:
	for index: int in host.rooms.size():
		if str(host.rooms[index].id) == id: return index
	return -1

func current_resident(id: String) -> KitInteractable:
	for item: Node in get_nodes_in_group("kit_interactables"):
		if item is KitInteractable and item.interaction_id == id and host.scenery.is_ancestor_of(item): return item
	return null

func await_conversation(id: String) -> bool:
	for frame: int in 100:
		await tick(1)
		if ui.page_id == "conversation": return ui.conversation_id == id
	return false

func open_with_f(id: String) -> bool:
	await tap(KEY_F)
	var opened: bool = await await_conversation(id)
	check(id+" physical F opens authored conversation",opened)
	if opened: await tick(8)
	return opened

func close_with_enter() -> void:
	await tap(KEY_ENTER)
	await tick(24)
	check("Return closes conversation and resumes",ui.page_id.is_empty() and not paused and host.player.controls_enabled)

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(TestHost)
	host.set("suite","kit-conversations")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	ui = host.player_ui as WhaleCampaignUI
	await tick(20)
	# Explicit start on the existing broad hub bank beside Yusuo, without reward grants.
	host.load_room(room_index("R3-01"),[1347,2080],false)
	await tick(35)
	check("uses isolated QA save",host.qa and host.save_path().contains("kit-conversations"))
	var yusuo: KitInteractable = current_resident("hub-yusuo")
	var beituo: KitInteractable = current_resident("hub-beituo")
	check("both authored resident bitmaps exist",yusuo != null and beituo != null and yusuo.get_child_count() > 0 and beituo.get_child_count() > 0)
	check("Yusuo nearest and prompt matches",KitInteractable.nearest(host) == yusuo and ui.data.prompt() == yusuo.prompt())
	await shot("00-yusuo-in-room")
	if await open_with_f("hub-yusuo"):
		check("default authored guidance is displayed",ui.conversation_lines == yusuo.lines and ui.heading.text == yusuo.title)
		await shot("01-yusuo-conversation")
		var before: Vector2 = host.player.position
		var before_clock: float = host.clock
		await tick(30)
		check("conversation freezes world and actor",paused and host.player.position == before and host.clock == before_clock)
		key(KEY_D)
		await tap(KEY_ESCAPE)
		await tick(20)
		check("closing while moving waits for key release",paused and ui.pending_resume and host.player.position == before)
		key(KEY_D,false)
		await tick(24)
		check("release restores gameplay",not paused and host.player.controls_enabled and ui.page_id.is_empty())
	await tap(KEY_ESCAPE)
	check("Pause restores full screen layout after conversation",ui.page_id == "pause" and ui.shade.get_rect() == Rect2(Vector2.ZERO,ui.panel.size) and ui.ornament.visible and not ui.hud.visible)
	await shot("06-pause-after-conversation")
	await tap(KEY_ESCAPE)
	await tick(24)
	for repeat: int in 3:
		if await open_with_f("hub-yusuo"): await close_with_enter()
	# Walk along H1 between the residents; do not rewrite the player position.
	key(KEY_D)
	for frame: int in 100:
		await tick(1)
		if host.player.position.x >= 1635.0: break
	key(KEY_D,false)
	await tick(20)
	check("walking reaches Beituo",str(host.room.id) == "R3-01" and KitInteractable.nearest(host) == beituo and host.player.is_on_floor())
	await shot("02-beituo-in-room")
	if await open_with_f("hub-beituo"):
		check("Beituo remains friendly resident",ui.conversation_lines == beituo.lines and host.enemies.is_empty())
		await shot("03-beituo-conversation")
		root.size = Vector2i(960,540)
		await tick(10)
		await shot("07-small-conversation")
		root.size = Vector2i(1280,720)
		await tick(10)
		await close_with_enter()
	# Second room fixture; the campaign is never granted bone or other progression.
	var old_yusuo: WeakRef = weakref(yusuo)
	var old_beituo: WeakRef = weakref(beituo)
	host.load_room(room_index("R4-06"),[595,1440],false)
	await tick(35)
	var node: KitInteractable = current_resident("transit-bone-node")
	check("Inactive streamed residents cannot interact across rooms",(old_yusuo.get_ref() == null or not old_yusuo.get_ref().nearby(host)) and (old_beituo.get_ref() == null or not old_beituo.get_ref().nearby(host)) and KitInteractable.nearest(host) == node)
	check("bone remains locked",not host.has_ability("bone"))
	if await open_with_f("transit-bone-node"):
		check("node reads locked authored text",ui.conversation_lines == node.locked_lines)
		await shot("04-bone-node-locked")
		await close_with_enter()
	var original: Dictionary = host.abilities.duplicate(true)
	var read_model: BoneReadModel = BoneReadModel.new()
	var unlocked: PackedStringArray = node.lines_for(read_model)
	check("read-only bone branch chooses unlocked text",unlocked == node.lines)
	# Layout-only preview from a read model. Not natural-unlock evidence.
	ui.open_conversation(node.title,unlocked,node.interaction_id)
	await tick(10)
	check("unlocked text uses conversation page",ui.page_id == "conversation" and ui.conversation_lines == node.lines)
	await shot("05-bone-node-unlocked-text-fixture")
	await close_with_enter()
	read_model.free()
	check("reading grants no campaign flags",host.abilities == original and not host.has_ability("bone"))
	var result: Dictionary = {"checks":checks,"failures":failures,"save":host.save_path(),"method":"Native GPU main scene; R3-01/R4-06 room/spawn fixtures; physical InputEventKey F/Escape/Return and walking between residents. Bone-unlocked text uses a read-only model/layout fixture, no reward grants or natural-unlock/full-playthrough claim."}
	FileAccess.open(OUT.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	await host.graceful_quit(1 if failures > 0 else 0)
