class_name PlayerTuning
extends Resource
## Values migrated from first-level; units are pixels and seconds (64 px/U).

@export var move_speed: float = 204.8
@export var gravity: float = 1000.0
@export var terminal_speed: float = 850.0
@export var jump_speed: float = 460.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export var dash_duration: float = 0.22
@export var dash_distance: float = 166.4
@export var dash_cooldown: float = 0.8
@export var heal_duration: float = 1.1
@export var invulnerability: float = 1.0

@export_group("Prototype controls")
@export var prototype_controls: bool = false
@export_range(0.05, 0.25) var action_buffer: float = 0.15
@export_range(0.1, 1.0) var jump_cut_ratio: float = 0.45
