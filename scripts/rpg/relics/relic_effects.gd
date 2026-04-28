extends RefCounted

const FRAGMENT_RELIC_ID := "붉은 달의 파편"
const SHIELD_RELIC_ID := "녹슨 방패편"
const FANG_RELIC_ID := "사냥개의 이빨"
const EMBER_RELIC_ID := "재의 잔향"
const THREAD_RELIC_ID := "균열의 실"
const BELL_RELIC_ID := "고요한 종"


static func apply_effect(relic, context: Dictionary) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	if relic == null or not relic.is_available():
		return result

	match relic.relic_id:
		FRAGMENT_RELIC_ID:
			_apply_fragment(relic, result)
		SHIELD_RELIC_ID:
			_apply_shield(result)
		FANG_RELIC_ID:
			_apply_fang(result)
		EMBER_RELIC_ID:
			_apply_ember(result)
		THREAD_RELIC_ID:
			_apply_thread(result)
		BELL_RELIC_ID:
			_apply_bell(result)

	return result


static func _apply_fragment(relic, result: Dictionary) -> void:
	if not bool(result.get("critical_hit", false)):
		return

	var current_damage := float(result.get("damage", 0))
	result["damage"] = int(floor(current_damage * 1.25))
	result["current_mp"] = int(result.get("current_mp", 0)) + 5
	relic.consume_use()


static func _apply_shield(result: Dictionary) -> void:
	if str(result.get("event", "")) != "defend":
		return

	result["defense"] = int(result.get("defense", 0)) + 3
	result["temporary_defense_turns"] = 2


static func _apply_fang(result: Dictionary) -> void:
	if result.has("bleed_damage"):
		var max_hp := float(result.get("max_hp", 0.0))
		result["bleed_damage"] = float(result.get("bleed_damage", 0.0)) + (max_hp * 0.02)

	if result.has("bleed_stacks"):
		result["bleed_stacks"] = int(result.get("bleed_stacks", 0)) + 1


static func _apply_ember(result: Dictionary) -> void:
	if result.has("burn_chance"):
		result["burn_chance"] = float(result.get("burn_chance", 0.0)) + 0.10


static func _apply_thread(result: Dictionary) -> void:
	if result.has("slow_chance"):
		result["slow_chance"] = float(result.get("slow_chance", 0.0)) + 0.10

	if result.has("shatter_chance"):
		result["shatter_chance"] = float(result.get("shatter_chance", 0.0)) + 0.10

	if result.has("effect_hit"):
		result["effect_hit"] = float(result.get("effect_hit", 0.0)) + 0.15


static func _apply_bell(result: Dictionary) -> void:
	if result.has("event_penalty"):
		result["event_penalty"] = float(result.get("event_penalty", 0.0)) * 0.8

	if result.has("healing_amount"):
		var healed := float(result.get("healing_amount", 0.0))
		if result.has("healing_multiplier"):
			healed *= float(result.get("healing_multiplier", 1.0))
		result["healing_amount"] = healed * 1.1
