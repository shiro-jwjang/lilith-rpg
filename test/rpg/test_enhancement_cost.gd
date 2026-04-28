extends "res://test/rpg/test_base.gd"

const INSTANCE_PATH := "res://scripts/rpg/equipment/equipment_instance.gd"
const MANAGER_PATH := "res://scripts/rpg/equipment/equipment_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_equip_001_normal_plus_one_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("녹슨 검", 0, wallet)
	assert_true(result["success"], "equip-001 expected enhancement success")
	assert_eq(result["cost"], 20, "equip-001 expected +1 normal cost 20")
	assert_eq(int(wallet.get_gold()), 80, "equip-001 expected gold 80")


func test_equip_002_high_plus_one_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("붉은 달 단도", 0, wallet)
	assert_true(result["success"], "equip-002 expected enhancement success")
	assert_eq(result["cost"], 35, "equip-002 expected +1 high cost 35")
	assert_eq(int(wallet.get_gold()), 65, "equip-002 expected gold 65")


func test_equip_003_normal_plus_two_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("녹슨 검", 1, wallet)
	assert_true(result["success"], "equip-003 expected enhancement success")
	assert_eq(result["cost"], 35, "equip-003 expected +2 normal cost 35")
	assert_eq(int(wallet.get_gold()), 65, "equip-003 expected gold 65")


func test_equip_004_high_plus_two_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("붉은 달 단도", 1, wallet)
	assert_true(result["success"], "equip-004 expected enhancement success")
	assert_eq(result["cost"], 55, "equip-004 expected +2 high cost 55")
	assert_eq(int(wallet.get_gold()), 45, "equip-004 expected gold 45")


func test_equip_005_rare_plus_two_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("균열 완드", 1, wallet)
	assert_true(result["success"], "equip-005 expected enhancement success")
	assert_eq(result["cost"], 80, "equip-005 expected +2 rare cost 80")
	assert_eq(int(wallet.get_gold()), 20, "equip-005 expected gold 20")


func test_equip_006_normal_plus_three_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("녹슨 검", 2, wallet)
	assert_true(result["success"], "equip-006 expected enhancement success")
	assert_eq(result["cost"], 60, "equip-006 expected +3 normal cost 60")
	assert_eq(int(wallet.get_gold()), 40, "equip-006 expected gold 40")


func test_equip_007_high_plus_three_cost() -> void:
	var wallet = _make_wallet(100)
	var result := _enhance_once("붉은 달 단도", 2, wallet)
	assert_true(result["success"], "equip-007 expected enhancement success")
	assert_eq(result["cost"], 90, "equip-007 expected +3 high cost 90")
	assert_eq(int(wallet.get_gold()), 10, "equip-007 expected gold 10")


func test_equip_008_rare_plus_three_cost() -> void:
	var wallet = _make_wallet(150)
	var result := _enhance_once("균열 완드", 2, wallet)
	assert_true(result["success"], "equip-008 expected enhancement success")
	assert_eq(result["cost"], 120, "equip-008 expected +3 rare cost 120")
	assert_eq(int(wallet.get_gold()), 30, "equip-008 expected gold 30")


func test_equip_009_insufficient_gold_fails_without_spending() -> void:
	var wallet = _make_wallet(19)
	var result := _enhance_once("녹슨 검", 0, wallet)
	assert_false(result["success"], "equip-009 expected enhancement failure")
	assert_eq(result["cost"], 20, "equip-009 expected reported cost 20")
	assert_eq(int(wallet.get_gold()), 19, "equip-009 expected gold unchanged")


func test_equip_010_exact_gold_succeeds_to_zero() -> void:
	var wallet = _make_wallet(20)
	var result := _enhance_once("녹슨 검", 0, wallet)
	assert_true(result["success"], "equip-010 expected enhancement success")
	assert_eq(result["cost"], 20, "equip-010 expected cost 20")
	assert_eq(int(wallet.get_gold()), 0, "equip-010 expected gold 0")


func test_equip_011_rejects_level_above_three() -> void:
	var wallet = _make_wallet(999)
	var result := _enhance_once("녹슨 검", 3, wallet)
	assert_false(result["success"], "equip-011 expected enhancement failure")
	assert_eq(result["error"], "MAX_LEVEL", "equip-011 expected MAX_LEVEL error")
	assert_eq(int(wallet.get_gold()), 999, "equip-011 expected gold unchanged")


func test_equip_047_normal_total_cost_to_plus_three() -> void:
	var wallet = _make_wallet(115)
	var result := _enhance_to_level("녹슨 검", 0, 3, wallet)
	assert_true(result["success"], "equip-047 expected enhance-to-level success")
	assert_eq(result["total_cost"], 115, "equip-047 expected total cost 115")
	assert_eq(int(wallet.get_gold()), 0, "equip-047 expected gold 0")
	assert_eq(result["final_level"], 3, "equip-047 expected final level 3")


func test_equip_048_high_total_cost_to_plus_three() -> void:
	var wallet = _make_wallet(180)
	var result := _enhance_to_level("붉은 달 단도", 0, 3, wallet)
	assert_true(result["success"], "equip-048 expected enhance-to-level success")
	assert_eq(result["total_cost"], 180, "equip-048 expected total cost 180")
	assert_eq(int(wallet.get_gold()), 0, "equip-048 expected gold 0")
	assert_eq(result["final_level"], 3, "equip-048 expected final level 3")


func _enhance_once(equipment_name: String, level: int, wallet) -> Dictionary:
	var manager_script = load(MANAGER_PATH)
	assert_not_null(manager_script, "expected equipment_manager.gd to exist")
	if manager_script == null:
		return {}

	var item = _make_item(equipment_name, level)
	var manager = manager_script.new({"wallet": wallet})
	return manager.enhance_equipment(item)


func _enhance_to_level(equipment_name: String, level: int, target_level: int, wallet) -> Dictionary:
	var manager_script = load(MANAGER_PATH)
	assert_not_null(manager_script, "expected equipment_manager.gd to exist")
	if manager_script == null:
		return {}

	var item = _make_item(equipment_name, level)
	var manager = manager_script.new({"wallet": wallet})
	return manager.enhance_to_level(item, target_level)


func _make_item(equipment_name: String, level: int):
	var instance_script = load(INSTANCE_PATH)
	assert_not_null(instance_script, "expected equipment_instance.gd to exist")
	if instance_script == null:
		return null
	return instance_script.new(equipment_name, level)


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
