class_name CrabPrototypeEffects
extends Node2D
## Detached authored sprites stay at impact position while the crab moves.

var dust: Sprite2D
var shells: Array[Sprite2D] = []
var dust_age := -1.0
var shell_age := -1.0
var last_state := ""
@onready var boss: CrabPrototype = get_parent() as CrabPrototype


func _ready() -> void:
	dust = _sprite("impact_dust", Vector2(-128, -224))
	dust.scale = Vector2(1.4, 1.4)
	for i in 3:
		var shell := _sprite("shell_turn", Vector2(-128, -128))
		shell.scale = Vector2.ONE * (0.18 + i * 0.04)
		shells.append(shell)


func _sprite(id: String, pivot: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(CrabPrototypeVisual.ROOT + id + ".png") as Texture2D
	sprite.hframes = 4
	sprite.centered = false
	sprite.offset = pivot
	sprite.visible = false
	sprite.top_level = true
	sprite.z_index = 4
	add_child(sprite)
	return sprite


func reset() -> void:
	dust_age = -1
	shell_age = -1
	last_state = ""
	if dust != null:
		dust.hide()
	for shell: Sprite2D in shells:
		shell.hide()


func _physics_process(delta: float) -> void:
	if boss.state != last_state:
		if boss.state == "active":
			dust_age = 0
			var reach := 160.0 if boss.kind == "charge" else 275.0
			dust.global_position = boss.global_position + Vector2(boss.facing * reach, 0)
		elif boss.state == "phase":
			shell_age = 0
			for i in shells.size():
				shells[i].global_position = boss.global_position + Vector2((i - 1) * 70, -260)
		last_state = boss.state
	if dust_age >= 0:
		dust_age += delta
		dust.visible = dust_age < 0.5
		dust.frame = mini(3, int(dust_age * 8))
		dust.modulate.a = clampf(1 - dust_age / 0.5, 0, 1)
	if shell_age >= 0:
		shell_age += delta
		for i in shells.size():
			var shell := shells[i]
			shell.visible = shell_age < 0.9
			shell.frame = int(shell_age * 10 + i) % 4
			shell.global_position += Vector2((i - 1) * 80, -170 + 520 * shell_age) * delta
			shell.modulate.a = clampf((0.9 - shell_age) / 0.3, 0, 1)
