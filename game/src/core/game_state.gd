extends Node
## Single owner of progress. Persistent: checkpoint_room, abilities, flags.
## Runtime only: hp, energy, current_room, arena_active.

const MAX_HP := 4
const MAX_ENERGY := 4

var save_path := SaveService.DEFAULT_PATH
var autosave := true
var loaded := false

var checkpoint_room := SaveService.START_ROOM
var current_room := ""
var abilities: Array[String] = []
var flags: Array[String] = []
var hp := MAX_HP
var energy := MAX_ENERGY
var arena_active := false


func load_progress() -> void:
	apply(SaveService.read(save_path))


func apply(data: Dictionary) -> void:
	checkpoint_room = data.get("checkpoint_room", SaveService.START_ROOM)
	abilities.assign(data.get("abilities", []))
	flags.assign(data.get("flags", []))
	arena_active = false
	loaded = true
	restore()


func to_save_data() -> Dictionary:
	return {
		"version": SaveService.VERSION,
		"checkpoint_room": checkpoint_room,
		"abilities": abilities.duplicate(),
		"flags": flags.duplicate(),
	}


func save_progress() -> void:
	if autosave:
		SaveService.write(to_save_data(), save_path)


func new_journey() -> void:
	apply(SaveService.default_data())
	save_progress()


func enter_room(room_id: String) -> void:
	current_room = room_id
	arena_active = false
	set_flag("map." + room_id)


func rest_at(room_id: String) -> void:
	checkpoint_room = room_id
	restore()
	save_progress()


func restore() -> void:
	hp = MAX_HP
	energy = MAX_ENERGY
	EventBus.stats_changed.emit()


func has_ability(id: String) -> bool:
	return abilities.has(id)


func grant_ability(id: String) -> void:
	if has_ability(id):
		return
	abilities.append(id)
	EventBus.ability_granted.emit(id)


func has_flag(id: String) -> bool:
	return flags.has(id)


func set_flag(id: String) -> void:
	if id.is_empty() or has_flag(id):
		return
	flags.append(id)
	EventBus.flag_set.emit(id)


func meets(required_abilities: PackedStringArray, required_flags: PackedStringArray) -> bool:
	for id in required_abilities:
		if not has_ability(id):
			return false
	for id in required_flags:
		if not has_flag(id):
			return false
	return true


## Returns true when this damage killed the player.
func damage(amount: int) -> bool:
	hp = maxi(0, hp - amount)
	EventBus.stats_changed.emit()
	return hp == 0


func heal(amount: int) -> void:
	hp = mini(MAX_HP, hp + amount)
	EventBus.stats_changed.emit()


func add_energy(amount: int) -> void:
	energy = mini(MAX_ENERGY, energy + amount)
	EventBus.stats_changed.emit()


func spend_energy(amount: int) -> bool:
	if energy < amount:
		return false
	energy -= amount
	EventBus.stats_changed.emit()
	return true
