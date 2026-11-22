class_name ChapterPressureArena
extends Node2D
## 专项夹具：实际章节角色、敌人执行器和1280平地；不加载或写入用户存档。
var profile_index: int=2
var challenge: bool=true
var player: ChapterTwoPlayer
var enemy: EnemyLabEnemy
var owned_actions: Array[StringName]=[]

func _init(index: int=2, enabled: bool=true) -> void:
	profile_index=index
	challenge=enabled

func _ready() -> void:
	# 与正式输入入口使用同一组action；角色setup负责实际键位，夹具只补缺失名称。
	var bindings: Dictionary=TideCombatInput.BASE.merged(TideCombatInput.MODS)
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			owned_actions.append(StringName(action))
	for rect: Rect2 in [Rect2(0,520,1280,150),Rect2(-30,-100,30,800),Rect2(1280,-100,30,800)]:
		var floor_body:=StaticBody2D.new()
		var collision:=CollisionShape2D.new()
		var shape:=RectangleShape2D.new()
		shape.size=rect.size
		collision.shape=shape
		floor_body.position=rect.get_center()
		floor_body.add_child(collision)
		add_child(floor_body)
	var actor: Node=preload("res://content/whalebelly/Player.tscn").instantiate()
	actor.set_script(preload("res://src/prototypes/chapter_two/player.gd"))
	player=actor as ChapterTwoPlayer
	player.position=Vector2(420,520)
	add_child(player)
	player.collision_mask=5
	match profile_index:
		3: enemy=EnemyLabPredator.new()
		4: enemy=EnemyLabEel.new()
		5: enemy=EnemyLabWarden.new()
		6: enemy=EnemyLabBeamGuard.new()
		7: enemy=ChapterRunElder.new()
		_: enemy=EnemyLabEnemy.new()
	enemy.profile=EnemyLabCatalog.profile(profile_index)
	if challenge: enemy.profile=ChapterCombatPressure.apply(enemy.profile)
	enemy.player=player
	enemy.position=Vector2(855,520)
	enemy.show_ranges=false
	enemy.auto_attack=false
	add_child(enemy)

func shutdown() -> void:
	# 必须在remove_child/queue_free以前执行；子角色离树后pad与命中反馈已解除树关联。
	if is_instance_valid(player) and player.is_inside_tree():
		player.clear_combat_input()
		player.clear_projectiles()

func _exit_tree() -> void:
	# 子角色已经离树，此处仅还原夹具新建的action，不能再调用角色清理入口。
	for action: StringName in owned_actions:
		if InputMap.has_action(action): InputMap.erase_action(action)
