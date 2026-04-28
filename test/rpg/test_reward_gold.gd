extends "res://test/rpg/test_base.gd"

const REWARD_GENERATOR_PATH := "res://scripts/rpg/rewards/reward_generator.gd"


func test_reward_001_normal_battle_gold_stays_within_range() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	for _index in range(1000):
		var rewards: Dictionary = generator.generate_rewards("normal")
		assert_ge(int(rewards.get("gold", -1)), 20, "reward-001 expected normal gold >= 20")
		assert_true(int(rewards.get("gold", -1)) <= 35, "reward-001 expected normal gold <= 35")


func test_reward_004_elite_battle_gold_stays_within_range() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	for _index in range(1000):
		var rewards: Dictionary = generator.generate_rewards("elite")
		assert_ge(int(rewards.get("gold", -1)), 60, "reward-004 expected elite gold >= 60")
		assert_true(int(rewards.get("gold", -1)) <= 80, "reward-004 expected elite gold <= 80")


func test_reward_006_unique_battle_gold_stays_within_range() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	for _index in range(1000):
		var rewards: Dictionary = generator.generate_rewards("unique")
		assert_ge(int(rewards.get("gold", -1)), 80, "reward-006 expected unique gold >= 80")
		assert_true(int(rewards.get("gold", -1)) <= 100, "reward-006 expected unique gold <= 100")


func test_reward_008_boss_battle_gold_is_fixed_at_120() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	for _index in range(100):
		var rewards: Dictionary = generator.generate_rewards("boss")
		assert_eq(int(rewards.get("gold", -1)), 120, "reward-008 expected boss gold to stay fixed at 120")


func test_reward_015_normal_battle_gold_can_hit_minimum_boundary() -> void:
	var generator = _make_generator({
		"rng": _SequenceRng.new([20]),
	})
	if generator == null:
		return

	var rewards: Dictionary = generator.generate_rewards("normal")
	assert_eq(int(rewards.get("gold", -1)), 20, "reward-015 expected forced minimum normal gold")


func test_reward_016_normal_battle_gold_can_hit_maximum_boundary() -> void:
	var generator = _make_generator({
		"rng": _SequenceRng.new([35]),
	})
	if generator == null:
		return

	var rewards: Dictionary = generator.generate_rewards("normal")
	assert_eq(int(rewards.get("gold", -1)), 35, "reward-016 expected forced maximum normal gold")


func _make_generator(config: Dictionary = {}):
	var script = load(REWARD_GENERATOR_PATH)
	assert_not_null(script, "expected reward_generator.gd to exist")
	if script == null:
		return null
	return script.new(config)


class _SequenceRng extends RefCounted:
	var _values: Array
	var _index := 0

	func _init(values: Array) -> void:
		_values = values.duplicate(true)

	func randi_range(_from: int, _to: int) -> int:
		if _values.is_empty():
			return _from
		var value = int(_values[min(_index, _values.size() - 1)])
		_index += 1
		return value
