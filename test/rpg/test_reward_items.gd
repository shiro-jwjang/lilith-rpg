extends "res://test/rpg/test_base.gd"

const REWARD_GENERATOR_PATH := "res://scripts/rpg/rewards/reward_generator.gd"


func test_reward_002_normal_battle_guarantees_exactly_one_item_with_normal_equipment_rate() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	var normal_equipment_hits := 0
	for _index in range(10000):
		var rewards: Dictionary = generator.generate_rewards("normal")
		var items: Array = rewards.get("items", [])
		assert_eq(items.size(), 1, "reward-002 expected exactly one normal battle item reward")
		if items.size() == 1 and items[0].get("category", "") == "normal_equipment":
			normal_equipment_hits += 1

	var rate := float(normal_equipment_hits) / 10000.0
	assert_ge(rate, 0.37, "reward-002 expected normal equipment rate >= 0.37")
	assert_true(rate <= 0.43, "reward-002 expected normal equipment rate <= 0.43")


func test_reward_003_normal_battle_potion_rate_matches_spec() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	var potion_hits := 0
	for _index in range(10000):
		var rewards: Dictionary = generator.generate_rewards("normal")
		var items: Array = rewards.get("items", [])
		assert_eq(items.size(), 1, "reward-003 expected exactly one normal battle item reward")
		if items.size() == 1 and items[0].get("category", "") == "potion":
			potion_hits += 1

	var rate := float(potion_hits) / 10000.0
	assert_ge(rate, 0.57, "reward-003 expected potion rate >= 0.57")
	assert_true(rate <= 0.63, "reward-003 expected potion rate <= 0.63")


func test_reward_005_elite_battle_item_rates_match_spec() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	var counts := {
		"high_equipment": 0,
		"relic_candidate": 0,
		"rare_equipment": 0,
	}

	for _index in range(10000):
		var rewards: Dictionary = generator.generate_rewards("elite")
		var items: Array = rewards.get("items", [])
		assert_eq(items.size(), 1, "reward-005 expected exactly one elite battle item reward")
		if items.size() == 1:
			var category := str(items[0].get("category", ""))
			if counts.has(category):
				counts[category] = int(counts[category]) + 1

	var high_rate := float(counts["high_equipment"]) / 10000.0
	var relic_candidate_rate := float(counts["relic_candidate"]) / 10000.0
	var rare_rate := float(counts["rare_equipment"]) / 10000.0
	assert_ge(high_rate, 0.47, "reward-005 expected high equipment rate >= 0.47")
	assert_true(high_rate <= 0.53, "reward-005 expected high equipment rate <= 0.53")
	assert_ge(relic_candidate_rate, 0.27, "reward-005 expected relic candidate rate >= 0.27")
	assert_true(relic_candidate_rate <= 0.33, "reward-005 expected relic candidate rate <= 0.33")
	assert_ge(rare_rate, 0.17, "reward-005 expected rare equipment rate >= 0.17")
	assert_true(rare_rate <= 0.23, "reward-005 expected rare equipment rate <= 0.23")


func test_reward_007_unique_battle_item_rates_match_spec() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	var counts := {
		"high_equipment": 0,
		"relic_candidate": 0,
		"rare_equipment": 0,
	}

	for _index in range(10000):
		var rewards: Dictionary = generator.generate_rewards("unique")
		var items: Array = rewards.get("items", [])
		assert_eq(items.size(), 1, "reward-007 expected exactly one unique battle item reward")
		if items.size() == 1:
			var category := str(items[0].get("category", ""))
			if counts.has(category):
				counts[category] = int(counts[category]) + 1

	var high_rate := float(counts["high_equipment"]) / 10000.0
	var relic_candidate_rate := float(counts["relic_candidate"]) / 10000.0
	var rare_rate := float(counts["rare_equipment"]) / 10000.0
	assert_ge(high_rate, 0.27, "reward-007 expected high equipment rate >= 0.27")
	assert_true(high_rate <= 0.33, "reward-007 expected high equipment rate <= 0.33")
	assert_ge(relic_candidate_rate, 0.47, "reward-007 expected relic candidate rate >= 0.47")
	assert_true(relic_candidate_rate <= 0.53, "reward-007 expected relic candidate rate <= 0.53")
	assert_ge(rare_rate, 0.17, "reward-007 expected rare equipment rate >= 0.17")
	assert_true(rare_rate <= 0.23, "reward-007 expected rare equipment rate <= 0.23")


func test_reward_009_boss_battle_guarantees_one_relic_and_one_unlock_check() -> void:
	var unlock_tracker = _UnlockTracker.new()
	var generator = _make_generator({
		"unlock_tracker": unlock_tracker,
	})
	if generator == null:
		return

	for _index in range(100):
		unlock_tracker.reset()
		var rewards: Dictionary = generator.generate_rewards("boss")
		var relics: Array = rewards.get("relics", [])
		assert_eq(relics.size(), 1, "reward-009 expected exactly one boss relic reward")
		assert_eq(unlock_tracker.call_count, 1, "reward-009 expected exactly one boss unlock check")


func _make_generator(config: Dictionary = {}):
	var script = load(REWARD_GENERATOR_PATH)
	assert_not_null(script, "expected reward_generator.gd to exist")
	if script == null:
		return null
	return script.new(config)


class _UnlockTracker extends RefCounted:
	var call_count := 0

	func perform_unlock_check() -> void:
		call_count += 1

	func reset() -> void:
		call_count = 0
