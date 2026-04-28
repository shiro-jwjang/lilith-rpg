extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"
const CAMPFIRE_MANAGER_PATH := "res://scripts/rpg/campfire/campfire_manager.gd"
const DAMAGE_CALCULATOR_PATH := "res://scripts/rpg/combat/damage_calculator.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_integ_013_rest_heals_player_for_thirty_five_percent_of_max_hp() -> void:
	var manager = _campfire_manager()
	if manager == null:
		return

	var wallet = _make_wallet(50)
	var result: Dictionary = manager.rest({
		"hp": 50,
		"max_hp": 100,
		"wallet": wallet,
		"strength": 5,
	})
	var player_after: Dictionary = result.get("player", {})
	assert_eq(int(player_after.get("hp", -1)), 85, "integ-013 expected hp 85 after rest")
	assert_eq(int(result.get("healed", -1)), 35, "integ-013 expected healed amount 35")


func test_integ_014_invest_strength_spends_twenty_five_gold_and_increases_stat() -> void:
	var manager = _campfire_manager()
	if manager == null:
		return

	var wallet = _make_wallet(50)
	var result: Dictionary = manager.invest_stat({
		"hp": 85,
		"max_hp": 100,
		"wallet": wallet,
		"strength": 5,
	}, "strength")
	var player_after: Dictionary = result.get("player", {})
	assert_true(bool(result.get("success", false)), "integ-014 expected investment success")
	assert_eq(int(player_after.get("strength", -1)), 6, "integ-014 expected strength 6")
	assert_eq(int(wallet.get_gold()), 25, "integ-014 expected gold 25")


func test_integ_015_campfire_updated_player_is_ready_for_next_combat() -> void:
	var campfire = _campfire_manager()
	var battle_manager = _battle_manager()
	var damage_calculator = _damage_calculator()
	if campfire == null or battle_manager == null or damage_calculator == null:
		return

	var wallet = _make_wallet(50)
	var rested: Dictionary = campfire.rest({
		"hp": 50,
		"max_hp": 100,
		"wallet": wallet,
		"strength": 5,
		"defense": 8,
		"speed": 11,
	}).get("player", {})
	var invested_result: Dictionary = campfire.invest_stat(rested, "strength")
	var player_after: Dictionary = invested_result.get("player", {})

	battle_manager.init_battle([
		{
			"internal_id": 1,
			"current_hp": int(player_after.get("hp", 0)),
			"max_hp": int(player_after.get("max_hp", 0)),
			"atk": int(player_after.get("strength", 0)) + 10,
			"def": int(player_after.get("defense", 0)),
			"speed": int(player_after.get("speed", 0)),
		},
	], [
		{
			"internal_id": 101,
			"current_hp": 60,
			"max_hp": 60,
			"atk": 12,
			"def": 4,
			"speed": 8,
			"tier": "normal",
		},
	])

	var opening = battle_manager.next_turn()
	var acting_unit = opening.get("unit", null)
	if acting_unit != null and bool(acting_unit.is_ally):
		var damage: int = damage_calculator.calculate_base_damage(int(acting_unit.atk), 1.0, int(battle_manager.enemies[0].def))
		battle_manager.enemies[0].take_damage(damage)

	assert_eq(int(battle_manager.allies[0].current_hp), 85, "integ-015 expected rested HP to carry into combat")
	assert_eq(int(battle_manager.allies[0].atk), 16, "integ-015 expected invested strength to affect combat ATK")
	assert_true(battle_manager.enemies[0].current_hp < 60, "integ-015 expected next combat to consume the campfire-updated player state")


func _campfire_manager():
	var script = load(CAMPFIRE_MANAGER_PATH)
	assert_not_null(script, "expected campfire_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _damage_calculator():
	var script = load(DAMAGE_CALCULATOR_PATH)
	assert_not_null(script, "expected damage_calculator.gd to exist")
	return script


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
