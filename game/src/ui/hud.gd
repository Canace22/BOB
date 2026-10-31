class_name GameHud
extends CanvasLayer

var remaining: float = 0.0


func _ready() -> void:
	EventBus.stats_changed.connect(refresh)
	EventBus.room_entered.connect(refresh.unbind(1))
	EventBus.flag_set.connect(refresh.unbind(1))
	EventBus.ability_granted.connect(refresh.unbind(1))
	EventBus.toast.connect(notify)
	refresh()


func refresh() -> void:
	$Top/Stats.text = "生命 %d / %d    蓄振 %d / %d    %s" % [GameState.hp, GameState.MAX_HP, GameState.energy, GameState.MAX_ENERGY, "贴流冲 ✓" if GameState.has_ability("ability.dash") else "贴流冲 · 未获得"]
	$Top/Room.text = "%s · %s" % [GameState.current_room, WorldGraph.ROOMS.get(GameState.current_room, "")]
	var goal := "寻找并击败负壳蟹"
	if GameState.has_flag("complete.r1"):
		goal = "首关已完成 · 可返回探索"
	elif GameState.has_ability("ability.dash"):
		goal = "前往流膜育窝 · 跳跃后按 Shift 跨沟"
	elif GameState.has_flag("boss.r1_shell_crab"):
		goal = "到负壳蟹房右岸 · 按 E 承接贴流冲"
	$Top/Goal.text = goal


func notify(message: String) -> void:
	$Message.text = message
	remaining = 4.0


func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	$Message.visible = remaining > 0
	var boss := get_tree().get_nodes_in_group("enemy").filter(func(node: Node) -> bool: return (node as EnemyBase).boss and (node as EnemyBase).state != "dead")
	$Boss.visible = GameState.arena_active and not boss.is_empty()
	if $Boss.visible:
		var enemy := boss[0] as EnemyBase
		$Boss.text = "负壳蟹    %d / %d    %s" % [enemy.health.current, enemy.health.maximum, {"tell": "蓄力预告", "active": "攻击", "recover": "恢复空档"}.get(enemy.state, "接近中")]
