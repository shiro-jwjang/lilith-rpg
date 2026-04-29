extends "res://test/rpg/test_base.gd"

var runner = null


func _setup_runner() -> void:
	runner = preload("res://scripts/rpg/game_runner.gd").new()
	runner.start_run()


func test_skill_damage_basic_attack() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	var hp_before := int(enemy.current_hp)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_true(bool(result.get("ok", false)), "basic attack should succeed")
	assert_has(result, "damage", "result should have damage key")
	assert_true(int(enemy.current_hp) < hp_before, "enemy HP should decrease")
	assert_eq(String(result.get("effect_type", "")), "damage", "effect_type should be damage")


func test_skill_damage_heavy_strike() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_advance_to_specific_ally_turn("리나")
	var basic_result: Dictionary = runner.player_attack(0)
	var basic_damage := int(basic_result.get("damage", 0))

	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_advance_to_specific_ally_turn("리나")
	var heavy_result: Dictionary = runner.player_attack(1)
	var heavy_damage := int(heavy_result.get("damage", 0))

	assert_true(bool(heavy_result.get("ok", false)), "heavy strike should succeed")
	assert_true(heavy_damage > basic_damage, "heavy strike should deal more damage than basic attack")


func test_skill_damage_returns_target_info() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_has(result, "target_name", "result should have target_name")
	assert_eq(String(result.get("target_name", "")), String(enemy.name), "target_name should match enemy name")


func test_skill_heal_restores_hp() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	var ally = runner.battle_manager.allies[0]
	ally.take_damage(30)
	runner._sync_party_from_battle()
	var hp_before := int(ally.current_hp)
	_advance_to_specific_ally_turn("세리아")
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "heal should succeed")
	assert_true(int(ally.current_hp) > hp_before, "heal should restore ally HP")
	assert_eq(String(result.get("effect_type", "")), "heal", "effect_type should be heal")


func test_skill_heal_caps_at_max_hp() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	var ally = runner.battle_manager.allies[0]
	var max_hp := int(ally.max_hp)
	_advance_to_specific_ally_turn("세리아")
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "heal at full HP should still resolve")
	assert_eq(int(ally.current_hp), max_hp, "heal should not exceed max HP")
	assert_eq(int(result.get("heal_amount", -1)), 0, "heal amount should be zero at full HP")


func test_skill_heal_returns_heal_amount() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	var ally = runner.battle_manager.allies[0]
	ally.take_damage(25)
	runner._sync_party_from_battle()
	_advance_to_specific_ally_turn("세리아")
	var result: Dictionary = runner.player_attack(2)
	assert_has(result, "heal_amount", "heal result should include heal_amount")
	assert_true(int(result.get("heal_amount", 0)) > 0, "heal_amount should be positive when HP is missing")
	assert_eq(String(result.get("target_name", "")), String(ally.name), "heal should report the healed ally")


func test_skill_def_boost_increases_defense() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	var guardian = runner.battle_manager.allies[1]
	var def_before := int(guardian.def)
	_advance_to_specific_ally_turn("카이")
	var result: Dictionary = runner.player_attack(1)
	assert_true(bool(result.get("ok", false)), "defense stance should succeed")
	assert_true(int(guardian.def) > def_before, "defense stance should increase defense")


func test_skill_def_boost_returns_effect_info() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_advance_to_specific_ally_turn("카이")
	var result: Dictionary = runner.player_attack(1)
	assert_eq(String(result.get("effect_type", "")), "buff", "defense stance should return buff effect type")
	assert_eq(String(result.get("buff_type", "")), "def_boost", "defense stance should identify its buff")
	assert_eq(String(result.get("target_name", "")), "카이", "defense stance should target the guardian")


func test_skill_taunt_targets_all_enemies() -> void:
	_setup_runner()
	_enter_multi_enemy_combat(["녹슨 검병", "붉은 사냥견"])
	var enemy_hps: Array = []
	for enemy in runner.battle_manager.enemies:
		enemy_hps.append(int(enemy.current_hp))
	_advance_to_specific_ally_turn("카이")
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "taunt should succeed")
	assert_eq(String(result.get("effect_type", "")), "taunt", "taunt should return taunt effect type")
	assert_eq(String(result.get("target_name", "")), "전체 적", "taunt should report all enemies as the target")
	for index in range(runner.battle_manager.enemies.size()):
		assert_eq(int(runner.battle_manager.enemies[index].current_hp), int(enemy_hps[index]), "taunt should not damage enemies")


func test_player_attack_returns_effect_type() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_has(result, "effect_type", "result should always include effect_type")


func test_heal_max_hp_percent_20() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	var ally = runner.battle_manager.allies[0]
	ally.take_damage(70)
	runner._sync_party_from_battle()
	_advance_to_specific_ally_turn("세리아")
	var result: Dictionary = runner.player_attack(2)
	assert_eq(int(ally.max_hp), 120, "리나 max HP should stay at 120 for percent-heal validation")
	assert_eq(int(result.get("heal_amount", -1)), 24, "heal should restore 20 percent of max HP")
	assert_eq(int(ally.current_hp), 74, "heal should add 24 HP to the injured ally")


func test_heal_skill_does_not_damage_enemies() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	var hp_before := int(enemy.current_hp)
	var ally = runner.battle_manager.allies[0]
	ally.take_damage(30)
	runner._sync_party_from_battle()
	_advance_to_specific_ally_turn("세리아")
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "heal should succeed")
	assert_eq(int(enemy.current_hp), hp_before, "heal should not damage enemies")


func test_def_boost_skill_does_not_damage_enemies() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	var hp_before := int(enemy.current_hp)
	_advance_to_specific_ally_turn("카이")
	var result: Dictionary = runner.player_attack(1)
	assert_true(bool(result.get("ok", false)), "defense stance should succeed")
	assert_eq(int(enemy.current_hp), hp_before, "defense stance should not damage enemies")


func _enter_single_enemy_combat(enemy_name: String):
	var enemy_config: Dictionary = runner.content_data.get_enemy_by_name(enemy_name)
	assert_false(enemy_config.is_empty(), "enemy config should exist for combat setup")
	runner.enter_combat([_normalize_enemy_config(enemy_config)])
	return runner.battle_manager.enemies[0]


func _enter_multi_enemy_combat(enemy_names: Array) -> void:
	var configs: Array = []
	for enemy_name in enemy_names:
		var enemy_config: Dictionary = runner.content_data.get_enemy_by_name(String(enemy_name))
		assert_false(enemy_config.is_empty(), "enemy config should exist for combat setup")
		configs.append(_normalize_enemy_config(enemy_config))
	runner.enter_combat(configs)


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
	assert_true(false, "expected to reach ally turn for %s" % ally_name)



