extends RefCounted

const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")
const TURN_MANAGER_SCRIPT := preload("res://scripts/rpg/combat/turn_manager.gd")
const TURN_ORDER_SCRIPT := preload("res://scripts/rpg/combat/turn_order.gd")

const TARGET_TURNS_BY_TIER := {
	"normal": {"min": 2, "max": 4},
	"elite": {"min": 4, "max": 6},
	"boss": {"min": 6, "max": 8},
}

var allies: Array = []
var enemies: Array = []
var turn_queue: Array = []
var turn_index: int = 0
var turn_manager = TURN_MANAGER_SCRIPT.new()
var battle_result = null
var target_turn_range: Dictionary = TARGET_TURNS_BY_TIER["normal"].duplicate(true)
var _run_terminated: bool = false
var _boss_phase_transition_checker = Callable()


func init_battle(ally_configs: Array, enemy_configs: Array) -> void:
	allies = _build_units(ally_configs, true)
	enemies = _build_units(enemy_configs, false)
	turn_queue.clear()
	turn_index = 0
	battle_result = null
	_run_terminated = false
	target_turn_range = _resolve_target_turn_range(enemy_configs)


func next_turn() -> Dictionary:
	if battle_result != null:
		return {"battle_result": battle_result}

	if turn_queue.is_empty() or turn_index >= turn_queue.size():
		turn_queue = TURN_ORDER_SCRIPT.resolve_turn_order(_living_units())
		turn_index = 0

	if turn_queue.is_empty():
		battle_result = check_battle_end()
		return {"battle_result": battle_result}

	var unit = turn_queue[turn_index]
	turn_index += 1
	if not unit.is_alive():
		battle_result = check_battle_end()
		return {
			"unit": unit,
			"action_allowed": false,
			"dot_damage": 0,
			"battle_result": battle_result,
		}

	var action_allowed := turn_manager.on_turn_start(unit)
	var dot_damage := turn_manager.on_turn_end(unit)
	check_boss_phase_transition()
	battle_result = check_battle_end()

	return {
		"unit": unit,
		"action_allowed": action_allowed,
		"dot_damage": dot_damage,
		"battle_result": battle_result,
	}


func set_boss_phase_transition_checker(checker: Callable) -> void:
	_boss_phase_transition_checker = checker


func check_boss_phase_transition() -> bool:
	var transitioned := false
	for unit in enemies:
		if not unit.is_alive():
			continue
		if String(unit.tier) != "boss":
			continue
		if int(unit.phases) < 2:
			continue
		if bool(unit.phase_2_triggered):
			continue
		if int(unit.phase_transition_hp) <= 0:
			continue
		var should_transition := int(unit.current_hp) <= int(unit.phase_transition_hp)
		if _boss_phase_transition_checker.is_valid():
			should_transition = bool(_boss_phase_transition_checker.call(int(unit.current_hp)))
		if not should_transition:
			continue
		unit.phase_2_triggered = true
		transitioned = true
		_emit_boss_phase_changed(unit)
	return transitioned


func _emit_boss_phase_changed(unit) -> void:
	var bus = null
	var main_loop = Engine.get_main_loop()
	if main_loop != null and main_loop is SceneTree:
		bus = main_loop.root.get_node_or_null("EventBus")
	if bus == null:
		bus = Engine.get_meta("_event_bus_instance", null)
	if bus != null and bus.has_signal("boss_phase_changed"):
		bus.emit_signal("boss_phase_changed", unit)


func check_battle_end():
	var living_allies := 0
	for unit in allies:
		if unit.is_alive():
			living_allies += 1

	var living_enemies := 0
	for unit in enemies:
		if unit.is_alive():
			living_enemies += 1

	if allies.size() > 0 and living_allies == 0:
		_run_terminated = true
		return "defeat"
	if enemies.size() > 0 and living_enemies == 0:
		_run_terminated = false
		return "victory"
	return null


func run_terminate() -> bool:
	return _run_terminated


func _build_units(configs: Array, ally_flag: bool) -> Array:
	var built: Array = []
	for config_value in configs:
		var unit_config: Dictionary = config_value.duplicate(true)
		unit_config["is_ally"] = ally_flag
		built.append(UNIT_SCRIPT.new(unit_config))
	return built


func _living_units() -> Array:
	var living: Array = []
	for unit in allies:
		if unit.is_alive():
			living.append(unit)
	for unit in enemies:
		if unit.is_alive():
			living.append(unit)
	return living


func _resolve_target_turn_range(enemy_configs: Array) -> Dictionary:
	var highest_priority := "normal"
	for config_value in enemy_configs:
		var tier := str(config_value.get("tier", "normal"))
		if tier == "boss":
			highest_priority = "boss"
			break
		if tier == "elite":
			highest_priority = "elite"
	return TARGET_TURNS_BY_TIER.get(highest_priority, TARGET_TURNS_BY_TIER["normal"]).duplicate(true)
