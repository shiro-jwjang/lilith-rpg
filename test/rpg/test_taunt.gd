extends "res://test/rpg/test_base.gd"

var runner = null


func before() -> void:
	runner = preload("res://scripts/rpg/game_runner.gd").new()
	runner.start_run()


func _setup_runner() -> void:
	runner = preload("res://scripts/rpg/game_runner.gd").new()
	runner.start_run()


func test_unit_has_taunt_turns_field() -> void:
	"""Unit은 taunt_turns 필드를 가진다"""
	var unit = preload("res://scripts/rpg/combat/unit.gd").new({"name": "테스트", "max_hp": 100})
	var has_taunt_turns := _unit_has_property(unit, "taunt_turns")
	assert_true(has_taunt_turns, "Unit should have taunt_turns field")
	if has_taunt_turns:
		assert_eq(int(unit.get("taunt_turns")), 0, "taunt_turns should default to 0")


func test_unit_apply_taunt_sets_turns() -> void:
	"""apply_taunt은 taunt_turns를 설정한다"""
	var unit = preload("res://scripts/rpg/combat/unit.gd").new({"name": "테스트", "max_hp": 100})
	assert_true(unit.has_method("apply_taunt"), "Unit should implement apply_taunt")
	if unit.has_method("apply_taunt") and _unit_has_property(unit, "taunt_turns"):
		unit.apply_taunt(1)
		assert_eq(int(unit.get("taunt_turns")), 1, "taunt_turns should be 1 after apply_taunt(1)")


func test_unit_apply_taunt_refreshes_duration() -> void:
	"""도발 재적용은 지속시간만 갱신한다 (중첩하지 않음)"""
	var unit = preload("res://scripts/rpg/combat/unit.gd").new({"name": "테스트", "max_hp": 100})
	assert_true(unit.has_method("apply_taunt"), "Unit should implement apply_taunt")
	if unit.has_method("apply_taunt") and _unit_has_property(unit, "taunt_turns"):
		unit.apply_taunt(1)
		unit.apply_taunt(1)
		assert_eq(int(unit.get("taunt_turns")), 1, "reapplying taunt should refresh to 1, not stack")


func test_unit_decrement_taunt() -> void:
	"""decrement_taunt은 taunt_turns를 1 감소시킨다"""
	var unit = preload("res://scripts/rpg/combat/unit.gd").new({"name": "테스트", "max_hp": 100})
	assert_true(unit.has_method("apply_taunt"), "Unit should implement apply_taunt")
	assert_true(unit.has_method("decrement_taunt"), "Unit should implement decrement_taunt")
	if unit.has_method("apply_taunt") and unit.has_method("decrement_taunt") and _unit_has_property(unit, "taunt_turns"):
		unit.apply_taunt(2)
		unit.decrement_taunt()
		assert_eq(int(unit.get("taunt_turns")), 1, "taunt_turns should decrement by 1")


func test_unit_is_taunting() -> void:
	"""is_taunting은 taunt_turns > 0일 때 true를 반환한다"""
	var unit = preload("res://scripts/rpg/combat/unit.gd").new({"name": "테스트", "max_hp": 100})
	assert_true(unit.has_method("is_taunting"), "Unit should implement is_taunting")
	assert_true(unit.has_method("apply_taunt"), "Unit should implement apply_taunt")
	assert_true(unit.has_method("decrement_taunt"), "Unit should implement decrement_taunt")
	if unit.has_method("is_taunting") and unit.has_method("apply_taunt") and unit.has_method("decrement_taunt"):
		assert_false(bool(unit.is_taunting()), "should not be taunting initially")
		unit.apply_taunt(1)
		assert_true(bool(unit.is_taunting()), "should be taunting after apply_taunt")
		unit.decrement_taunt()
		assert_false(bool(unit.is_taunting()), "should not be taunting after decrement to 0")


