extends RefCounted

const STACKABLE := ["출혈", "화상"]
const MAX_STACKS := {"출혈": 3, "화상": 3}
const DOT_DAMAGE := {"출혈": 0.05, "화상": 0.06}

var name: String = ""
var current_hp: int = 0
var max_hp: int = 0
var current_mp: int = 0
var max_mp: int = 0
var atk: int = 0
var def: int = 0
var speed: int = 0
var internal_id: int = 0
var is_ally: bool = false
var alive: bool = true
var tier: String = "normal"
var phases: int = 1
var phase_2_triggered: bool = false
var phase_transition_hp: int = 0
var status_effects: Dictionary = {}
var active_statuses: Dictionary = {}
var crit_rate: float = 0.0
var effect_hit: float = 0.0
var effect_resist: float = 0.0
var base_speed: int = 0
var taunt_turns: int = 0


func _init(config: Dictionary = {}) -> void:
	name = String(config.get("name", ""))
	max_hp = int(config.get("max_hp", 0))
	current_hp = int(config.get("current_hp", max_hp))
	max_mp = int(config.get("max_mp", 0))
	current_mp = int(config.get("current_mp", max_mp))
	atk = int(config.get("atk", 0))
	def = int(config.get("def", 0))
	speed = int(config.get("speed", 0))
	internal_id = int(config.get("internal_id", 0))
	is_ally = bool(config.get("is_ally", false))
	tier = String(config.get("tier", "normal"))
	phases = int(config.get("phases", 1))
	phase_2_triggered = bool(config.get("phase_2_triggered", false))
	phase_transition_hp = int(config.get("phase_transition_hp", 0))
	status_effects = config.get("status_effects", {}).duplicate(true)
	crit_rate = float(config.get("crit_rate", 0.0))
	effect_hit = float(config.get("effect_hit", 0.0))
	effect_resist = float(config.get("effect_resist", config.get("effect_resistance", 0.0)))
	base_speed = int(config.get("speed", speed))
	active_statuses = {
		"출혈": {"stacks": 0, "duration": 0},
		"화상": {"stacks": 0, "duration": 0},
		"둔화": {"stacks": 0, "duration": 0},
		"약화": {"stacks": 0, "duration": 0},
		"파쇄": {"stacks": 0, "duration": 0},
		"기절": {"stacks": 0, "duration": 0},
	}
	if config.has("active_statuses") and config.get("active_statuses") is Dictionary:
		var config_active_statuses: Dictionary = config.get("active_statuses")
		for key in config_active_statuses:
			if active_statuses.has(key):
				active_statuses[key] = config_active_statuses[key].duplicate(true)
	taunt_turns = int(config.get("taunt_turns", 0))
	current_hp = clamp(current_hp, 0, max_hp)
	current_mp = clamp(current_mp, 0, max_mp)
	alive = current_hp > 0


func take_damage(amount) -> void:
	current_hp = max(0, current_hp - int(amount))
	alive = current_hp > 0


func heal(amount) -> void:
	current_hp = min(max_hp, current_hp + int(amount))
	alive = current_hp > 0


func use_mp(cost) -> bool:
	var mp_cost := int(cost)
	if current_mp < mp_cost:
		return false
	current_mp -= mp_cost
	return true


func is_alive() -> bool:
	return alive


func apply_status(effect_type: String, stacks: int, duration: int) -> void:
	if not active_statuses.has(effect_type):
		return
	if STACKABLE.has(effect_type):
		var current_stacks: int = int(active_statuses[effect_type]["stacks"])
		var max_stacks: int = int(MAX_STACKS.get(effect_type, 1))
		active_statuses[effect_type]["stacks"] = min(current_stacks + stacks, max_stacks)
	else:
		active_statuses[effect_type]["stacks"] = 1
	active_statuses[effect_type]["duration"] = duration


func has_status(effect_type: String) -> bool:
	if not active_statuses.has(effect_type):
		return false
	return int(active_statuses[effect_type]["duration"]) > 0


func get_status(effect_type: String) -> Dictionary:
	if not active_statuses.has(effect_type):
		return {}
	return active_statuses[effect_type].duplicate(true)


func process_turn_end_status() -> Dictionary:
	var tick_damage := 0
	var tick_types: Array = []
	for dot_type in ["출혈", "화상"]:
		var info: Dictionary = active_statuses[dot_type]
		var stacks: int = int(info["stacks"])
		var duration: int = int(info["duration"])
		if stacks > 0 and duration > 0:
			var damage_ratio: float = float(DOT_DAMAGE.get(dot_type, 0.0))
			var damage: int = int(floor(float(max_hp) * damage_ratio * float(stacks)))
			take_damage(damage)
			tick_damage += damage
			tick_types.append(dot_type)

	var expired: Array = []
	for effect_type in active_statuses:
		var duration: int = int(active_statuses[effect_type]["duration"])
		if duration > 0:
			active_statuses[effect_type]["duration"] = duration - 1
			if int(active_statuses[effect_type]["duration"]) <= 0:
				expired.append(effect_type)

	for effect_type in expired:
		active_statuses[effect_type]["stacks"] = 0
		active_statuses[effect_type]["duration"] = 0

	return {
		"tick_damage": tick_damage,
		"tick_types": tick_types,
		"expired": expired,
	}


func clear_all_statuses() -> void:
	for effect_type in active_statuses:
		active_statuses[effect_type]["stacks"] = 0
		active_statuses[effect_type]["duration"] = 0


func apply_taunt(turns: int) -> void:
	taunt_turns = turns


func decrement_taunt() -> void:
	if taunt_turns > 0:
		taunt_turns -= 1


func is_taunting() -> bool:
	return taunt_turns > 0
