extends "res://test/rpg/test_base.gd"

const DAMAGE_CALCULATOR_SCRIPT := preload("res://scripts/rpg/combat/damage_calculator.gd")
const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")

var runner = null


func _setup_runner() -> void:
	runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()


func _enter_combat_with_enemies(enemy_names: Array) -> Array:
	if runner == null:
		_setup_runner()
	var configs: Array = []
	for name in enemy_names:
		var enemy_config: Dictionary = runner.content_data.get_enemy_by_name(String(name))
		if not enemy_config.is_empty():
			configs.append(_normalize_enemy_config(enemy_config))
	runner.enter_combat(configs)
	return runner.battle_manager.enemies


func _advance_to_specific_ally_turn(ally_name: String) -> void:
	for _i in range(30):
		var turn_result: Dictionary = runner.next_turn()
		if turn_result.is_empty():
			continue
		if not bool(turn_result.get("action_allowed", false)):
			continue
		var unit = turn_result.get("unit", null)
		if unit == null:
			continue
		if bool(unit.is_ally) and String(unit.name) == ally_name:
			return
	assert_true(false, "expected ally turn for %s" % ally_name)


func _configure_turn_order(a1: int, a2: int, a3: int, e1: int, e2: int = 0) -> void:
	if runner.battle_manager.allies.size() >= 3:
		runner.battle_manager.allies[0].speed = a1
		runner.battle_manager.allies[1].speed = a2
		runner.battle_manager.allies[2].speed = a3
	if runner.battle_manager.enemies.size() >= 1:
		runner.battle_manager.enemies[0].speed = e1
	if runner.battle_manager.enemies.size() >= 2:
		runner.battle_manager.enemies[1].speed = e2


func test_aoe_hits_all_enemies() -> void:
	_enter_combat_with_enemies(["녹슨 검병", "붉은 사냥견"])
	_configure_turn_order(20, 19, 18, 10, 9)
	_advance_to_specific_ally_turn("리나")
	var enemy1 = runner.battle_manager.enemies[0]
	var enemy2 = runner.battle_manager.enemies[1]
	var hp1_before := int(enemy1.current_hp)
	var hp2_before := int(enemy2.current_hp)
	var result: Dictionary = runner.player_attack(3)
	assert_true(bool(result.get("ok", false)), "aoe attack should succeed")
	assert_eq(String(result.get("target_name", "")), "전체 적", "target_name should be '전체 적'")
	assert_eq(int(result.get("target_count", 0)), 2, "should hit 2 enemies")
	assert_true(int(enemy1.current_hp) < hp1_before, "enemy 1 should take damage")
	assert_true(int(enemy2.current_hp) < hp2_before, "enemy 2 should take damage")


func test_aoe_returns_per_target_results() -> void:
	_enter_combat_with_enemies(["녹슨 검병", "붉은 사냥견"])
	_configure_turn_order(20, 19, 18, 10, 9)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(3)
	assert_true(result.has("target_results"), "result should have target_results")
	var target_results: Array = result.get("target_results", [])
	assert_true(target_results is Array, "target_results should be array")
	assert_eq(target_results.size(), 2, "should have 2 target results")


func test_aoe_uses_aoe_multiplier() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	_configure_turn_order(20, 19, 18, 10)
	_advance_to_specific_ally_turn("리나")
	var enemy_def: int = int(runner.battle_manager.enemies[0].def)
	var attacker_atk: int = int(runner.battle_manager.allies[0].atk)
	var expected_damage: int = max(1, int(floor(float(attacker_atk) * 0.7)) - enemy_def)
	var result: Dictionary = runner.player_attack(3)
	var target_results: Array = result.get("target_results", [])
	assert_true(target_results.size() >= 1, "should have target results")
	if target_results.size() >= 1:
		assert_eq(int(target_results[0].get("damage", 0)), expected_damage, "aoe damage should use 0.7 multiplier")


func test_single_target_still_works() -> void:
	_enter_combat_with_enemies(["녹슨 검병", "붉은 사냥견"])
	_configure_turn_order(20, 19, 18, 10, 9)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_true(bool(result.get("ok", false)), "single target attack should succeed")
	assert_ne(String(result.get("target_name", "")), "전체 적", "single target should not say '전체 적'")


func test_crit_rate_field_on_ally() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	var lina = runner.battle_manager.allies[0]
	assert_true(float(lina.crit_rate) >= 0.0, "crit_rate should be non-negative")


func test_damage_result_includes_is_critical() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	_configure_turn_order(20, 19, 18, 10)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_true(result.has("is_critical"), "result should include is_critical")
	var is_critical = result.get("is_critical", null)
	assert_true(is_critical is bool, "is_critical should be bool")


func test_aoe_target_results_include_is_critical() -> void:
	_enter_combat_with_enemies(["녹슨 검병", "붉은 사냥견"])
	_configure_turn_order(20, 19, 18, 10, 9)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(3)
	var target_results: Array = result.get("target_results", [])
	assert_true(target_results.size() >= 1, "should have target results")
	if target_results.size() >= 1:
		assert_true(target_results[0].has("is_critical"), "each target result should have is_critical")


func test_crit_damage_is_higher_than_non_crit() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	_configure_turn_order(20, 19, 18, 10)
	_advance_to_specific_ally_turn("리나")
	var attacker = runner.battle_manager.allies[0]
	attacker.crit_rate = 1.0
	var target = runner.battle_manager.enemies[0]
	var non_crit := DAMAGE_CALCULATOR_SCRIPT.calculate_base_damage(attacker.atk, 1.0, target.def)
	var crit := DAMAGE_CALCULATOR_SCRIPT.apply_critical(non_crit, true)
	assert_gt(crit, non_crit, "crit damage should be higher than non-crit")
	var result: Dictionary = runner.player_attack(0)
	assert_eq(int(result.get("damage", 0)), crit, "with 100% crit rate, damage should match crit formula")
	assert_true(bool(result.get("is_critical", false)), "100% crit rate should produce critical hit")


func test_전위딜러_has_10_percent_crit() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	var front = runner.battle_manager.allies[0]
	assert_eq(float(front.crit_rate), 0.10, "전위딜러 crit_rate should be 0.10")


func test_수호자_has_5_percent_crit() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	var guardian = runner.battle_manager.allies[1]
	assert_eq(float(guardian.crit_rate), 0.05, "수호자 crit_rate should be 0.05")


func test_마법지원가_has_8_percent_crit() -> void:
	_enter_combat_with_enemies(["녹슨 검병"])
	var support = runner.battle_manager.allies[2]
	assert_eq(float(support.crit_rate), 0.08, "마법지원가 crit_rate should be 0.08")
