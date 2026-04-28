extends "res://test/rpg/test_base.gd"

const EFFECTS_PATH := "res://scripts/rpg/equipment/unique_effects.gd"


func test_equip_016_rusty_sword_unlocks_basic_attack_bonus_at_plus_three() -> void:
	var result := _apply_effect("녹슨 검", 3, {"base_attack_coefficient": 1.0})
	assert_true(result["active"], "equip-016 expected effect to be active at +3")
	assert_true(
		is_equal_approx(result["attack_coefficient_bonus"], 0.1),
		"equip-016 expected attack coefficient bonus 0.1"
	)
	assert_true(
		is_equal_approx(result["attack_coefficient"], 1.1),
		"equip-016 expected final attack coefficient 1.1"
	)


func test_equip_017_rusty_sword_effect_stays_locked_below_plus_three() -> void:
	var result := _apply_effect("녹슨 검", 2, {"base_attack_coefficient": 1.0})
	assert_false(result["active"], "equip-017 expected effect to remain inactive at +2")


func test_equip_018_red_moon_dagger_adds_one_bleed_on_critical() -> void:
	var result := _apply_effect("붉은 달 단도", 3, {"critical_hit": true, "bleed_stacks": 0})
	assert_true(result["active"], "equip-018 expected active effect")
	assert_eq(result["bleed_stacks"], 1, "equip-018 expected one bleed stack added")


func test_equip_019_rift_wand_adds_ten_percent_damage_to_debuffed_targets() -> void:
	var result := _apply_effect("균열 완드", 3, {"target_has_debuff": true, "damage_multiplier": 1.0})
	assert_true(result["active"], "equip-019 expected active effect")
	assert_true(
		is_equal_approx(result["damage_multiplier"], 1.1),
		"equip-019 expected damage multiplier 1.1"
	)


func test_equip_020_sturdy_cuirass_reduces_damage_by_ten_percent() -> void:
	var result := _apply_effect("견고한 흉갑", 3, {"incoming_damage": 100, "effect_used": false})
	assert_true(result["active"], "equip-020 expected active effect")
	assert_eq(result["incoming_damage"], 90, "equip-020 expected reduced damage 90")
	assert_true(result["effect_used"], "equip-020 expected effect to mark itself used")


func test_equip_021_sturdy_cuirass_does_not_reduce_second_hit() -> void:
	var result := _apply_effect("견고한 흉갑", 3, {"incoming_damage": 100, "effect_used": true})
	assert_true(result["active"], "equip-021 expected effect definition to exist")
	assert_eq(result["incoming_damage"], 100, "equip-021 expected no further reduction once used")


func test_equip_022_hound_leather_reduces_first_turn_damage_by_five_percent() -> void:
	var result := _apply_effect("사냥견 가죽갑", 3, {"turn_number": 1, "incoming_damage": 100})
	assert_true(result["active"], "equip-022 expected active effect")
	assert_eq(result["incoming_damage"], 95, "equip-022 expected reduced damage 95")


func test_equip_023_ritual_robe_restores_two_mp_on_skill_hit() -> void:
	var result := _apply_effect("의식가 로브", 3, {"skill_hit": true, "current_mp": 7})
	assert_true(result["active"], "equip-023 expected active effect")
	assert_eq(result["current_mp"], 9, "equip-023 expected MP to increase by 2")


func test_equip_024_red_thread_ring_adds_five_percent_bleed_success_chance() -> void:
	var result := _apply_effect("붉은 실 반지", 3, {"bleed_chance": 0.40})
	assert_true(result["active"], "equip-024 expected active effect")
	assert_true(is_equal_approx(result["bleed_chance"], 0.45), "equip-024 expected bleed chance 0.45")


func test_equip_025_moonlight_charm_adds_two_speed_on_first_turn() -> void:
	var result := _apply_effect("달빛 부적", 3, {"turn_number": 1, "speed": 10})
	assert_true(result["active"], "equip-025 expected active effect")
	assert_eq(result["speed"], 12, "equip-025 expected first-turn speed bonus +2")


func test_equip_026_moonlight_charm_does_not_add_speed_after_first_turn() -> void:
	var result := _apply_effect("달빛 부적", 3, {"turn_number": 2, "speed": 10})
	assert_true(result["active"], "equip-026 expected effect definition to exist")
	assert_eq(result["speed"], 10, "equip-026 expected no speed bonus after first turn")


func test_equip_027_shard_necklace_reduces_damage_below_half_hp() -> void:
	var result := _apply_effect("파편 목걸이", 3, {"current_hp": 50, "max_hp": 100, "incoming_damage": 100})
	assert_true(result["active"], "equip-027 expected active effect")
	assert_eq(result["incoming_damage"], 92, "equip-027 expected reduced damage 92")


func test_equip_028_sealed_key_unlocks_one_hidden_choice() -> void:
	var result := _apply_effect("봉인된 열쇠", 3, {"locked_choices": 1, "uses_remaining": 1})
	assert_true(result["active"], "equip-028 expected active effect")
	assert_eq(result["locked_choices"], 0, "equip-028 expected one locked choice to be opened")
	assert_eq(result["uses_remaining"], 0, "equip-028 expected one-time use to be consumed")


func test_equip_029_sleeping_bell_boosts_campfire_and_reduces_event_penalty() -> void:
	var result := _apply_effect("잠든 종", 3, {"campfire_heal": 50.0, "event_penalty": 20.0})
	assert_true(result["active"], "equip-029 expected active effect")
	assert_true(is_equal_approx(result["campfire_heal"], 55.0), "equip-029 expected campfire heal 55.0")
	assert_true(is_equal_approx(result["event_penalty"], 16.0), "equip-029 expected event penalty 16.0")


func test_equip_030_ash_fragment_boosts_burn_damage_and_chance() -> void:
	var result := _apply_effect("재의 조각", 3, {"burn_damage": 10.0, "burn_chance": 0.20})
	assert_true(result["active"], "equip-030 expected active effect")
	assert_true(is_equal_approx(result["burn_damage"], 11.5), "equip-030 expected burn damage 11.5")
	assert_true(is_equal_approx(result["burn_chance"], 0.25), "equip-030 expected burn chance 0.25")


func _apply_effect(equipment_name: String, level: int, context: Dictionary) -> Dictionary:
	var effects = load(EFFECTS_PATH)
	assert_not_null(effects, "expected unique_effects.gd to exist")
	if effects == null:
		return {}
	return effects.apply_effect(equipment_name, level, context)
