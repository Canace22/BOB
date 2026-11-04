class_name CampaignCrabEffects
extends Node2D
## Authored bitmap contact dust and shed shell fragments; no generated geometry.
var dust: Sprite2D
var label: Label
var shells: Array[Sprite2D] = []
var last_state := ""
var age := 1.0
var shell_age := 1.0
var label_age := 1.0
@onready var boss: Node2D = get_parent() as Node2D

func _ready() -> void:
	dust = Sprite2D.new()
	dust.texture = load("res://art/enemies/crab_video/impact_dust.png")
	dust.hframes = 4
	dust.top_level = true
	dust.z_as_relative = false
	dust.z_index = 4
	dust.hide()
	add_child(dust)
	label = Label.new()
	label.add_theme_font_override("font",preload("res://art/fonts/WhalefallUI.ttf"))
	label.add_theme_font_size_override("font_size",22)
	label.top_level = true
	label.z_index = 6
	label.hide()
	add_child(label)
	for i in 3:
		var shell := Sprite2D.new()
		shell.texture = load("res://art/enemies/crab_video/shell_turn.png")
		shell.hframes = 4
		shell.scale = Vector2.ONE*(0.18+i*0.04)
		shell.top_level = true
		shell.z_as_relative = false
		shell.z_index = 4
		shell.hide()
		add_child(shell)
		shells.append(shell)

func _physics_process(dt: float) -> void:
	age += dt
	shell_age += dt
	label_age += dt
	dust.visible = age < 0.4
	dust.frame = mini(3,int(age*10))
	dust.modulate.a = clampf(1-age/0.4,0,0.65)
	label.visible = label_age < 0.6
	for i in shells.size():
		var shell := shells[i]
		shell.visible = shell_age < 0.65
		shell.frame = mini(3,int(shell_age*7))
		shell.global_position += Vector2((i-1)*65,-110+400*shell_age)*dt
		shell.modulate.a = clampf((0.65-shell_age)/0.3,0,0.6)
	if boss.state != last_state:
		if boss.state == "active":
			age = 0
			dust.global_position = boss.global_position+Vector2(boss.facing*210,-30)
			dust.scale = Vector2(boss.facing*0.65,0.65)
		elif boss.state in ["phase","stagger"]:
			shell_age = 0
			for i in shells.size(): shells[i].global_position = boss.global_position+Vector2((i-1)*70,-200)
		last_state = boss.state

func received(origin: Vector2, ranged: bool) -> void:
	label_age = 0
	var shell: bool = boss.hurtbox.last_result == "shell"
	var broken: bool = boss.hurtbox.last_result == "break"
	label.text = ("弹刀" if shell else ("破防！" if broken else "命中"))+" −%d" % boss.hurtbox.last_damage
	label.modulate = Color(0.58,0.86,1) if shell else Color(1,0.88,0.6)
	var area: Rect2 = boss.hurt_rect()
	var contact := Vector2(clampf(origin.x,area.position.x,area.end.x),clampf(origin.y if ranged else origin.y-38,area.position.y,area.end.y))
	label.global_position = contact+Vector2(-40,-62)
