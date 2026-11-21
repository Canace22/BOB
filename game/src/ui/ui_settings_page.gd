class_name WhaleUISettingsPage
extends RefCounted

static func build(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "界面与声音"
	var column: VBoxContainer = WhaleUIPages.menu(ui,720)
	_toggle(column, "Numbers", "数值辅助", "显示生命、蓄振与 Boss 的准确数值；关闭后蓄振显示可释放次数。",ui.preferences.numbers,func(value: bool) -> void:
		ui.preferences.numbers=value
		ui.save_preferences())
	_toggle(column, "Contrast", "增强对比", "加深 HUD 底色，增强控件边框。",ui.preferences.contrast,func(value: bool) -> void:
		ui.preferences.contrast=value
		ui.save_preferences())
	_toggle(column, "Motion", "减少动态", "关闭镜头震动与冲刺缩放；保留攻击和危险提示。",ui.preferences.reduce_motion,func(value: bool) -> void:
		ui.preferences.reduce_motion=value
		ui.save_preferences())
	_toggle(column, "Mute", "静音", "也可按 M 切换。",ui.preferences.muted,func(value: bool) -> void:
		ui.preferences.muted=value
		ui.save_preferences())
	var row := HBoxContainer.new()
	column.add_child(row)
	var label: Label = WhaleUIStyle.label("主音量",18)
	label.custom_minimum_size.x=170
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "Volume"
	slider.min_value=0
	slider.max_value=100
	slider.step=1
	slider.value=ui.preferences.volume*100
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var number: Label = WhaleUIStyle.label("%d%%"%slider.value,18,WhaleUIStyle.AMBER)
	number.custom_minimum_size.x=75
	row.add_child(number)
	slider.value_changed.connect(func(value: float) -> void:
		number.text="%d%%"%value
		ui.preferences.volume=value/100
		ui.save_preferences())
	WhaleUIPages.action(column, "MusicCredits", "声音来源", func() -> void: _music_credits(ui))
	WhaleUIPages.action(column,"SettingsBack","返回",ui.back)

static func _toggle(parent: Node, id: String, title: String, description: String, checked: bool, changed: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	var label: Label = WhaleUIStyle.label(title,20)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	text_column.add_child(label)
	var detail: Label = WhaleUIStyle.paragraph(description)
	detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	text_column.add_child(detail)
	var toggle := CheckButton.new()
	toggle.name=id
	toggle.text="开启" if checked else "关闭"
	toggle.button_pressed=checked
	toggle.custom_minimum_size=Vector2(110,48)
	row.add_child(toggle)
	toggle.toggled.connect(func(value: bool) -> void:
		toggle.text="开启" if value else "关闭"
		changed.call(value))

static func _music_credits(ui: WhaleCampaignUI) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "声音来源"
	dialog.dialog_hide_on_ok = true
	var credits := RichTextLabel.new()
	credits.bbcode_enabled = true
	credits.custom_minimum_size = Vector2(520, 250)
	credits.text = "\n".join([
		"[url=https://opengameart.org/content/rpg-music-the-lost-town]The Lost Town[/url] / [url=https://opengameart.org/content/rpg-exploration-the-black-temple]The Black Temple[/url] — HitCtrl · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]",
		"First Light Particles — Yoiyami · CC0",
		"",
		"[url=https://github.com/wesnoth/wesnoth/tree/1.18.5/data/core/music]The Battle for Wesnoth[/url] · [url=https://www.gnu.org/licenses/old-licenses/gpl-2.0.html]GNU GPL v2 or later[/url]",
		"Journey's End / Breaking the Chains — Mattias Westlund",
		"Love Theme — Ryan Reilly",
		"Into the Shadows — Tyler Johnson",
		"Elvish Theme — Doug Kaufman",
	])
	credits.meta_clicked.connect(func(url: Variant) -> void: OS.shell_open(str(url)))
	dialog.add_child(credits)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	ui.add_child(dialog)
	dialog.popup_centered()
