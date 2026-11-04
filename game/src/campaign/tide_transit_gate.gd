class_name TideTransitGate
extends Node2D
## Attach to an authored gate sprite; this component creates no placeholder art.
signal pass_used(player: TidePlayer)
@export var destination_room_id: String = ""
@export var destination_spawn: Vector2 = Vector2.ZERO
@export var interaction_radius: float = 90.0
var used: bool = false

func _ready() -> void:
	add_to_group("tide_transit_gates")

func use_transit_pass(player: TidePlayer) -> void:
	if not player.skill_unlocked("chapter") or global_position.distance_to(player.global_position)>interaction_radius: return
	used=true
	pass_used.emit(player)
	player.notification.emit("通行凭证已验证")
	if destination_room_id.is_empty() or not "host" in player: return
	var host: Node2D=player.host
	for index: int in host.rooms.size():
		if str(host.rooms[index].id)==destination_room_id:
			player.transition_locked=true
			host.enter_door.call_deferred({"to":index,"spawn":[destination_spawn.x,destination_spawn.y]})
			return
	push_warning("Transit destination not found: "+destination_room_id)
