extends "res://test/rpg/test_base.gd"

const INSTANCE_PATH := "res://scripts/rpg/equipment/equipment_instance.gd"
const MANAGER_PATH := "res://scripts/rpg/equipment/equipment_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_equip_043_swap_puts_old_item_into_inventory_when_space_exists() -> void:
	var manager = _make_manager(0, ["봉인된 열쇠", "잠든 종", "재의 조각"], {"weapon": "녹슨 검"})
	var result = manager.equip_item(_make_item("붉은 달 단도"))
	assert_true(result["success"], "equip-043 expected equip success")
	assert_true(result["old_in_inventory"], "equip-043 expected old item to move to inventory")
	assert_eq(manager.get_inventory().size(), 4, "equip-043 expected inventory size 4")
	assert_eq(manager.get_equipped()["weapon"].get_name(), "붉은 달 단도", "equip-043 expected new weapon equipped")


func test_equip_044_swap_discards_old_item_when_inventory_is_full() -> void:
	var manager = _make_manager(0, ["봉인된 열쇠", "잠든 종", "재의 조각", "붉은 실 반지", "달빛 부적", "파편 목걸이"], {"weapon": "녹슨 검"})
	var result = manager.equip_item(_make_item("붉은 달 단도"))
	assert_true(result["success"], "equip-044 expected equip success")
	assert_false(result["old_in_inventory"], "equip-044 expected no room for old item")
	assert_true(result["old_discarded"], "equip-044 expected old item discarded")
	assert_eq(manager.get_inventory().size(), 6, "equip-044 expected inventory to stay full")


func test_equip_045_add_item_succeeds_at_five_of_six_capacity() -> void:
	var manager = _make_manager(0, ["봉인된 열쇠", "잠든 종", "재의 조각", "붉은 실 반지", "달빛 부적"], {})
	var result = manager.add_to_inventory(_make_item("파편 목걸이"))
	assert_true(result["success"], "equip-045 expected add success")
	assert_eq(manager.get_inventory().size(), 6, "equip-045 expected inventory size 6")


func test_equip_046_add_item_fails_at_six_of_six_capacity() -> void:
	var manager = _make_manager(0, ["봉인된 열쇠", "잠든 종", "재의 조각", "붉은 실 반지", "달빛 부적", "파편 목걸이"], {})
	var result = manager.add_to_inventory(_make_item("균열 완드"))
	assert_false(result["success"], "equip-046 expected add failure")
	assert_eq(manager.get_inventory().size(), 6, "equip-046 expected inventory size unchanged")


func _make_manager(gold: int, inventory_names: Array, equipped_names: Dictionary):
	var manager_script = load(MANAGER_PATH)
	assert_not_null(manager_script, "expected equipment_manager.gd to exist")
	if manager_script == null:
		return null

	var inventory: Array = []
	for equipment_name in inventory_names:
		inventory.append(_make_item(str(equipment_name)))

	var equipped: Dictionary = {}
	for slot_name in equipped_names:
		equipped[slot_name] = _make_item(str(equipped_names[slot_name]))

	return manager_script.new({
		"wallet": _make_wallet(gold),
		"inventory": inventory,
		"equipped": equipped,
	})


func _make_item(equipment_name: String):
	var instance_script = load(INSTANCE_PATH)
	assert_not_null(instance_script, "expected equipment_instance.gd to exist")
	if instance_script == null:
		return null
	return instance_script.new(equipment_name, 0)


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
