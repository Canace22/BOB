@warning_ignore_start("untyped_declaration")
class_name WhalebellyTideInput
extends RefCounted

static func install() -> void:
	var keys := {
		"tp_left": [KEY_A, KEY_LEFT], "tp_right": [KEY_D, KEY_RIGHT],
		"tp_up": [KEY_W, KEY_UP], "tp_down": [KEY_S, KEY_DOWN],
		"tp_jump": [KEY_K, KEY_SPACE], "tp_attack": [KEY_J, KEY_Q],
		"tp_dash": [KEY_L, KEY_SHIFT], "tp_orb": [KEY_U], "tp_heavy": [KEY_I],
		"tp_heal": [KEY_P], "tp_slit": [KEY_O], "tp_interact": [KEY_E], "tp_respawn": [KEY_R]
	}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
