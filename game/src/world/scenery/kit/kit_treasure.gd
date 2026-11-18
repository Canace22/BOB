class_name KitTreasure
extends KitInteractable
## A permanent collectible inside registered shell art; the shell stays after pickup.
var host: WhalebellyMain

func _ready() -> void:
	super._ready()
	var candidate: Node = get_parent()
	while candidate != null:
		if candidate is WhalebellyMain:
			host = candidate
			break
		candidate = candidate.get_parent()
	refresh_art()

func _process(_delta: float) -> void:
	refresh_art()

func refresh_art() -> void:
	var loot: CanvasItem = get_node_or_null("Loot") as CanvasItem
	if loot != null and is_instance_valid(host):
		loot.visible = not host.collected.get(interaction_id, false)

func nearby(level: Node2D) -> bool:
	return super.nearby(level) and not level.collected.get(interaction_id, false)

func interact(level: Node2D) -> bool:
	if not nearby(level) or not CampaignRelics.ITEMS.has(interaction_id): return false
	level.collected[interaction_id] = true
	level.relics.refill(level.collected)
	level.health = level.player.max_health
	level.player.health = level.health
	level.player.soul = level.player.max_soul
	level.player.stats_changed.emit(level.player.health, level.player.soul)
	level.sfx("collect")
	level.record_event("reward", {"room":str(level.room.id), "id":interaction_id})
	refresh_art()
	level.save_progress(false)
	if level.last_save_ok:
		level.notify("获得%s · 护盾上限 +%d，生命与蓄振已恢复" % [CampaignRelics.reward_name(interaction_id), int(CampaignRelics.ITEMS[interaction_id].charges)])
	return true
