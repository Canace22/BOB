class_name PlayerVisual
extends Sprite2D
## Existing static poses with programmatic feedback; these are not new drawn animation.

var frames: Dictionary[String, Array] = {}
var clock: float = 0.0
@onready var player: Player = get_parent() as Player
@onready var effect: Sprite2D = $Effect


func _ready() -> void:
	for state: String in ["idle", "run", "jump", "attack", "heavy", "hit", "dash", "heal"]:
		var images: Array[Texture2D] = []
		for i in 8:
			var path := "res://art/player/%s_%d.png" % [state, i]
			if ResourceLoader.exists(path):
				images.append(load(path) as Texture2D)
		frames[state] = images


func _process(delta: float) -> void:
	clock += delta
	var state := "run" if absf(player.velocity.x) > 20 else "idle"
	if not player.is_on_floor():
		state = "jump"
	var action := player.actions
	if action.mode == "attack":
		state = "heavy" if action.attack_kind == "heavy" else "attack"
	elif action.mode in ["heal", "dash"]:
		state = action.mode
	elif action.mode == "hurt":
		state = "hit"
	var images: Array = frames[state]
	if not images.is_empty():
		var frame := int(clock * 9) % images.size()
		if action.mode == "attack":
			var start := 0.30 if state == "heavy" else (0.16 if action.attack_kind == "short2" else 0.12)
			frame = 0 if action.elapsed < start else (1 if action.elapsed < start + 0.14 else 2)
		texture = images[mini(frame, images.size() - 1)] as Texture2D
	scale = Vector2(player.facing * 0.28, 0.28)
	position.y = -35.28
	modulate.a = 0.45 if player.invulnerable > 0 and sin(clock * 35) > 0 else 1.0
	effect.visible = player.hitbox.active or action.mode == "dash"
	if effect.visible:
		var kind := "dash_trail" if action.mode == "dash" else ("heavy_ring" if action.attack_kind == "heavy" else "short_swipe")
		effect.texture = load("res://art/fx/%s.png" % kind) as Texture2D
		var size := 200.0 if kind == "heavy_ring" else 120.0
		effect.scale = Vector2.ONE * size / effect.texture.get_width() / 0.28
		effect.position = Vector2(120 if kind != "dash_trail" else -80, 0)
