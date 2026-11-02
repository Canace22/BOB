class_name CrabPrototypeEffects
extends Node2D
## Low authored wakes sit behind bodies; every contact is anchored in world space.

var dust: CombatEffect
var impact: CombatEffect
var resonance: CombatEffect
var received: CombatEffect
var hit_label: Label
var wakes: Array[CombatEffect] = []
var shells: Array[Sprite2D] = []
var shell_age := -1.0
var last_state := ""
var wake_x := 0.0
var wake_index := 0
var contacts := 0
@onready var boss: CrabPrototype = get_parent() as CrabPrototype


func _ready() -> void:
	dust = _effect()
	resonance = _effect()
	impact = _effect()
	impact.z_index = 4
	received = _effect()
	received.z_index = 5
	hit_label = Label.new()
	hit_label.theme = load("res://src/ui/theme.tres") as Theme
	hit_label.add_theme_font_size_override("font_size", 20)
	hit_label.z_index = 6
	hit_label.hide()
	add_child(hit_label)
	hit_label.top_level = true
	boss.get_node("Hurtbox").resolved.connect(_received)
	(boss.get_node("Hitbox") as Hitbox).landed.connect(_landed)
	for i in 3:
		wakes.append(_effect())
		var shell := Sprite2D.new()
		shell.texture = load(CrabPrototypeVisual.ROOT + "shell_turn.png") as Texture2D
		shell.hframes = 4
		shell.centered = false
		shell.offset = Vector2(-128, -128)
		shell.scale = Vector2.ONE * (0.18 + i * 0.04)
		shell.top_level = true
		shell.z_as_relative = false
		shell.z_index = 1
		shell.hide()
		add_child(shell)
		shells.append(shell)


func _effect() -> CombatEffect:
	var effect := CombatEffect.new()
	add_child(effect)
	effect.top_level = true
	return effect


func reset() -> void:
	shell_age = -1
	last_state = ""
	wake_index = 0
	contacts = 0
	if dust != null:
		dust.reset()
		resonance.reset()
		impact.reset()
		received.reset()
		hit_label.hide()
	for wake: CombatEffect in wakes:
		wake.reset()
	for shell: Sprite2D in shells:
		shell.hide()


func _physics_process(delta: float) -> void:
	impact.advance(delta)
	received.advance(delta)
	hit_label.visible = boss.hurtbox.feedback_left > 0 and boss.running
	dust.advance(delta)
	resonance.advance(delta)
	for wake: CombatEffect in wakes:
		wake.advance(delta)
	if boss.state != last_state:
		_enter_state()
		last_state = boss.state
	if boss.state == "active" and boss.kind == "charge" and absf(boss.global_position.x - wake_x) >= 42:
		_charge_wake()
	if shell_age >= 0:
		shell_age += delta
		for i in shells.size():
			var shell := shells[i]
			shell.visible = shell_age < 0.65
			shell.frame = mini(3, int(shell_age * 7))
			shell.global_position += Vector2((i - 1) * 65, -110 + 400 * shell_age) * delta
			shell.modulate.a = clampf((0.65 - shell_age) / 0.3, 0, 0.6)


func _enter_state() -> void:
	if boss.state in ["tell", "phase", "stagger", "dead", "waiting"]:
		dust.hide()
		for wake: CombatEffect in wakes:
			wake.hide()
	if boss.state == "tell":
		resonance.hide()
	if boss.state == "active":
		contacts += 1
		if boss.kind == "charge":
			_charge_wake()
		else:
			var finisher := boss.sequence.size() > 1 and boss.sequence_index == boss.sequence.size() - 1
			var slam := boss.kind == "slam"
			var width := (260.0 if slam else 220.0) * (1.08 if finisher else 1.0)
			var at := boss.global_position + Vector2(boss.facing * (235 if slam else 210), -width * 0.40)
			dust.play("slam" if slam else "sweep", at, width, 0.4 if slam else 0.32,
				0.60 if finisher else 0.48, boss.facing)
	elif boss.state == "observe" and last_state == "waiting":
		resonance.z_index = 1
		resonance.modulate = Color(0.76, 0.97, 1.0)
		resonance.play("resonance", boss.global_position + Vector2(boss.facing * 175, -62), 145, 0.48, 0.38)
	elif boss.state in ["phase", "stagger"]:
		shell_age = 0
		for i in shells.size():
			shells[i].global_position = boss.global_position + Vector2((i - 1) * 70, -200)
		if boss.state == "phase":
			resonance.z_index = 1
			var final_phase := boss.phase >= 2
			resonance.modulate = Color(1.0, 0.82, 0.60) if final_phase else Color(0.66, 1.0, 0.92)
			var at := boss.global_position + Vector2(boss.facing * 200, -90)
			resonance.play("resonance", at, 295 if final_phase else 220, 0.9, 0.58 if final_phase else 0.42)
	elif boss.state == "dead" and boss.target != null:
		resonance.z_index = 4
		resonance.modulate = Color.WHITE
		resonance.play("resonance", boss.target.global_position + Vector2(0, -100), 190, 1.6, 0.72)
	elif boss.state == "waiting":
		resonance.hide()
		if boss.target != null and boss.target.dead:
			resonance.z_index = 4
			resonance.modulate = Color(0.55, 0.85, 0.90)
			resonance.play("resonance", boss.target.global_position + Vector2(0, -75), 105, 0.9, 0.45)
			resonance.advance(0.46)


func _landed(target: Hurtbox, _hit: HitData) -> void:
	var claw := boss.global_position + Vector2(boss.facing * CrabMoves.value(boss.kind, "reach"), -36)
	impact.modulate = Color(1.0, 0.82, 0.61)
	impact.play("hit", CombatEffect.contact_point(target, claw), 66 if boss.kind == "slam" else 48,
		0.20, 0.72, boss.facing)


func _received(result: String, hit: HitData) -> void:
	var origin := hit.origin if hit.ranged else hit.origin + Vector2(0, -38)
	var at := CombatEffect.contact_point(boss.hurtbox, origin)
	var shell := result == "shell"
	var broken := result == "break"
	received.modulate = Color(0.58, 0.86, 1.0) if shell else Color(1.0, 0.88, 0.60)
	received.play("short2" if shell else ("heavy" if broken else "hit"), at,
		48 if shell else (155 if broken else 80), 0.16 if shell else (0.45 if broken else 0.24), 0.85, boss.facing)
	hit_label.text = ("弹刀" if shell else ("破防！" if broken else "命中")) + " −%d" % hit.damage
	hit_label.modulate = received.modulate
	hit_label.modulate.a = 1
	hit_label.global_position = at + Vector2(-40, -62)
	hit_label.show()


func _charge_wake() -> void:
	wake_x = boss.global_position.x
	var wake := wakes[wake_index % wakes.size()]
	wake_index += 1
	wake.play("charge", boss.global_position + Vector2(-boss.facing * 215, -64), 160, 0.38, 0.40, boss.facing)


func snapshot() -> Dictionary:
	var active_wakes: Array[Dictionary] = []
	for wake: CombatEffect in wakes:
		if wake.visible:
			active_wakes.append(wake.snapshot())
	return {"impact": impact.snapshot(), "received": received.snapshot(), "contact": dust.snapshot(), "wakes": active_wakes, "resonance": resonance.snapshot(),
		"contacts": contacts, "wake_count": wake_index}
