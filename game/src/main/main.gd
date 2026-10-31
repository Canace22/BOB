class_name GameMain
extends Node2D

@onready var player: Player = $Player
@onready var host: Node2D = $RoomHost
var room: Room
var changing: bool = false


func _ready() -> void:
	EventBus.room_change_requested.connect(change_room)
	EventBus.player_died.connect(_respawn)
	if not GameState.loaded:
		GameState.load_progress()
	change_room(GameState.checkpoint_room, "camp")


func change_room(id: String, entry: String) -> void:
	if changing:
		return
	var path := WorldGraph.room_path(id)
	if path.is_empty() or not ResourceLoader.exists(path):
		EventBus.toast.emit("房间不可用 · 返回入鲸营地")
		path = WorldGraph.room_path(SaveService.START_ROOM)
	changing = true
	_change.call_deferred(path, entry)


func _change(path: String, entry: String) -> void:
	if is_instance_valid(room):
		host.remove_child(room)
		room.queue_free()
	GameState.arena_active = false
	room = (load(path) as PackedScene).instantiate() as Room
	host.add_child(room)
	GameState.enter_room(room.room_id)
	player.bounds = Rect2(Vector2.ZERO, room.dimensions + Vector2(0, 30))
	player.fall_damage = room.fall_damage
	player.reset_at(room.entry_position(entry))
	$CameraRig.reset_for(room)
	GameState.save_progress()
	EventBus.room_entered.emit(room.room_id)
	changing = false


func _respawn() -> void:
	await get_tree().create_timer(0.3, false).timeout
	GameState.restore()
	change_room(GameState.checkpoint_room, "camp")
	EventBus.toast.emit("在营地重新出发 · 永久收获仍在")
