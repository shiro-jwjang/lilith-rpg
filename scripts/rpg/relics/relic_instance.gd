extends RefCounted

const FRAGMENT_RELIC_ID := "붉은 달의 파편"

var relic_id: String = ""
var active: bool = true
var uses_remaining: int = -1


func _init(config: Dictionary = {}) -> void:
	relic_id = str(config.get("relic_id", ""))
	active = bool(config.get("active", true))
	uses_remaining = int(config.get("uses_remaining", _default_uses_for(relic_id)))


func is_available() -> bool:
	return active and uses_remaining != 0


func consume_use() -> void:
	if uses_remaining > 0:
		uses_remaining -= 1


func _default_uses_for(target_relic_id: String) -> int:
	if target_relic_id == FRAGMENT_RELIC_ID:
		return 1
	return -1
