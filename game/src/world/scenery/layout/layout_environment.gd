class_name XumenLayoutEnvironment
extends Node2D
## Existing authored motion follows the campaign clock. No duplicate scenery or collision.
var host: Node2D
var animated: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	host = get_parent()
	while host != null and not "abilities" in host: host = host.get_parent() as Node2D
	if host == null: return
	for node: Node in host.find_children("*","Node",true,false):
		if node != self and (node is ChapterPinnedBitmap or node is ChapterFishGroup or node is EnvironmentBubbleEmitter or node is WhalebellyBaleenFrames or node is KitDriftField or node is WhalebellySoftUnderwaterLight or node is XumenBackgroundCurrent):
			animated.append(node)

func _process(_delta: float) -> void:
	if not is_instance_valid(host): return
	var active: bool = not host.reference_visible and host.capture_path.is_empty()
	for node: Node in animated:
		if is_instance_valid(node) and active: node.update_at(host.clock)
