extends "res://test/rpg/test_base.gd"

const CAMPFIRE_MANAGER_PATH := "res://scripts/rpg/campfire/campfire_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_campfire_005_investing_in_a_stat_costs_twenty_five_gold_and_adds_one() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var wallet = _make_wallet(50)
	var result: Dictionary = manager.invest_stat({
		"wallet": wallet,
		"strength": 5,
	}, "strength")
	var player_after: Dictionary = result.get("player", {})
	assert_true(bool(result.get("success", false)), "campfire-005 expected investment success")
	assert_eq(int(player_after.get("strength", -1)), 6, "campfire-005 expected strength 6")
	assert_eq(int(wallet.get_gold()), 25, "campfire-005 expected gold 25")


func test_campfire_006_investment_fails_when_gold_is_below_cost() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var wallet = _make_wallet(24)
	var result: Dictionary = manager.invest_stat({
		"wallet": wallet,
		"strength": 5,
	}, "strength")
	var player_after: Dictionary = result.get("player", {})
	assert_false(bool(result.get("success", false)), "campfire-006 expected investment failure")
	assert_eq(int(player_after.get("strength", -1)), 5, "campfire-006 expected strength unchanged")
	assert_eq(int(wallet.get_gold()), 24, "campfire-006 expected gold unchanged")


func test_campfire_007_investment_succeeds_with_exactly_twenty_five_gold() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var wallet = _make_wallet(25)
	var result: Dictionary = manager.invest_stat({
		"wallet": wallet,
		"vitality": 3,
	}, "vitality")
	var player_after: Dictionary = result.get("player", {})
	assert_true(bool(result.get("success", false)), "campfire-007 expected exact-gold investment success")
	assert_eq(int(player_after.get("vitality", -1)), 4, "campfire-007 expected vitality 4")
	assert_eq(int(wallet.get_gold()), 0, "campfire-007 expected gold 0")


func test_campfire_008_each_supported_stat_can_be_invested_independently() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var stats := ["strength", "vitality", "intelligence", "agility", "luck"]
	for stat_name in stats:
		var wallet = _make_wallet(999)
		var result: Dictionary = manager.invest_stat({
			"wallet": wallet,
			"strength": 1,
			"vitality": 1,
			"intelligence": 1,
			"agility": 1,
			"luck": 1,
		}, stat_name)
		var player_after: Dictionary = result.get("player", {})
		assert_true(bool(result.get("success", false)), "campfire-008 expected investment success for %s" % stat_name)
		assert_eq(int(player_after.get(stat_name, -1)), 2, "campfire-008 expected %s to increase by 1" % stat_name)
		assert_eq(int(wallet.get_gold()), 974, "campfire-008 expected gold to decrease by 25")


func _make_manager(config: Dictionary = {}):
	var script = load(CAMPFIRE_MANAGER_PATH)
	assert_not_null(script, "expected campfire_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
