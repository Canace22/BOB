class_name CampaignRelics
extends RefCounted
## Permanent ownership uses existing V6 reward IDs; charges last for this journey.
const ITEMS := {
	"R1-03": {"name":"护潮壳", "charges":2},
	"R1-06": {"name":"厚壳碎片", "charges":1},
}
var charges: int = 0

static func capacity(collected: Dictionary) -> int:
	var total: int = 0
	for id: String in ITEMS:
		if collected.get(id, false): total += int(ITEMS[id].charges)
	return total

static func reward_name(id: String) -> String:
	return str(ITEMS[id].name) if ITEMS.has(id) else "记忆 / 补给"

static func description(id: String) -> String:
	if not ITEMS.has(id): return ""
	return "%s · 护盾上限 +%d\n自动生效，抵挡等量伤害；营地、重试与续档补满。跌落不受保护。" % [ITEMS[id].name, ITEMS[id].charges]

func refill(collected: Dictionary) -> void:
	charges = capacity(collected)

func absorb(amount: int, force: bool) -> int:
	if force or amount <= 0: return amount
	var blocked: int = mini(charges, amount)
	charges -= blocked
	return amount - blocked
