extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")


class _FixedRng extends RefCounted:
	var _value: float = 0.0

	func _init(value: float) -> void:
		_value = value

	func randf() -> float:
		return _value

	func randi_range(from_value: int, _to_value: int) -> int:
		return from_value


var runner = null


func _setup_runner() -> void:
	runner = GAME_RUNNER_SCRIPT.new({"rng": _FixedRng.new(0.0)})
	runner.start_run()


func _enter_single_enemy_combat(enemy_name: String):
	var enemy_config: Dictionary = runner.content_data.get_enemy_by_name(enemy_name)
	assert_false(enemy_config.is_empty(), "enemy config should exist")
	runner.enter_combat([_normalize_enemy_config(enemy_config)])
	return runner.battle_manager.enemies[0]


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


func _configure_turn_order(ally1_speed: int, ally2_speed: int, ally3_speed: int, enemy_speed: int) -> void:
	if runner.battle_manager.allies.size() >= 3:
		runner.battle_manager.allies[0].speed = ally1_speed
		runner.battle_manager.allies[1].speed = ally2_speed
		runner.battle_manager.allies[2].speed = ally3_speed
	if runner.battle_manager.enemies.size() >= 1:
		runner.battle_manager.enemies[0].speed = enemy_speed


func test_player_attack_damage_returns_status_structure() -> void:
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order(18, 14, 10, 12)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_true(bool(result.get("ok", false)), "basic attack should succeed")
	assert_true(result.has("statuses_applied"), "damage result should include statuses_applied")
	assert_true(result.has("statuses_missed"), "damage result should include statuses_missed")
	assert_true(result["statuses_applied"] is Array, "statuses_applied should be an array")
	assert_true(result["statuses_missed"] is Array, "statuses_missed should be an array")


func test_basic_attack_applies_no_status() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order(18, 14, 10, 12)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(0)
	assert_true(bool(result.get("ok", false)), "basic attack should succeed")
	assert_eq((result.get("statuses_applied", []) as Array).size(), 0, "basic attack should not apply status")
	assert_false(enemy.has_status("출혈"), "basic attack should not add bleed")
	assert_false(enemy.has_status("화상"), "basic attack should not add burn")


func test_charge_slash_applies_bleed_with_deterministic_rng() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order(18, 14, 10, 12)
	_advance_to_specific_ally_turn("리나")
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "charge slash should succeed")
	assert_has(result.get("statuses_applied", []), "출혈", "charge slash should apply bleed")
	assert_true(enemy.has_status("출혈"), "enemy should keep bleed after application")


func test_bleed_ticks_damage_in_combat() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order(8, 7, 6, 20)
	enemy.apply_status("출혈", 2, 3)
	var hp_before := int(enemy.current_hp)
	var turn_result: Dictionary = runner.next_turn()
	var expected_bleed := int(floor(float(enemy.max_hp) * 0.05 * 2.0))
	assert_false(bool(turn_result.get("unit", null).is_ally), "enemy should act first")
	assert_eq(int(enemy.current_hp), hp_before - expected_bleed, "bleed should tick on enemy turn")
	assert_eq(int(turn_result.get("dot_damage", 0)), expected_bleed, "turn result should report bleed dot damage")


func test_burn_ticks_damage_in_combat() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order(8, 7, 6, 20)
	enemy.apply_status("화상", 2, 3)
	var hp_before := int(enemy.current_hp)
	var turn_result: Dictionary = runner.next_turn()
	var expected_burn := int(floor(float(enemy.max_hp) * 0.06 * 2.0))
	assert_false(bool(turn_result.get("unit", null).is_ally), "enemy should act first")
	assert_eq(int(enemy.current_hp), hp_before - expected_burn, "burn should tick on enemy turn")
	assert_eq(int(turn_result.get("dot_damage", 0)), expected_burn, "turn result should report burn dot damage")


func test_status_expires_after_duration_in_combat() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order(8, 7, 6, 20)
	enemy.apply_status("출혈", 1, 1)
	assert_true(enemy.has_status("출혈"), "bleed should exist before the turn")
	runner.next_turn()
	assert_false(enemy.has_status("출혈"), "bleed should expire after one tick")


func test_bleed_stacks_on_reapply_in_combat() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("봉인된 문지기")
	_configure_turn_order(18, 14, 10, 12)
	_advance_to_specific_ally_turn("리나")
	var first_result: Dictionary = runner.player_attack(2)
	assert_true(bool(first_result.get("ok", false)), "first charge slash should succeed")
	_advance_to_specific_ally_turn("리나")
	var second_result: Dictionary = runner.player_attack(2)
	assert_true(bool(second_result.get("ok", false)), "second charge slash should succeed")
	assert_eq(int(enemy.get_status("출혈").get("stacks", 0)), 2, "bleed should stack to 2 on reapply")


func test_bleed_caps_at_max_stacks_in_combat() -> void:
	_setup_runner()
	var enemy = _enter_single_enemy_combat("붉은 달의 파수꾼")
	_configure_turn_order(18, 14, 10, 12)
	runner.battle_manager.allies[0].current_mp = 99
	runner.party[0]["current_mp"] = 99
	for _i in range(4):
		_advance_to_specific_ally_turn("리나")
		var result: Dictionary = runner.player_attack(2)
		assert_true(bool(result.get("ok", false)), "charge slash should succeed while stacking")
	assert_eq(int(enemy.get_status("출혈").get("stacks", 0)), 3, "bleed should cap at 3 stacks")


func test_돌진베기_has_bleed_status() -> void:
	_setup_runner()
	var skill: Dictionary = runner.content_data.get_skill("전위딜러", "돌진베기")
	assert_false(skill.is_empty(), "charge slash skill should exist")
	assert_eq(skill.get("status_effects", []), ["출혈"], "charge slash should define bleed")
	assert_eq(float(skill.get("status_chance", 0.0)), 0.3, "charge slash should define bleed chance")


func test_화염_has_burn_status() -> void:
	_setup_runner()
	var skill: Dictionary = runner.content_data.get_skill("마법지원가", "화염")
	assert_false(skill.is_empty(), "flame skill should exist")
	assert_eq(skill.get("status_effects", []), ["화상"], "flame should define burn")
	assert_eq(float(skill.get("status_chance", 0.0)), 0.35, "flame should define burn chance")


func test_방패타격_has_slow_status() -> void:
	_setup_runner()
	var skill: Dictionary = runner.content_data.get_skill("수호자", "방패타격")
	assert_false(skill.is_empty(), "shield bash skill should exist")
	assert_eq(skill.get("status_effects", []), ["둔화"], "shield bash should define slow")
	assert_eq(float(skill.get("status_chance", 0.0)), 0.4, "shield bash should define slow chance")
