extends RefCounted

const EQUIPMENT_INSTANCE_PATH := "res://scripts/rpg/equipment/equipment_instance.gd"
const POTION_REGISTRY_PATH := "res://scripts/rpg/inventory/potion_registry.gd"

const RELIC_IDS := [
	"붉은 달의 파편",
	"녹슨 방패편",
	"사냥개의 이빨",
	"균열의 실",
]

var _rng := RandomNumberGenerator.new()
var _equipment_catalog: Dictionary = {}
var _potion_registry = null


func _init(config: Dictionary = {}) -> void:
	_rng.randomize()
	if config.has("seed"):
		_rng.seed = int(config.get("seed", 0))

	var equipment_script = load(EQUIPMENT_INSTANCE_PATH)
	if equipment_script != null:
		_equipment_catalog = equipment_script.EQUIPMENT_DATA.duplicate(true)

	var potion_registry_script = load(POTION_REGISTRY_PATH)
	if potion_registry_script != null:
		_potion_registry = potion_registry_script.new()


func generate_equipment_pool(config: Dictionary = {}) -> Array:
	var tier: String = String(config.get("tier", ""))
	var requested_count: int = int(config.get("count", _rng.randi_range(3, 4)))
	var count: int = clampi(requested_count, 3, 4)
	var candidates: Array = _equipment_candidates_for_tier(tier)
	var selections: Array = _pick_unique_entries(candidates, count)
	var results: Array = []

	for equipment_name in selections:
		var tier_name: String = _equipment_tier_for_name(String(equipment_name))
		results.append({
			"type": "equipment",
			"name": String(equipment_name),
			"tier": tier_name,
			"price": _roll_equipment_price(tier_name),
		})

	return results


func generate_relic_pool() -> Array:
	var selections: Array = _pick_unique_entries(RELIC_IDS.duplicate(), 2)
	var results: Array = []

	for relic_id in selections:
		results.append({
			"type": "relic",
			"name": relic_id,
			"price": _rng.randi_range(60, 90),
		})

	return results


func generate_potion_pool() -> Array:
	var results: Array = []
	if _potion_registry == null:
		return results

	var all_potions: Dictionary = _potion_registry.get_all_potions()
	var potion_names: Array = all_potions.keys()
	potion_names.sort()

	for potion_name in potion_names:
		var potion = all_potions[potion_name]
		results.append({
			"type": "potion",
			"name": String(potion.name),
			"price": int(potion.cost),
			"stock": -1,
		})

	return results


func _equipment_candidates_for_tier(tier: String) -> Array:
	var names: Array = []
	var sorted_names: Array = _equipment_catalog.keys()
	sorted_names.sort()

	for equipment_name in sorted_names:
		var grade: String = _equipment_tier_for_name(String(equipment_name))
		if tier.is_empty() or grade == tier:
			names.append(String(equipment_name))

	return names


func _equipment_tier_for_name(equipment_name: String) -> String:
	var record: Dictionary = _equipment_catalog.get(equipment_name, {})
	return String(record.get("grade", ""))


func _roll_equipment_price(tier: String) -> int:
	if tier == "high":
		return _rng.randi_range(50, 70)
	return _rng.randi_range(30, 45)


func _pick_unique_entries(source: Array, count: int) -> Array:
	var pool: Array = source.duplicate()
	var results: Array = []
	var target_count: int = mini(count, pool.size())

	while results.size() < target_count and pool.size() > 0:
		var index: int = _rng.randi_range(0, pool.size() - 1)
		results.append(pool[index])
		pool.remove_at(index)

	return results
