extends "res://test/rpg/test_base.gd"

const RELIC_MANAGER_PATH := "res://scripts/rpg/relics/relic_manager.gd"


func test_relic_001_add_relic_succeeds_when_inventory_has_space() -> void:
	var manager = _make_manager(["유물1", "유물2"])
	if manager == null:
		return
	var result = manager.add_relic("붉은 달의 파편")
	assert_true(result["success"], "relic-001 expected relic add success")
	assert_eq(manager.get_relic_count(), 3, "relic-001 expected relic count 3")


func test_relic_002_add_relic_succeeds_at_three_of_four_capacity() -> void:
	var manager = _make_manager(["유물1", "유물2", "유물3"])
	if manager == null:
		return
	var result = manager.add_relic("녹슨 방패편")
	assert_true(result["success"], "relic-002 expected relic add success at three of four")
	assert_eq(manager.get_relic_count(), 4, "relic-002 expected relic count 4")


func test_relic_003_add_relic_fails_when_inventory_is_full() -> void:
	var manager = _make_manager(["유물1", "유물2", "유물3", "유물4"])
	if manager == null:
		return
	var result = manager.add_relic("사냥개의 이빨")
	assert_false(result["success"], "relic-003 expected relic add failure at capacity 4")
	assert_true(result["discarded"], "relic-003 expected relic to be discarded")
	assert_eq(manager.get_relic_count(), 4, "relic-003 expected relic count to stay 4")


func test_relic_004_add_relic_fails_for_duplicate_relic() -> void:
	var manager = _make_manager(["붉은 달의 파편", "유물2"])
	if manager == null:
		return
	var result = manager.add_relic("붉은 달의 파편")
	assert_false(result["success"], "relic-004 expected duplicate relic add failure")
	assert_eq(result["reason"], "already_owned", "relic-004 expected duplicate reason already_owned")
	assert_eq(manager.get_relic_count(), 2, "relic-004 expected relic count to stay 2")


func _make_manager(relic_ids: Array = []):
	var script = load(RELIC_MANAGER_PATH)
	assert_not_null(script, "expected relic_manager.gd to exist")
	if script == null:
		return null
	return script.new({"relics": relic_ids})
