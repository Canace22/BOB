extends TestSuite
## Use the existing isolated actors; these tests cover combat decisions, not saves.

const Fixtures = preload("res://tests/test_story_forager.gd")
var fixtures: Fixtures

func before_each() -> void:
	super.before_each()
	fixtures = Fixtures.new()
	fixtures.tree = tree

func after_each() -> void:
	await fixtures.after_each()
	await super.after_each()

func test_nonlethal_hits_preserve_tell_lunge_and_recovery_deadlines() -> void:
	var target := fixtures._probe()
	var enemy: StoryForager = fixtures._enemy(target)
	enemy.engage()
	enemy.change_state("tell")
	enemy.timer = 0.4
	enemy.take_hit(1)
	eq(enemy.state, "tell", "A visible warning is not cancelled by a poke")
	eq(enemy.timer, 0.4, "Hit does not postpone the committed attack")
	eq(enemy.visual.current_action, &"warn", "Hurt pose does not swallow the warning")
	enemy.timer = 0.56
	enemy._update_behavior(0.01)
	enemy.timer = 0.1
	enemy.take_hit(1)
	eq(enemy.state, "lunge", "Nonlethal damage cannot silently cancel an active rush")
	eq(enemy.visual.current_action, &"lunge", "The active attack keeps its readable pose")
	enemy.reset(false)
	enemy.engage()
	enemy.change_state("recover")
	enemy.timer = 0.5
	enemy.take_hit(1)
	eq(enemy.timer, 0.5, "A successful counter does not restart the recovery timer")
	eq(enemy.visual.current_action, &"hurt", "Safe recovery can show the authored hurt pose")
	enemy.take_hit(1)
	enemy.timer = 0.61
	enemy._update_behavior(0.01)
	eq(enemy.state, "approach", "Repeated J cannot indefinitely pin the recovery state")

func test_active_rush_detects_late_contact_once_and_matches_body_range() -> void:
	var target := fixtures._probe()
	var enemy: StoryForager = fixtures._enemy(target)
	enemy.facing = 1
	enemy.change_state("lunge")
	target.position = enemy.position + Vector2(60, 0)
	enemy.timer = 0.02
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 0, "The initial pose is not an immediate invisible hit")
	target.position.x = enemy.position.x + 85
	enemy.timer = 0.07
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 0, "A target beyond the visible body reach is not hit remotely")
	target.position.x = enemy.position.x + 55
	enemy.timer = 0.18
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 1, "Entering body range later in the rush still registers contact")
	enemy.timer = 0.22
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 1, "Persistent overlap cannot deal repeated damage")
	enemy.change_state("lunge")
	target.position = enemy.position + Vector2(40, -100)
	enemy.timer = 0.12
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 1, "Jumping above the body clears the entire active strike")
	target.position = enemy.position + Vector2(40, 0)
	enemy.timer = 0.25
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 1, "Landing after the active window cannot receive a late hit")

func test_second_rush_retelegraphs_direction_and_then_gives_full_recovery() -> void:
	var target := fixtures._probe()
	var enemy: StoryForager = fixtures._enemy(target)
	enemy.rush_count = 2
	enemy.engage()
	enemy._update_behavior(0.01)
	eq(enemy.state, "tell", "First close approach visibly prepares the first rush")
	eq(enemy.rush_index, 1, "The chain starts on its first rush")
	target.position = enemy.position + Vector2(60, 0)
	enemy.timer = 0.56
	enemy._update_behavior(0.01)
	eq(enemy.facing, -1.0, "Crossing sides during the first tell does not make it track invisibly")
	enemy.timer = 0.29
	enemy._update_behavior(0.01)
	eq(enemy.state, "tell", "Second rush has a separate complete warning")
	eq(enemy.rush_index, 2, "Second warning belongs to rush two")
	eq(enemy.facing, 1.0, "New warning visibly turns to the player's new side")
	eq(enemy.velocity.x, 0.0, "The creature stops moving while it retelegraphs")
	enemy.timer = 0.4
	enemy._update_behavior(0.01)
	eq(enemy.state, "tell", "Second warning leaves a real reaction interval")
	enemy.timer = 0.56
	enemy._update_behavior(0.01)
	eq(enemy.attack_count, 2, "Exactly two committed attacks are observable")
	enemy.timer = 0.29
	enemy._update_behavior(0.01)
	eq(enemy.state, "recover", "Second landing opens the shared counterattack window")
	enemy.timer = 0.59
	enemy._update_behavior(0.01)
	eq(enemy.state, "recover", "Recovery is a full readable opportunity")
	enemy.timer = 0.61
	enemy._update_behavior(0.01)
	eq(enemy.state, "approach", "Completed chain returns to normal approach")

func test_high_platform_allows_observation_without_remote_vertical_damage() -> void:
	var target := fixtures._probe()
	var enemy: StoryForager = fixtures._enemy(target)
	target.position = enemy.position + Vector2(60, -130)
	enemy.engage()
	enemy._update_behavior(0.01)
	eq(enemy.state, "tell", "The high platform lets the player observe a real warning")
	enemy.timer = 0.56
	enemy._update_behavior(0.01)
	eq(enemy.state, "lunge", "The creature demonstrates the rush beneath the platform")
	enemy.timer = 0.12
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 0, "The rush never reaches the high platform vertically")
	eq(enemy.velocity.y, 0.0, "The attack does not leap towards an elevated player")
	enemy.timer = 0.29
	enemy._update_behavior(0.01)
	eq(enemy.state, "recover", "Waiting above reveals the safe descent opportunity")

func test_actual_rush_travels_seventy_to_ninety_pixels() -> void:
	fixtures._floor()
	var target := fixtures._probe()
	var enemy: StoryForager = fixtures._enemy(target)
	await physics_frames(2)
	target.position = Vector2(700, 100)
	enemy.facing = 1
	enemy.rush_index = 1
	enemy.change_state("lunge")
	var origin: float = enemy.position.x
	for tick: int in range(18): enemy._physics_process(1.0 / 60.0)
	var distance: float = enemy.position.x - origin
	check(distance >= 70 and distance <= 90, "The rush moves its body 70–90 pixels instead of applying remote damage")
	eq(enemy.state, "recover", "Measured physical rush ends in a counterattack opportunity")
