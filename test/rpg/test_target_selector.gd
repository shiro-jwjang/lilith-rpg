extends "res://test/rpg/test_base.gd"

const TARGET_SELECTOR_PATH := "res://scripts/rpg/ai/target_selector.gd"


func test_combat_035_single_target_selects_lowest_hp_ratio_ally() -> void:
	var selector = _make_target_selector()
	if selector == null:
		return
	var allies := [
		{"id": "ally_1", "current_hp": 30, "max_hp": 100},
		{"id": "ally_2", "current_hp": 80, "max_hp": 100},
		{"id": "ally_3", "current_hp": 50, "max_hp": 100},
	]
	var target = selector.select_target("single", allies)
	assert_eq(target.get("id", ""), "ally_1", "combat-035 expected lowest HP ratio ally_1")


func test_combat_036_aoe_target_returns_all_allies() -> void:
	var selector = _make_target_selector()
	if selector == null:
		return
	var allies := [
		{"id": "ally_1", "current_hp": 100, "max_hp": 100},
		{"id": "ally_2", "current_hp": 1, "max_hp": 100},
	]
	var targets = selector.select_target("aoe", allies)
	assert_eq(targets.size(), 2, "combat-036 expected all allies to be targeted")
	assert_eq(targets[0].get("id", ""), "ally_1", "combat-036 expected first ally preserved")
	assert_eq(targets[1].get("id", ""), "ally_2", "combat-036 expected second ally preserved")


func test_combat_037_status_target_selects_first_ally_without_requested_status() -> void:
	var selector = _make_target_selector()
	if selector == null:
		return
	var allies := [
		{"id": "ally_1", "statuses": ["bleed"]},
		{"id": "ally_2", "statuses": []},
		{"id": "ally_3", "statuses": ["burn"]},
	]
	var target = selector.select_target("status_effect", allies, "bleed")
	assert_eq(target.get("id", ""), "ally_2", "combat-037 expected first ally without bleed to be selected")


func _make_target_selector():
	var script = load(TARGET_SELECTOR_PATH)
	assert_not_null(script, "expected target_selector.gd to exist")
	if script == null:
		return null
	return script.new()
