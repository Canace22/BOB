extends Node
## Global signals between modules. Emit facts, not commands to specific nodes.

signal room_change_requested(room_id: String, entry_id: String)
signal room_entered(room_id: String)
signal player_died
signal stats_changed
signal ability_granted(ability_id: String)
signal flag_set(flag_id: String)
signal toast(text: String)
signal sfx(name: String)
signal hit_landed(at: Vector2, heavy: bool)
signal arena_changed(active: bool)
