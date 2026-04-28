extends "res://test/rpg/test_base.gd"

const REWARD_GENERATOR_PATH := "res://scripts/rpg/rewards/reward_generator.gd"


func test_reward_011_event_node_grants_one_reward_per_choice() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	var result_a: Dictionary = generator.generate_event_reward("A")
	var result_b: Dictionary = generator.generate_event_reward("B")
	assert_true(_reward_payload_has_content(result_a), "reward-011 expected one reward payload for choice A")
	assert_true(_reward_payload_has_content(result_b), "reward-011 expected one reward payload for choice B")
	assert_eq(generator.get_event_reward_count(), 2, "reward-011 expected reward count to match choices made")


func test_reward_012_event_node_disallows_duplicate_rewards_for_same_choice() -> void:
	var generator = _make_generator()
	if generator == null:
		return

	var first_result: Dictionary = generator.generate_event_reward("A")
	var second_result: Dictionary = generator.generate_event_reward("A")
	assert_true(_reward_payload_has_content(first_result), "reward-012 expected first reward for choice A")
	assert_false(_reward_payload_has_content(second_result), "reward-012 expected duplicate reward for choice A to be blocked")
	assert_eq(generator.get_event_reward_count(), 1, "reward-012 expected only one granted reward for duplicate choice")


func _reward_payload_has_content(payload: Dictionary) -> bool:
	if int(payload.get("gold", 0)) > 0:
		return true
	if (payload.get("items", []) as Array).size() > 0:
		return true
	if (payload.get("relics", []) as Array).size() > 0:
		return true
	return false


func _make_generator(config: Dictionary = {}):
	var script = load(REWARD_GENERATOR_PATH)
	assert_not_null(script, "expected reward_generator.gd to exist")
	if script == null:
		return null
	return script.new(config)
