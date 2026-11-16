class_name KitDepthMotion
extends Node2D
## One pausable presentation clock, separate from existing progress/current logic.
@export var enabled: bool = true
@export var speed: float = 1.0
@export var unified_ambient: bool = false
var elapsed: float = 0.0
var water: ShaderMaterial
var lights: Array[WhalebellySoftUnderwaterLight] = []
var ambient: Array[Node] = []

func _ready() -> void:
	water=get_parent().get_node("Far/Organs/Art").material as ShaderMaterial
	for node: Node in get_parent().find_children("*","WhalebellySoftUnderwaterLight",true,false): lights.append(node)
	if unified_ambient:
		for type_name: String in ["KitReferenceMotionSprite","KitAmphipodSchool","EnvironmentBubbleEmitter","KitDriftField"]:
			for node: Node in get_parent().find_children("*",type_name,true,false):
				node.set("external_clock",true)
				ambient.append(node)
	update_at(0.0)

func _process(delta: float) -> void:
	if enabled: update_at(elapsed+delta*speed)

func update_at(time: float) -> void:
	elapsed=time
	if water!=null: water.set_shader_parameter("clock",time)
	for light: WhalebellySoftUnderwaterLight in lights: light.update_at(time)
	for node: Node in ambient: node.call("update_at",time)
