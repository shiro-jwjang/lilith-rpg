extends RefCounted


func is_choice_visible(choice: Dictionary, context: Dictionary) -> bool:
	if not choice.has("hidden_condition"):
		return true

	var rule: Dictionary = choice["hidden_condition"]
	var rule_type := String(rule.get("type", ""))
	var min_value := int(rule.get("min", 0))

	match rule_type:
		"visit_count":
			return int(context.get("visit_count", 0)) >= min_value
		"gold":
			var player: Dictionary = context.get("player", {})
			if not player.has("wallet"):
				return false
			var wallet = player["wallet"]
			return bool(wallet.can_afford(min_value))
		"battle_wins":
			return int(context.get("battle_wins", 0)) >= min_value
		"status_effects":
			var player: Dictionary = context.get("player", {})
			var status_effects: Array = player.get("status_effects", [])
			return status_effects.size() >= min_value

	return true
