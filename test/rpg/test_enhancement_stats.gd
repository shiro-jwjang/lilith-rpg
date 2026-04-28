extends "res://test/rpg/test_base.gd"

const CALCULATOR_PATH := "res://scripts/rpg/equipment/enhancement_calculator.gd"


func test_equip_012_main_stat_scales_ten_percent_at_plus_one() -> void:
	assert_true(
		is_equal_approx(_scale_stat(5.0, 1), 5.5),
		"equip-012 expected 5.0 to scale to 5.5 at +1"
	)


func test_equip_013_main_stat_scales_twenty_percent_at_plus_two() -> void:
	assert_true(
		is_equal_approx(_scale_stat(5.0, 2), 6.0),
		"equip-013 expected 5.0 to scale to 6.0 at +2"
	)


func test_equip_014_percent_stat_scales_ten_percent_at_plus_one() -> void:
	assert_true(
		is_equal_approx(_scale_stat(3.0, 1), 3.3),
		"equip-014 expected 3.0 percent stat to scale to 3.3 at +1"
	)


func test_equip_015_percent_stat_scales_twenty_percent_at_plus_two() -> void:
	assert_true(
		is_equal_approx(_scale_stat(3.0, 2), 3.6),
		"equip-015 expected 3.0 percent stat to scale to 3.6 at +2"
	)


func _scale_stat(base_value: float, level: int) -> float:
	var calculator = load(CALCULATOR_PATH)
	assert_not_null(calculator, "expected enhancement_calculator.gd to exist")
	if calculator == null:
		return -1.0
	return calculator.scale_stat(base_value, level)
