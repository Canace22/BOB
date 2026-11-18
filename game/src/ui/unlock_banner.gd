class_name WhaleUnlockBanner
extends Control
## Consume the campaign's existing event IDs; never infer unlocks from notice text.

const LIFETIME := 3.5
var controller: WhaleCampaignUI
var last_sequence: int = 0
var pending: Array[Dictionary] = []
var current: Dictionary = {}
var age: float = 0.0
var card_rect := Rect2()
var title: Label
var detail: Label
var style := StyleBoxFlat.new()
var emblem: Texture2D
var clearance_alpha: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	last_sequence = controller.host.event_sequence
	emblem = load("res://art/ui/echo.svg") as Texture2D
	title = WhaleUIStyle.label("", 22)
	detail = WhaleUIStyle.label("", 16, WhaleUIStyle.TEAL)
	for label: Label in [title, detail]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_child(label)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = WhaleUIStyle.AMBER
	style.shadow_color = Color(WhaleUIStyle.AMBER, 0.12)
	style.shadow_size = 5
	hide()

func clear() -> void:
	pending.clear()
	current.clear()
	last_sequence = controller.host.event_sequence
	hide()

func _read_events() -> void:
	if last_sequence == controller.host.event_sequence: return
	for event: Dictionary in controller.host.events:
		if int(event.seq) <= last_sequence: continue
		last_sequence = int(event.seq)
		if controller.host.practice or controller.host.room_preview: continue
		var kind: String = str(event.event)
		var id: String = str(event.data.get("id", ""))
		var card: Dictionary = {}
		if kind == "ability_unlocked": card = ability_card(id)
		elif kind == "reward": card = relic_card(str(event.data.get("id", event.data.get("room", ""))))
		elif kind == "level_complete": card = {"id":"chapter", "title":"技能升级", "brief":"影潮 · 深鸣 · 共鸣啸 · 深钟"}
		if card.is_empty() or current.get("id", "") == card.id: continue
		if pending.any(func(item: Dictionary) -> bool: return item.id == card.id): continue
		pending.append(card)

static func ability_card(id: String) -> Dictionary:
	var description: String = ""
	match id:
		"dash": description = "%s 冲刺 · %s + J 五段连斩\n%s + K 回旋斩 · %s + %s + L 按住蓄力" % [WhaleUIStyle.key("tp_dash"), WhaleUIStyle.key("wb_rt"), WhaleUIStyle.key("wb_rt"), WhaleUIStyle.key("wb_lt"), WhaleUIStyle.key("wb_rt")]
		"float": description = "%s 起跳后，空中按住 %s 浮游\n松开落台 · 落地恢复浮膜余压" % [WhaleUIStyle.key("tp_jump"), WhaleUIStyle.key("float")]
		"pressure": description = "胃枢的强流门已可通行"
		"bone": description = "右侧通往交通椎的通路已开启"
		"silence": description = "已获得静默 · 返回交通椎，前往归海释放槽"
		_: return {}
	var brief: String = {"dash":"%s 冲刺" % WhaleUIStyle.key("tp_dash"), "float":"空中按住 %s 浮游" % WhaleUIStyle.key("float"), "pressure":"胃枢强流门已可通行", "bone":"右侧通往交通椎", "silence":"返回交通椎，前往归海释放槽"}[id]
	return {"id":id, "title":WhaleUICampaignData.ability_name(id), "detail":description, "brief":brief}

static func relic_card(id: String) -> Dictionary:
	if not CampaignRelics.ITEMS.has(id): return {}
	var description: String = "护盾上限 +%d · 自动生效，营地可补满" % int(CampaignRelics.ITEMS[id].charges)
	if id == "R1-03": description += "\n上涌 %s + W + L · 空中下潜 %s + S + L" % [WhaleUIStyle.key("wb_rt"), WhaleUIStyle.key("wb_rt")]
	var brief: String = "护盾 +%d" % int(CampaignRelics.ITEMS[id].charges)
	if id == "R1-03": brief += " · 解锁上涌 / 下潜"
	return {"id":id,"title":CampaignRelics.reward_name(id),"heading":"获得遗物","detail":description,"brief":brief}

func _process(dt: float) -> void:
	_read_events()
	if not get_parent().is_visible_in_tree() or get_tree().paused or controller.host.continuity.travelling or controller.host.continuity.transition.active: return
	if current.is_empty():
		if pending.is_empty(): return
		current = pending.pop_front()
		age = 0.0
		title.text = str(current.title) + (" · 已获得" if current.has("heading") else " · 已解锁")
		detail.text = str(current.brief) + " · H 详情"
		show()
	age += dt
	if age >= LIFETIME:
		current.clear()
		hide()
		return
	var reduced: bool = controller.preferences.reduce_motion
	var entrance: float = 1.0 if reduced else clampf(age / 0.3, 0.0, 1.0)
	style.bg_color = Color(WhaleUIStyle.INK, 1.0 if controller.preferences.contrast else 0.9)
	var right: float = size.x - 306.0
	var width: float = minf(430.0, maxf(220.0, right - 526.0))
	card_rect = Rect2(right - width, 24.0, width, 72.0)
	title.position = card_rect.position + Vector2(56, 7)
	title.size = Vector2(width - 70, 29)
	detail.position = card_rect.position + Vector2(56, 39)
	detail.size = Vector2(width - 70, 25)
	var feet: Vector2 = controller.player.get_global_transform_with_canvas().origin
	var silhouette := Rect2(feet - Vector2(54, 138), Vector2(108, 156))
	clearance_alpha = move_toward(clearance_alpha, 0.12 if card_rect.grow(12).intersects(silhouette) else 1.0, dt * 8.0)
	modulate.a = minf(entrance, clampf((LIFETIME - age) / 0.4, 0.0, 1.0)) * clearance_alpha
	queue_redraw()

func _draw() -> void:
	if current.is_empty(): return
	draw_style_box(style, card_rect)
	var spread: float = 1.0 if controller.preferences.reduce_motion else clampf(age / 0.45, 0.0, 1.0)
	var middle: Vector2 = card_rect.position + Vector2(card_rect.size.x * 0.5, 0)
	var extent := Vector2((card_rect.size.x - 40) * 0.5 * spread, 0)
	draw_line(middle - extent, middle + extent, WhaleUIStyle.AMBER, 2.0, true)
	var center: Vector2 = card_rect.position + Vector2(28, 36)
	draw_texture_rect(emblem, Rect2(center - Vector2(14,14),Vector2(28,28)), false, WhaleUIStyle.AMBER)
