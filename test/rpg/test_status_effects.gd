extends "res://test/rpg/test_base.gd"

const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")


func test_unit_has_status_effects_field() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	assert_true(unit.active_statuses is Dictionary, "active_statuses should be a dictionary")
	for effect_type in ["출혈", "화상", "둔화", "약화", "파쇄", "기절"]:
		assert_has(unit.active_statuses, effect_type, "active_statuses should initialize %s" % effect_type)
		assert_eq(int(unit.active_statuses[effect_type]["stacks"]), 0, "%s stacks should default to 0" % effect_type)
		assert_eq(int(unit.active_statuses[effect_type]["duration"]), 0, "%s duration should default to 0" % effect_type)


func test_unit_has_crit_rate_field() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	assert_eq(float(unit.crit_rate), 0.0, "crit_rate should default to 0.0")


func test_unit_has_effect_hit_field() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	assert_eq(float(unit.effect_hit), 0.0, "effect_hit should default to 0.0")


func test_unit_has_effect_resist_field() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	assert_eq(float(unit.effect_resist), 0.0, "effect_resist should default to 0.0")


func test_unit_has_base_speed_field() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100, "speed": 13})
	assert_eq(int(unit.base_speed), 13, "base_speed should preserve the original speed")


func test_apply_status_bleed_basic() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	assert_eq(int(unit.active_statuses["출혈"]["stacks"]), 1, "bleed should start at 1 stack")
	assert_eq(int(unit.active_statuses["출혈"]["duration"]), 3, "bleed should last 3 turns")


func test_apply_status_bleed_stacking() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	unit.apply_status("출혈", 1, 2)
	assert_eq(int(unit.active_statuses["출혈"]["stacks"]), 2, "bleed should stack on reapply")
	assert_eq(int(unit.active_statuses["출혈"]["duration"]), 2, "bleed duration should refresh to the new value")


func test_apply_status_bleed_max_stacks() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 1)
	unit.apply_status("출혈", 1, 1)
	unit.apply_status("출혈", 1, 1)
	unit.apply_status("출혈", 1, 3)
	assert_eq(int(unit.active_statuses["출혈"]["stacks"]), 3, "bleed should cap at 3 stacks")
	assert_eq(int(unit.active_statuses["출혈"]["duration"]), 3, "bleed duration should still refresh at max stacks")


func test_apply_status_slow_no_stacking() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("둔화", 1, 2)
	unit.apply_status("둔화", 1, 1)
	assert_eq(int(unit.active_statuses["둔화"]["stacks"]), 1, "slow should not stack")
	assert_eq(int(unit.active_statuses["둔화"]["duration"]), 1, "slow duration should refresh")


func test_apply_status_weaken_no_stacking() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("약화", 1, 2)
	unit.apply_status("약화", 1, 1)
	assert_eq(int(unit.active_statuses["약화"]["stacks"]), 1, "weaken should not stack")
	assert_eq(int(unit.active_statuses["약화"]["duration"]), 1, "weaken duration should refresh")


func test_apply_status_stun_no_stacking() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("기절", 1, 1)
	unit.apply_status("기절", 1, 1)
	assert_eq(int(unit.active_statuses["기절"]["stacks"]), 1, "stun should not stack")
	assert_eq(int(unit.active_statuses["기절"]["duration"]), 1, "stun duration should refresh")


func test_has_status_true() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	assert_true(bool(unit.has_status("출혈")), "has_status should return true for active bleed")


func test_has_status_false() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	assert_false(bool(unit.has_status("출혈")), "has_status should return false when the status is absent")


func test_get_status_returns_dict() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	var status = unit.get_status("출혈")
	assert_true(status is Dictionary, "get_status should return a dictionary")
	assert_eq(int(status["stacks"]), 1, "get_status should include stacks")
	assert_eq(int(status["duration"]), 3, "get_status should include duration")


func test_process_turn_end_bleed_damage() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	unit.process_turn_end_status()
	assert_eq(int(unit.current_hp), 95, "1-stack bleed should deal 5 damage on 100 max_hp")


func test_process_turn_end_bleed_multi_stack() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 3, 3)
	unit.process_turn_end_status()
	assert_eq(int(unit.current_hp), 85, "3-stack bleed should deal 15 damage on 100 max_hp")


func test_process_turn_end_burn_damage() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("화상", 1, 3)
	unit.process_turn_end_status()
	assert_eq(int(unit.current_hp), 94, "1-stack burn should deal 6 damage on 100 max_hp")


func test_process_turn_end_decrements_duration() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	unit.process_turn_end_status()
	assert_eq(int(unit.active_statuses["출혈"]["duration"]), 2, "duration should decrement by 1 at turn end")


func test_process_turn_end_removes_expired() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 1)
	unit.process_turn_end_status()
	assert_eq(int(unit.active_statuses["출혈"]["stacks"]), 0, "expired bleed should clear stacks")
	assert_eq(int(unit.active_statuses["출혈"]["duration"]), 0, "expired bleed should clear duration")


func test_process_turn_end_returns_tick_info() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 1, 3)
	unit.apply_status("화상", 1, 3)
	var result = unit.process_turn_end_status()
	assert_true(result is Dictionary, "process_turn_end_status should return a dictionary")
	assert_eq(int(result["tick_damage"]), 11, "tick_damage should total bleed and burn damage")
	assert_true(result["tick_types"] is Array, "tick_types should be an array")
	assert_has(result["tick_types"], "출혈", "tick_types should include bleed")
	assert_has(result["tick_types"], "화상", "tick_types should include burn")


func test_clear_all_statuses() -> void:
	var unit = UNIT_SCRIPT.new({"name": "테스트", "max_hp": 100})
	unit.apply_status("출혈", 2, 3)
	unit.apply_status("화상", 1, 3)
	unit.apply_status("둔화", 1, 2)
	unit.clear_all_statuses()
	for effect_type in unit.active_statuses:
		assert_eq(int(unit.active_statuses[effect_type]["stacks"]), 0, "%s stacks should reset to 0" % effect_type)
		assert_eq(int(unit.active_statuses[effect_type]["duration"]), 0, "%s duration should reset to 0" % effect_type)
