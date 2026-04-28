extends "res://test/rpg/e2e_support.gd"


func test_e2e_004_bleed_enemy_applies_status_and_dot_damage_in_full_battle() -> void:
	var content = _content()
	if content == null:
		return
	var enemy_data: Dictionary = content.get_enemy_by_name("붉은 사냥견")
	var summary: Dictionary = _run_battle(_build_allies_from_player(_make_player({"hp": 100.0})), [_enemy_config(enemy_data, 401)])
	if summary.is_empty():
		return

	assert_eq(String(summary.get("winner", "")), "victory", "e2e-004 expected bleed battle victory")
	assert_gt(int(summary.get("status_applied_count", 0)), 0, "e2e-004 expected bleed to be applied")
	assert_true(bool(summary.get("dot_observed", false)), "e2e-004 expected bleed tick damage to be observed")
	assert_true(int(summary.get("hp_after_dot", 9999)) < int(summary.get("hp_after_direct_hit", 9999)), "e2e-004 expected bleed DOT after direct hit")


func test_e2e_005_burn_enemy_applies_status_and_dot_damage_in_full_battle() -> void:
	var content = _content()
	if content == null:
		return
	var enemy_data: Dictionary = content.get_enemy_by_name("그을린 궁수")
	var summary: Dictionary = _run_battle(_build_allies_from_player(_make_player({"hp": 100.0})), [_enemy_config(enemy_data, 402)])
	if summary.is_empty():
		return

	assert_eq(String(summary.get("winner", "")), "victory", "e2e-005 expected burn battle victory")
	assert_gt(int(summary.get("status_applied_count", 0)), 0, "e2e-005 expected burn to be applied")
	assert_true(bool(summary.get("dot_observed", false)), "e2e-005 expected burn tick damage to be observed")
	assert_true(int(summary.get("hp_after_dot", 9999)) < int(summary.get("hp_after_direct_hit", 9999)), "e2e-005 expected burn DOT after direct hit")
