extends "res://test/rpg/test_base.gd"

const DAMAGE_CALCULATOR_PATH := "res://scripts/rpg/combat/damage_calculator.gd"


func test_combat_001_base_damage_normal_case() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.calculate_base_damage(100, 1.2, 30)
	assert_eq(damage, 90, "combat-001 expected floor(100 * 1.2) - 30 = 90")


func test_combat_002_base_damage_minimum_guarantee() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.calculate_base_damage(50, 1.0, 80)
	assert_eq(damage, 1, "combat-002 expected minimum damage of 1")


func test_combat_003_base_damage_zero_boundary() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.calculate_base_damage(100, 0.5, 50)
	assert_eq(damage, 1, "combat-003 expected zero boundary to clamp to 1")


func test_combat_004_base_damage_floor_decimal_coefficient() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.calculate_base_damage(77, 0.7, 10)
	assert_eq(damage, 43, "combat-004 expected floor(77 * 0.7) - 10 = 43")


func test_combat_005_base_damage_zero_defense() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.calculate_base_damage(80, 1.5, 0)
	assert_eq(damage, 120, "combat-005 expected zero DEF to preserve full scaled damage")


func test_combat_006_apply_critical_multiplier() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.apply_critical(100, true, 1.5)
	assert_eq(damage, 150, "combat-006 expected critical to deal 150 damage")


func test_combat_007_apply_critical_no_change_when_not_critical() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.apply_critical(100, false, 1.5)
	assert_eq(damage, 100, "combat-007 expected non-critical to keep base damage")


func test_combat_008_apply_critical_keeps_minimum_damage_at_one() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var base_damage = calculator.calculate_base_damage(10, 1.0, 100)
	var damage = calculator.apply_critical(base_damage, true, 1.5)
	assert_eq(base_damage, 1, "combat-008 setup expected minimum guaranteed base damage")
	assert_eq(damage, 1, "combat-008 expected critical minimum damage to remain 1")


func test_combat_009_fixed_damage_ignores_defense() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var damage = calculator.calculate_fixed_damage(50)
	assert_eq(damage, 50, "combat-009 expected fixed damage to ignore defense")


func test_combat_010_fixed_damage_ignores_critical() -> void:
	var calculator = _load_calculator()
	if calculator == null:
		return
	var fixed_damage = calculator.calculate_fixed_damage(50)
	assert_eq(fixed_damage, 50, "combat-010 expected fixed damage to remain 50 regardless of critical state")


func _load_calculator():
	var calculator = load(DAMAGE_CALCULATOR_PATH)
	assert_not_null(calculator, "expected damage_calculator.gd to exist")
	return calculator