func test_player_attack_taunt_returns_effect_type() -> void:
	"""도발 스킬 사용 시 effect_type이 taunt로 반환된다"""
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order_for_taunt_window()
	_advance_to_specific_ally_turn("카이")
	var guardian = runner.battle_manager.allies[1]
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "taunt should succeed")
	assert_eq(String(result.get("effect_type", "")), "taunt", "effect_type should be taunt")
	assert_true(_unit_has_property(guardian, "taunt_turns"), "guardian should expose taunt_turns")
	if _unit_has_property(guardian, "taunt_turns"):
		assert_eq(int(guardian.get("taunt_turns")), 1, "guardian should still be taunting until the next ally turn starts")


func test_player_attack_taunt_consumes_mp() -> void:
	"""도발은 MP를 소모한다"""
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order_for_taunt_window()
	_advance_to_specific_ally_turn("카이")
	var guardian = runner.battle_manager.allies[1]
	var mp_before := int(guardian.current_mp)
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "taunt should succeed")
	assert_eq(int(guardian.current_mp), mp_before - 5, "taunt should consume 5 MP")


func test_player_attack_taunt_sets_taunt_on_self() -> void:
	"""도발은 자신에게 taunt 상태를 부여한다"""
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order_for_taunt_window()
	_advance_to_specific_ally_turn("카이")
	var guardian = runner.battle_manager.allies[1]
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "taunt should succeed")
	assert_true(guardian.has_method("is_taunting"), "guardian should expose is_taunting")
	if guardian.has_method("is_taunting"):
		assert_true(bool(guardian.is_taunting()), "guardian should gain taunt on self")


func test_enemy_targets_taunting_ally_first() -> void:
	"""도발 중인 아군이 있으면 적은 도발 대상을 최우선으로 공격한다"""
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order_for_taunt_window()
	_advance_to_specific_ally_turn("카이")
	var guardian = runner.battle_manager.allies[1]
	var result: Dictionary = runner.player_attack(2)
	var follow_up: Dictionary = result.get("next_turn", {})
	var auto_action: Dictionary = follow_up.get("auto_action", {})
	assert_true(bool(result.get("ok", false)), "taunt should succeed")
	assert_false(auto_action.is_empty(), "taunt follow-up should include an enemy action")
	assert_eq(int(auto_action.get("target_internal_id", -1)), int(guardian.internal_id), "enemy should target the taunting guardian")


func test_enemy_targets_lowest_hp_when_no_taunt() -> void:
	"""도발이 없으면 적은 HP 비율이 가장 낮은 아군을 공격한다 (기존 동작 유지)"""
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	var lina = runner.battle_manager.allies[0]
	var guardian = runner.battle_manager.allies[1]
	var seria = runner.battle_manager.allies[2]
	lina.take_damage(10)
	guardian.take_damage(70)
	seria.take_damage(5)
	var auto_action: Dictionary = runner._execute_enemy_turn(enemy)
	assert_true(bool(auto_action.get("ok", false)), "enemy turn should succeed")
	assert_eq(int(auto_action.get("target_internal_id", -1)), int(guardian.internal_id), "enemy should target the ally with the lowest HP ratio when no taunt is active")


func test_taunt_expires_after_one_turn() -> void:
	"""도발은 1턴 후 만료된다"""
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order_for_taunt_window()
	_advance_to_specific_ally_turn("카이")
	var guardian = runner.battle_manager.allies[1]
	var result: Dictionary = runner.player_attack(2)
	assert_true(_unit_has_property(guardian, "taunt_turns"), "guardian should expose taunt_turns")
	if _unit_has_property(guardian, "taunt_turns"):
		assert_eq(int(guardian.get("taunt_turns")), 1, "taunt should remain active through the enemy response")
	var next_turn_result: Dictionary = runner.next_turn()
	assert_true(bool(next_turn_result.get("unit", null).is_ally), "taunt should expire when the next ally turn starts")
	if _unit_has_property(guardian, "taunt_turns"):
		assert_eq(int(guardian.get("taunt_turns")), 0, "taunt should expire on the next ally turn")


