extends RefCounted

const SHOP_POOL_GENERATOR_PATH := "res://scripts/rpg/shop/shop_pool_generator.gd"

var wallet: RefCounted = null

var _generator = null
var _visit_count: int = 0
var _relics_shown_this_run: bool = false
var _potion_purchase_counts: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	wallet = config["wallet"]
	var generator_script = load(SHOP_POOL_GENERATOR_PATH)
	if generator_script != null:
		_generator = generator_script.new(config)


func visit_shop(config: Dictionary = {}) -> Dictionary:
	_visit_count += 1

	var equipment_config: Dictionary = {}
	if config.has("forced_equipment_count"):
		equipment_config["count"] = int(config.get("forced_equipment_count", 3))

	var equipment_list: Array = []
	var relic_list: Array = []
	var potion_list: Array = []
	if _generator != null:
		equipment_list = _generator.generate_equipment_pool(equipment_config)
		potion_list = _generator.generate_potion_pool()
		if not _relics_shown_this_run:
			relic_list = _generator.generate_relic_pool()
			_relics_shown_this_run = true

	return {
		"visit_count": _visit_count,
		"equipment_roll_id": "shop_roll_%d" % _visit_count,
		"equipment_list": equipment_list,
		"relic_pool_visible": relic_list.size() > 0,
		"relic_list": relic_list,
		"potion_list": potion_list,
	}


func purchase_item(item: Dictionary) -> Dictionary:
	var price: int = int(item.get("price", 0))
	if not _can_afford(price):
		return {
			"success": false,
			"reason": "insufficient_gold",
			"gold_after": _get_current_gold(),
		}

	_spend_gold(price)
	var item_type: String = String(item.get("type", ""))
	var result: Dictionary = {
		"success": true,
		"reason": "",
		"gold_after": _get_current_gold(),
		"item": item.duplicate(true),
	}

	if item_type == "relic":
		result["relic_preview_displayed"] = true
	elif item_type == "potion":
		var potion_name: String = String(item.get("name", ""))
		var count: int = int(_potion_purchase_counts.get(potion_name, 0)) + 1
		_potion_purchase_counts[potion_name] = count
		result["purchased_count"] = count
		result["stock_limit_reached"] = false

	return result


func _can_afford(amount: int) -> bool:
	return bool(wallet.can_afford(amount))


func _spend_gold(amount: int) -> bool:
	return bool(wallet.spend(amount))


func _get_current_gold() -> int:
	return int(wallet.get_gold())
