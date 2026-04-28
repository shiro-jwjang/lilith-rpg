extends RefCounted

const REWARD_GENERATOR_PATH := "res://scripts/rpg/rewards/reward_generator.gd"

var event_id: String = ""
var title: String = ""
var event_enemy_pool: Array = []
var _choices: Array = []
var _condition_checker = null
var _rng = null
var _reward_generator = null


func _init(config: Dictionary = {}) -> void:
	event_id = String(config.get("event_id", ""))
	title = String(config.get("title", ""))
	event_enemy_pool = (config.get("event_enemy_pool", []) as Array).duplicate(true)
	_choices = (config.get("choices", []) as Array).duplicate(true)
	_condition_checker = config.get("condition_checker", null)
	_rng = config.get("rng", null)
	var reward_generator_script = load(REWARD_GENERATOR_PATH)
	if reward_generator_script != null:
		_reward_generator = reward_generator_script.new({
			"rng": _rng,
		})


func get_all_choices() -> Array:
	return _choices.duplicate(true)


func get_visible_choices(context: Dictionary) -> Array:
	var visible: Array = []
	for choice in _choices:
		if _is_choice_visible(choice, context):
			visible.append(choice.duplicate(true))
	return visible


func resolve_choice(choice_id: String, context: Dictionary) -> Dictionary:
	var result := _create_base_result(context)
	if not _is_visible_choice_id(choice_id, context):
		result["next_state"] = "blocked"
		result["event_resolved"] = false
		return result

	_apply_choice(choice_id, result, context)
	_finalize_result(result)
	return result


func _apply_choice(_choice_id: String, _result: Dictionary, _context: Dictionary) -> void:
	pass


func _create_base_result(context: Dictionary) -> Dictionary:
	var player: Dictionary = (context.get("player", {}) as Dictionary).duplicate(true)
	return {
		"event_id": event_id,
		"current_node": (context.get("current_node", null) as Variant),
		"player": player,
		"reward": {},
		"reward_count": 0,
		"relic_offered": false,
		"relic_granted": false,
		"combat_triggered": false,
		"combat": {},
		"event_resolved": false,
		"next_node": null,
		"next_state": "pending",
		"next_combat_modifier": (context.get("next_combat_modifier", {}) as Dictionary).duplicate(true),
	}


func _finalize_result(result: Dictionary) -> void:
	if String(result.get("next_state", "pending")) == "pending":
		result["next_state"] = "advance"
	if result.get("next_node", null) == null:
		result["next_node"] = _make_next_node(String(result.get("next_state", "advance")))
	result["event_resolved"] = true


func _make_next_node(next_state: String) -> Dictionary:
	var node_type := "event"
	if next_state == "combat":
		node_type = "combat"
	return {
		"id": "%s_%s" % [event_id, next_state],
		"type": node_type,
		"source_event": event_id,
	}


func _is_visible_choice_id(choice_id: String, context: Dictionary) -> bool:
	for choice in _choices:
		if String(choice.get("id", "")) == choice_id and _is_choice_visible(choice, context):
			return true
	return false


func _is_choice_visible(choice: Dictionary, context: Dictionary) -> bool:
	if _condition_checker == null:
		return true
	return bool(_condition_checker.is_choice_visible(choice, context))


func _set_reward(result: Dictionary, reward_type: String, reward_count: int = 1, extra: Dictionary = {}) -> void:
	var reward := {
		"type": reward_type,
	}
	for key in extra:
		reward[key] = extra[key]
	result["reward"] = reward
	result["reward_count"] = reward_count


func _offer_relic(result: Dictionary, guaranteed: bool) -> void:
	_set_reward(result, "relic_candidate", 1)
	result["relic_offered"] = true
	result["relic_granted"] = guaranteed


func _trigger_combat(result: Dictionary) -> void:
	var gold_reward := 20
	if _reward_generator != null:
		var rewards: Dictionary = _reward_generator.generate_rewards("normal")
		gold_reward = int(rewards.get("gold", 20))
	var enemy_id := _pick_enemy()
	result["combat_triggered"] = true
	result["combat"] = {
		"battle_type": "normal",
		"gold": gold_reward,
		"enemy": enemy_id,
		"event_enemy_pool": event_enemy_pool.duplicate(true),
	}
	result["next_state"] = "combat"
	result["next_node"] = _make_next_node("combat")


func _pick_enemy() -> String:
	if event_enemy_pool.is_empty():
		return ""
	if _rng != null and _rng.has_method("randi_range"):
		var index := int(_rng.randi_range(0, event_enemy_pool.size() - 1))
		return String(event_enemy_pool[index])
	var roll := _randf()
	var index := int(floor(roll * float(event_enemy_pool.size())))
	index = clamp(index, 0, event_enemy_pool.size() - 1)
	return String(event_enemy_pool[index])


func _randf() -> float:
	if _rng != null and _rng.has_method("randf"):
		return float(_rng.randf())
	return randf()


func _reduce_hp_percent(player: Dictionary, percent: float) -> void:
	player["hp"] = float(player.get("hp", 0.0)) * (1.0 - percent)


func _reduce_mp_percent(player: Dictionary, percent: float) -> void:
	player["mp"] = float(player.get("mp", 0.0)) * (1.0 - percent)


func _increase_hp_percent_of_max(player: Dictionary, percent: float) -> void:
	var hp_max := float(player.get("hp_max", 0.0))
	var hp := float(player.get("hp", 0.0))
	player["hp"] = min(hp_max, hp + (hp_max * percent))


func _clear_statuses(player: Dictionary) -> void:
	player["status_effects"] = []


func _get_player_wallet(player: Dictionary):
	return player["wallet"]


func _get_player_gold(player: Dictionary) -> int:
	return int(_get_player_wallet(player).get_gold())


func _can_player_afford(player: Dictionary, amount: int) -> bool:
	return bool(_get_player_wallet(player).can_afford(amount))


func _spend_player_gold(player: Dictionary, amount: int) -> bool:
	return bool(_get_player_wallet(player).spend(amount))


func _add_player_gold(player: Dictionary, amount: int) -> void:
	_get_player_wallet(player).add_gold(amount)
