extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_SCRIPT := preload("res://scripts/rpg/combat/battle_manager.gd")
const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")
const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")


class _BossPhaseSignalCapture extends RefCounted:
	var count := 0
	var last_unit = null

	func on_boss_phase_changed(unit) -> void:
		count += 1
		last_unit = unit


class _StubBossContentData extends RefCounted:
	func get_boss() -> Dictionary:
		return {
			"name": "테스트 보스",
			"tier": "boss",
			"max_hp": 450,
			"attack": 22,
			"defense": 8,
			"speed": 10,
			"phases": 2,
			"phase_transition_hp": 225,
			"status_effects": [],
		}

	func get_normal_enemies() -> Array:
		return []

	func get_elite_enemies() -> Array:
		return []

	func get_unique_enemies() -> Array:
		return []

	func get_skills_for_character(role_name: String) -> Array:
		if role_name == "전위딜러":
			return [{"name": "기본공격", "mp_cost": 0, "multiplier": 1.0, "target": "single"}]
		if role_name == "수호자":
			return [{"name": "기본공격", "mp_cost": 0, "multiplier": 1.0, "target": "single"}]
		return [{"name": "기본공격", "mp_cost": 0, "multiplier": 1.0, "target": "single"}]

	func should_boss_transition_phase(current_hp: int) -> bool:
		return current_hp <= 225


func test_boss_phase_transitions_at_threshold() -> void:
	var manager = BATTLE_MANAGER_SCRIPT.new()
	manager.init_battle([], [_boss_enemy_config()])
	var boss = manager.enemies[0]

	boss.take_damage(225)
	var transitioned := manager.check_boss_phase_transition()

	assert_true(transitioned, "boss should transition when HP reaches the threshold")
	assert_true(bool(boss.phase_2_triggered), "boss should mark phase 2 as triggered")


func test_boss_phase_does_not_retrigger() -> void:
	var manager = BATTLE_MANAGER_SCRIPT.new()
	manager.init_battle([], [_boss_enemy_config()])
	var boss = manager.enemies[0]

	boss.take_damage(225)
	assert_true(manager.check_boss_phase_transition(), "boss should transition on the first threshold check")
	boss.take_damage(10)

	assert_false(manager.check_boss_phase_transition(), "boss phase 2 should not retrigger after it has already fired")
	assert_true(bool(boss.phase_2_triggered), "boss phase 2 flag should remain set")


func test_boss_phase_emits_eventbus_signal() -> void:
	var bus = Engine.get_meta("_event_bus_instance", null)
	assert_not_null(bus, "EventBus autoload should exist for boss phase tests")
	if bus == null:
		return

	var capture = _BossPhaseSignalCapture.new()
	bus.boss_phase_changed.connect(capture.on_boss_phase_changed)

	var manager = BATTLE_MANAGER_SCRIPT.new()
	manager.init_battle([], [_boss_enemy_config()])
	var boss = manager.enemies[0]
	boss.take_damage(225)
	manager.check_boss_phase_transition()

	assert_eq(capture.count, 1, "boss phase transition should emit exactly one EventBus signal")
	assert_eq(capture.last_unit, boss, "boss phase transition should emit the transitioned unit")
	if bus.boss_phase_changed.is_connected(capture.on_boss_phase_changed):
		bus.boss_phase_changed.disconnect(capture.on_boss_phase_changed)


func test_normal_enemy_no_phase_transition() -> void:
	var manager = BATTLE_MANAGER_SCRIPT.new()
	manager.init_battle([], [{
		"name": "일반 적",
		"tier": "normal",
		"max_hp": 100,
		"current_hp": 100,
		"atk": 10,
		"def": 4,
		"speed": 8,
		"phases": 2,
		"phase_transition_hp": 50,
	}])
	var enemy = manager.enemies[0]
	enemy.take_damage(50)

	assert_false(manager.check_boss_phase_transition(), "normal enemies should never trigger boss phase transitions")
	assert_false(bool(enemy.phase_2_triggered), "normal enemies should keep phase 2 disabled")


func test_boss_phase_transition_mid_combat() -> void:
	var runner = GAME_RUNNER_SCRIPT.new({"content_data": _StubBossContentData.new()})
	runner.start_run()
	runner.enter_combat([runner._normalize_enemy_config(_StubBossContentData.new().get_boss())])

	var boss = runner.battle_manager.enemies[0]
	boss.take_damage(224)
	assert_false(runner.battle_manager.check_boss_phase_transition(), "boss should not transition above the threshold")
	assert_false(bool(boss.phase_2_triggered), "boss phase should remain inactive above the threshold")

	boss.take_damage(1)
	assert_true(runner.battle_manager.check_boss_phase_transition(), "boss should transition at the exact threshold mid-combat")
	assert_true(bool(boss.phase_2_triggered), "boss phase should activate once the threshold is crossed")


func _boss_enemy_config() -> Dictionary:
	return {
		"name": "붉은 달의 파수꾼",
		"tier": "boss",
		"max_hp": 450,
		"current_hp": 450,
		"atk": 22,
		"def": 8,
		"speed": 10,
		"phases": 2,
		"phase_transition_hp": 225,
	}