func test_taunt_refresh_on_reapply() -> void:
	"""도발을 연속 사용하면 지속시간이 갱신된다"""
	_setup_runner()
	_enter_single_enemy_combat("녹슨 검병")
	_configure_turn_order_for_taunt_window()
	_advance_to_specific_ally_turn("카이")
	var guardian = runner.battle_manager.allies[1]
	assert_true(guardian.has_method("apply_taunt"), "guardian should expose apply_taunt")
	if guardian.has_method("apply_taunt"):
		guardian.apply_taunt(1)
	var result: Dictionary = runner.player_attack(2)
	assert_true(bool(result.get("ok", false)), "taunt should succeed while already taunting")
	assert_true(_unit_has_property(guardian, "taunt_turns"), "guardian should expose taunt_turns")
	if _unit_has_property(guardian, "taunt_turns"):
		assert_eq(int(guardian.get("taunt_turns")), 1, "reapplying taunt should refresh to 1 instead of stacking")


func test_last_taunter_is_priority_when_multiple_taunt() -> void:
	"""다수 아군이 도발 시 마지막 도발자가 우선 타겟"""
	_setup_runner()
	var enemy = _enter_single_enemy_combat("녹슨 검병")
	var lina = runner.battle_manager.allies[0]
	var guardian = runner.battle_manager.allies[1]
	assert_true(lina.has_method("apply_taunt"), "allies should expose apply_taunt")
	assert_true(guardian.has_method("apply_taunt"), "allies should expose apply_taunt")
	if lina.has_method("apply_taunt") and guardian.has_method("apply_taunt"):
		lina.apply_taunt(1)
		guardian.apply_taunt(1)
	var auto_action: Dictionary = runner._execute_enemy_turn(enemy)
	assert_true(bool(auto_action.get("ok", false)), "enemy turn should succeed with multiple taunters")
	assert_eq(int(auto_action.get("target_internal_id", -1)), int(guardian.internal_id), "enemy should target the last taunting ally")


func _enter_single_enemy_combat(enemy_name: String):
	var enemy_config: Dictionary = runner.content_data.get_enemy_by_name(enemy_name)
	assert_false(enemy_config.is_empty(), "enemy config should exist for combat setup")
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


func _configure_turn_order_for_taunt_window() -> void:
	var lina = runner.battle_manager.allies[0]
	var guardian = runner.battle_manager.allies[1]
	var seria = runner.battle_manager.allies[2]
	var enemy = runner.battle_manager.enemies[0]
	lina.speed = 18
	guardian.speed = 14
	enemy.speed = 12
	seria.speed = 10


func _normalize_enemy_config(enemy: Dictionary) -> Dictionary:
	var max_hp := int(enemy.get("max_hp", enemy.get("hp", 0)))
	return {
		"name": String(enemy.get("name", "")),
		"max_hp": max_hp,
		"current_hp": max_hp,
		"max_mp": int(enemy.get("max_mp", enemy.get("mp", 0))),
		"current_mp": int(enemy.get("max_mp", enemy.get("mp", 0))),
		"atk": int(enemy.get("atk", enemy.get("attack", 0))),
		"def": int(enemy.get("def", enemy.get("defense", 0))),
		"speed": int(enemy.get("speed", 0)),
		"tier": String(enemy.get("tier", "normal")),
		"phases": int(enemy.get("phases", 1)),
		"phase_transition_hp": int(enemy.get("phase_transition_hp", 0)),
		"skills": (enemy.get("skills", []) as Array).duplicate(true),
		"status_effects": {"enemy_status_names": (enemy.get("status_effects", []) as Array).duplicate(true)},
	}


func _unit_has_property(unit, property_name: String) -> bool:
	for property_info in unit.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false
