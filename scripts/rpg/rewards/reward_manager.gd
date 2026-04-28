extends RefCounted

var pity_counter := 0
var pending_rewards: Array = []


func _init(config: Dictionary = {}) -> void:
	pity_counter = int(config.get("pity_counter", 0))
	pending_rewards = config.get("pending_rewards", []).duplicate(true)


func grant_rewards(rewards: Dictionary, inventory) -> Dictionary:
	if _is_empty_reward(rewards):
		return {
			"success": false,
			"error": "BUG_EMPTY_REWARD",
			"overflow_handled": false,
			"overflow_count": 0,
			"pity_counter": pity_counter,
		}

	_apply_gold(rewards, inventory)

	var overflow_entries: Array = []
	grant_item_rewards(rewards.get("items", []), inventory, overflow_entries)
	grant_relic_rewards(rewards.get("relics", []), inventory, overflow_entries)

	if not overflow_entries.is_empty():
		pending_rewards.append_array(overflow_entries)

	if _contains_relic_candidate(rewards.get("items", [])):
		pity_counter = 0
	else:
		pity_counter += 1

	return {
		"success": true,
		"error": "",
		"overflow_handled": not overflow_entries.is_empty(),
		"overflow_count": overflow_entries.size(),
		"queued_rewards": overflow_entries.duplicate(true),
		"pity_counter": pity_counter,
	}


func grant_item_rewards(items: Array, inventory, overflow_entries: Array) -> void:
	for item in items:
		var result: Dictionary = _grant_item(item, inventory)
		if not bool(result.get("success", false)):
			overflow_entries.append(item.duplicate(true))


func grant_relic_rewards(relics: Array, inventory, overflow_entries: Array) -> void:
	for relic in relics:
		var relic_id := str(relic.get("id", ""))
		var result: Dictionary = inventory.add_relic(relic_id)
		if not bool(result.get("success", false)):
			overflow_entries.append(relic.duplicate(true))


func _grant_item(item: Dictionary, inventory) -> Dictionary:
	var category := str(item.get("category", ""))
	var item_id := str(item.get("id", ""))

	if category == "potion":
		return inventory.add_potion(item_id)

	return inventory.add_equipment(item_id)


func _apply_gold(rewards: Dictionary, inventory) -> void:
	if not rewards.has("gold") or inventory == null:
		return

	var reward_wallet = rewards.get("wallet", null)
	if reward_wallet != null:
		reward_wallet.add_gold(int(rewards.get("gold", 0)))
		return

	if inventory is Dictionary:
		if not inventory.has("wallet"):
			return
		var inventory_wallet = inventory["wallet"]
		if inventory_wallet != null:
			inventory_wallet.add_gold(int(rewards.get("gold", 0)))
		return

	for property_info in inventory.get_property_list():
		var property_name := str(property_info.get("name", ""))
		if property_name == "wallet":
			var inventory_wallet = inventory.get("wallet")
			if inventory_wallet != null:
				inventory_wallet.add_gold(int(rewards.get("gold", 0)))
			return


func _contains_relic_candidate(items: Array) -> bool:
	for item in items:
		if str(item.get("category", "")) == "relic_candidate":
			return true
	return false


func _is_empty_reward(rewards: Dictionary) -> bool:
	if rewards.is_empty():
		return true
	if int(rewards.get("gold", 0)) > 0:
		return false
	if (rewards.get("items", []) as Array).size() > 0:
		return false
	if (rewards.get("relics", []) as Array).size() > 0:
		return false
	return true
