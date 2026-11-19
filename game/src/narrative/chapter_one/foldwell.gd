class_name WhaleChapterFoldwell
extends Node2D
## 让可见出口兑现为真实房间，到达后明确收束样板，提供重试和回访按钮。
var host: Node2D
var result_open: bool = false

func _ready() -> void:
	var trigger := WhaleDialogueTrigger.new()
	trigger.dialogue_id="loop.foldwell_arrival"
	trigger.room_id="R1-02"
	trigger.area=Rect2(-1000,-1000,5000,5000)
	trigger.speakers=PackedStringArray(["旁白","拾潮者"])
	trigger.lines=PackedStringArray(["穿过骨拱，拾潮者来到下层的折井入口。低鸣沿更深的井壁传来，旧封闭刻痕刻在前路旁。","补巢者指的路没有错。接下来，要找到守着这条路的人。"])
	trigger.objective_id="loop.arrived"
	trigger.objective_text="已抵达折井入口 · 本次循环验证完成"
	host.dialogue.ended.connect(_dialogue_finished)
	add_child(trigger)

func _process(_dt: float) -> void:
	if host.dialogue.seen.get("loop.foldwell_arrival",false) and host.dialogue.active.is_empty() and not result_open and not host.continuity.travelling:
		show_result()

func _dialogue_finished() -> void:
	if host.dialogue.seen.get("loop.foldwell_arrival",false): show_result.call_deferred()

func show_result() -> void:
	if result_open or not is_inside_tree(): return
	result_open=true
	var ui: WhaleCampaignUI=host.player_ui
	ui.open("chapter_result",false)
	ui.heading.text="已抵达折井入口"
	var column: VBoxContainer=WhaleUIPages.menu(ui,650)
	column.add_child(WhaleUIStyle.paragraph("你已穿过聚食区，并循着下层低鸣来到折井。\n本次循环验证到此完成。第二章主体尚未接入。",WhaleUIStyle.BONE))
	WhaleUIPages.action(column,"RestartLoop","重新试玩",host.restart_loop)
	WhaleUIPages.action(column,"ReturnPassage","返回须庭查看结果",host.return_to_passage)
	ui.footer.text="选择重新试玩或返回须庭 · Esc 可留在折井入口活动"
	host.record_event("chapter_loop_arrived",host.loop_result)
	host.record_completion()
