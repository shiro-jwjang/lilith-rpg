extends "res://test/rpg/test_base.gd"

const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"


func test_inventory_018_small_healing_potion_caps_hp_at_max_hp() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 치료 물약": 3},
	})
	if inventory == null:
		return
	var target = _make_target({"current_hp": 90, "max_hp": 100})
	var result = inventory.use_potion("소형 치료 물약", target)
	assert_true(result["success"], "inventory-018 expected potion use success")
	assert_eq(result["healed"], 10, "inventory-018 expected only missing HP to be healed")
	assert_eq(target["current_hp"], 100, "inventory-018 expected HP to cap at max")
	assert_eq(inventory.potions["소형 치료 물약"], 2, "inventory-018 expected potion count 2")


func test_inventory_019_small_healing_potion_restores_full_value_when_room_exists() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 치료 물약": 2},
	})
	if inventory == null:
		return
	var target = _make_target({"current_hp": 30, "max_hp": 100})
	var result = inventory.use_potion("소형 치료 물약", target)
	assert_true(result["success"], "inventory-019 expected potion use success")
	assert_eq(result["healed"], 35, "inventory-019 expected full heal amount to apply")
	assert_eq(target["current_hp"], 65, "inventory-019 expected HP after heal 65")
	assert_eq(inventory.potions["소형 치료 물약"], 1, "inventory-019 expected potion count 1")


func test_inventory_020_small_mana_potion_restores_twenty_mp() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 마나 물약": 1},
	})
	if inventory == null:
		return
	var target = _make_target({"current_mp": 10, "max_mp": 50})
	var result = inventory.use_potion("소형 마나 물약", target)
	assert_true(result["success"], "inventory-020 expected potion use success")
	assert_eq(result["restored"], 20, "inventory-020 expected full mana restore amount")
	assert_eq(target["current_mp"], 30, "inventory-020 expected MP after restore 30")
	assert_eq(inventory.potions.get("소형 마나 물약", 0), 0, "inventory-020 expected potion count 0")


func test_inventory_021_small_mana_potion_caps_mp_at_max_mp() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 마나 물약": 1},
	})
	if inventory == null:
		return
	var target = _make_target({"current_mp": 40, "max_mp": 50})
	var result = inventory.use_potion("소형 마나 물약", target)
	assert_true(result["success"], "inventory-021 expected potion use success")
	assert_eq(result["restored"], 10, "inventory-021 expected restore amount to be capped by missing MP")
	assert_eq(target["current_mp"], 50, "inventory-021 expected MP to cap at max")
	assert_eq(inventory.potions.get("소형 마나 물약", 0), 0, "inventory-021 expected potion count 0")


func test_inventory_022_purification_potion_removes_one_debuff_and_heals_ten_hp() -> void:
	var inventory = _make_inventory({
		"potions": {"정화 물약": 1},
	})
	if inventory == null:
		return
	var target = _make_target({
		"current_hp": 50,
		"max_hp": 100,
		"debuffs": ["bleed", "burn", "slow"],
	})
	var result = inventory.use_potion("정화 물약", target)
	assert_true(result["success"], "inventory-022 expected potion use success")
	assert_eq(result["removed_debuff_count"], 1, "inventory-022 expected one debuff removed")
	assert_eq(target["debuffs"], ["burn", "slow"], "inventory-022 expected first debuff removed")
	assert_eq(target["current_hp"], 60, "inventory-022 expected HP after heal 60")
	assert_eq(inventory.potions.get("정화 물약", 0), 0, "inventory-022 expected potion count 0")


func test_inventory_023_purification_potion_fails_when_no_debuffs_are_present() -> void:
	var inventory = _make_inventory({
		"potions": {"정화 물약": 1},
	})
	if inventory == null:
		return
	var target = _make_target({
		"current_hp": 50,
		"max_hp": 100,
		"debuffs": [],
	})
	var result = inventory.use_potion("정화 물약", target)
	assert_false(result["success"], "inventory-023 expected potion use to fail without debuffs")
	assert_eq(target["current_hp"], 50, "inventory-023 expected HP unchanged on failed use")
	assert_eq(inventory.potions["정화 물약"], 1, "inventory-023 expected potion count unchanged")


func test_inventory_024_focus_potion_applies_two_turn_crit_and_effect_hit_buff() -> void:
	var inventory = _make_inventory({
		"potions": {"전투 집중 물약": 1},
	})
	if inventory == null:
		return
	var target = _make_target({
		"crit_rate": 0.05,
		"effect_hit": 0.10,
	})
	var result = inventory.use_potion("전투 집중 물약", target)
	assert_true(result["success"], "inventory-024 expected potion use success")
	assert_eq(result["duration"], 2, "inventory-024 expected buff duration 2")
	assert_eq(target["crit_rate"], 0.15, "inventory-024 expected crit rate buff +0.10")
	assert_eq(target["effect_hit"], 0.20, "inventory-024 expected effect hit buff +0.10")
	assert_eq(target["temporary_effects"].size(), 1, "inventory-024 expected one temporary effect entry")
	assert_eq(inventory.potions.get("전투 집중 물약", 0), 0, "inventory-024 expected potion count 0")


func test_inventory_025_focus_potion_expires_after_two_turns_and_restores_stats() -> void:
	var inventory = _make_inventory({
		"potions": {"전투 집중 물약": 1},
	})
	if inventory == null:
		return
	var target = _make_target({
		"crit_rate": 0.05,
		"effect_hit": 0.10,
	})
	inventory.use_potion("전투 집중 물약", target)
	inventory.tick_temporary_effects(target)
	assert_eq(target["crit_rate"], 0.15, "inventory-025 expected buff to remain after one turn")
	assert_eq(target["effect_hit"], 0.20, "inventory-025 expected effect hit buff to remain after one turn")
	inventory.tick_temporary_effects(target)
	assert_eq(target["crit_rate"], 0.05, "inventory-025 expected crit rate to restore after two turns")
	assert_eq(target["effect_hit"], 0.10, "inventory-025 expected effect hit to restore after two turns")
	assert_eq(target["temporary_effects"].size(), 0, "inventory-025 expected no temporary effects after expiry")


func test_inventory_028_use_fails_when_potion_count_is_zero() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 치료 물약": 0},
	})
	if inventory == null:
		return
	var target = _make_target({"current_hp": 50, "max_hp": 100})
	var result = inventory.use_potion("소형 치료 물약", target)
	assert_false(result["success"], "inventory-028 expected use failure at zero count")
	assert_eq(target["current_hp"], 50, "inventory-028 expected HP unchanged on failure")


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _make_target(overrides: Dictionary = {}) -> Dictionary:
	var target := {
		"current_hp": 100,
		"max_hp": 100,
		"current_mp": 50,
		"max_mp": 50,
		"crit_rate": 0.0,
		"effect_hit": 0.0,
		"debuffs": [],
		"temporary_effects": [],
	}
	for key in overrides:
		target[key] = overrides[key]
	return target
