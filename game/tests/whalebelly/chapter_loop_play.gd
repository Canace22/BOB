extends "res://src/campaign/main.gd"
## 正式角色/对话/伤害的隔离循环样板；不导入正式存档，不替换19房主线。
var wall_start_ms: int = Time.get_ticks_msec()
var loop_beats: Array[Dictionary] = []
var loop_result: Dictionary = {}
var loop: WhaleChapterOneLoop
func _init() -> void:
	qa=true
	qa_full_abilities=false
	integration_external_test=true
	ui_interactive_in_tests=true
func save_path() -> String:
	return "user://whalebelly/chapter-loop-"+ProjectSettings.globalize_path("res://").sha256_text().left(12)+".json"
func _ready() -> void:
	super._ready()
	streaming.enabled=false
	streaming.reset()
	DisplayServer.window_set_title("鲸落万物生 · 第一章循环验证（修订版）")
	dialogue.enabled=true
	var badge := Label.new()
	badge.text="第一章循环样板 · 敌人动作与居民位置为占位"
	badge.add_theme_font_override("font",WhaleUIStyle.FONT)
	badge.add_theme_font_size_override("font_size",14)
	badge.position=Vector2(420,18)
	player_ui.panel.add_child(badge)
	print("CHAPTER_LOOP_READY isolated_save=",save_path())
func _create_room_enemies() -> void:
	enemies=[]
func load_room(index: int, target_spawn: Array = [], record_discovery: bool = true, stream_crossing: bool = false) -> void:
	# 复用现有关卡作入口占位，出口真的改变房间，不再以通知代替通行。
	index=clampi(index,0,1)
	rooms[1].name="折井入口"
	if index==1:
		rooms[1].doors=[{"pos":[75,715],"to":0,"spawn":[1390,650],"ability":""}]
	super.load_room(index,target_spawn,record_discovery,false)
	player.automatic_doors=false
	if index==0:
		var sample: Node2D=preload("res://content/whalebelly/narrative/chapter_loop.tscn").instantiate()
		sample.set("host",self)
		scenery.add_child(sample)
		loop=sample as WhaleChapterOneLoop
		var entrance: CampaignDoorway=continuity.doorways[0]
		entrance.position=Vector2(1530,ground_y(1530,650))
		entrance.data.pos=[entrance.position.x,entrance.position.y]
		entrance.kind="door"
		entrance.radius=140
		var label := WhaleUIStyle.label("↓ 折井入口",20,WhaleUIStyle.AMBER)
		label.position=Vector2(-90,-240)
		label.z_index=25
		entrance.add_child(label)
	else:
		loop=null
		var arrival := WhaleChapterFoldwell.new()
		arrival.host=self
		scenery.add_child(arrival)

func _unhandled_key_input(event: InputEvent) -> void:
	# 验证入口保留正常暂停/存读档，关闭房间预览和全能力练习，避免绕开样板状态。
	if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_F9]: return
	super._unhandled_key_input(event)

func enter_door(_door: Dictionary) -> void:
	if continuity.travelling: return
	if room_index==1:
		return_to_passage()
		return
	if not dialogue.seen.get("loop.aftermath",false):
		notify("补巢者正在赶来说明下层通路，安全落地后会自动交流")
		return
	loop.stage="departure"
	loop.mark("departure")
	loop_result={"strikes":loop.strikes,"guards":loop.guards,"backsteps":loop.backsteps,"damage_taken":loop.damage_taken,"observed":loop.observed}
	continuity.travel({"to":1,"pos":[1530,ground_y(1530,650)],"spawn":[180,715]})

func restart_loop() -> void:
	dialogue.restore({})
	loop_beats.clear()
	loop_result.clear()
	wall_start_ms=Time.get_ticks_msec()
	health=5
	player_soul=99
	load_room(0)
	player_ui.previous_controls=true
	player_ui.previous_pause=false
	player_ui.close_all()

func return_to_passage() -> void:
	load_room(0,[1390,ground_y(1390,650)])
	player_ui.previous_controls=true
	player_ui.previous_pause=false
	player_ui.close_all()

func record_completion() -> void:
	var entry: Dictionary={"id":"completed","stage":"complete","seconds":clock,"wall_seconds":(Time.get_ticks_msec()-wall_start_ms)/1000.0}
	loop_beats.append(entry)
	var output: Dictionary=loop_result.duplicate(true)
	output.merge({"stage":"complete","beats":loop_beats,"seconds":clock,"notes":"Route execution only; human motivation and pacing remain subject to playtest."})
	var file := FileAccess.open("res://build/qa/chapter-loop/latest-play.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(output,"\t"))
