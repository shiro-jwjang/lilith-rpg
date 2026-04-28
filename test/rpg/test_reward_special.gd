extends "res://test/rpg/test_base.gd"

const REWARD_GENERATOR_PATH := "res://scripts/rpg/rewards/reward_generator.gd"
const REWARD_MANAGER_PATH := "res://scripts/rpg/rewards/reward_manager.gd"
const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"


func test_reward_010_treasure_node_guarantees_one_relic() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	for _index in range(100):
		var rewards: Dictionary = generator.generate_treasure_rewards()
		var relics: Array = rewards.get("relics", [])
		assert_ge(relics.size(), 1, "reward-010 expected at least one treasure reward")
		assert_eq(relics.size(), 1, "reward-010 expected exactly one treasure relic")


func test_reward_013_empty_reward_returns_bug_empty_reward_error() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var inventory = _make_inventory()
	if inventory == null:
		return

	var result: Dictionary = manager.grant_rewards({}, inventory)
	assert_false(bool(result.get("success", true)), "reward-013 expected empty reward grant to fail")
	assert_eq(str(result.get("error", "")), "BUG_EMPTY_REWARD", "reward-013 expected BUG_EMPTY_REWARD")


func test_reward_014_full_inventory_handles_reward_overflow_without_crashing() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4", "장비5", "장비6"],
		"relics": ["유물1", "유물2", "유물3", "유물4"],
		"potions": {"소형 치료 물약": 5},
	})
	if inventory == null:
		return

	var result: Dictionary = manager.grant_rewards({
		"gold": 25,
		"items": [{"category": "normal_equipment", "id": "장비7"}],
		"relics": [{"id": "유물5"}],
	}, inventory)
	assert_true(bool(result.get("success", false)), "reward-014 expected overflow handling to succeed")
	assert_true(bool(result.get("overflow_handled", false)), "reward-014 expected overflow to be marked handled")
	assert_ge(int(result.get("overflow_count", 0)), 1, "reward-014 expected at least one overflowed reward")


func test_reward_017_boss_battle_calls_unlock_check_exactly_once() -> void:
	var unlock_tracker = _UnlockTracker.new()
	var generator = _make_generator({
		"unlock_tracker": unlock_tracker,
	})
	if generator == null:
		return

	var rewards: Dictionary = generator.generate_rewards("boss")
	assert_eq(unlock_tracker.call_count, 1, "reward-017 expected boss unlock check exactly once")
	assert_eq((rewards.get("relics", []) as Array).size(), 1, "reward-017 expected boss relic reward to still be present")


func _make_generator(config: Dictionary = {}):
	var script = load(REWARD_GENERATOR_PATH)
	assert_not_null(script, "expected reward_generator.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _make_manager(config: Dictionary = {}):
	var script = load(REWARD_MANAGER_PATH)
	assert_not_null(script, "expected reward_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)


class _UnlockTracker extends RefCounted:
	var call_count := 0

	func perform_unlock_check() -> void:
		call_count += 1
