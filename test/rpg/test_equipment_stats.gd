extends "res://test/rpg/test_base.gd"

const INSTANCE_PATH := "res://scripts/rpg/equipment/equipment_instance.gd"


func test_equip_031_rusty_sword_base_stats() -> void:
	var item = _make_item("녹슨 검")
	assert_eq(item.get_slot(), "weapon", "equip-031 expected weapon slot")
	assert_eq(item.get_grade(), "normal", "equip-031 expected normal grade")
	assert_eq(item.get_stats()["atk"], 4, "equip-031 expected ATK +4")


func test_equip_032_red_moon_dagger_base_stats() -> void:
	var item = _make_item("붉은 달 단도")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "weapon", "equip-032 expected weapon slot")
	assert_eq(item.get_grade(), "high", "equip-032 expected high grade")
	assert_eq(stats["atk"], 3, "equip-032 expected ATK +3")
	assert_eq(stats["spd"], 2, "equip-032 expected SPD +2")
	assert_true(is_equal_approx(stats["crit"], 0.05), "equip-032 expected CRIT +5%")


func test_equip_033_rift_wand_base_stats() -> void:
	var item = _make_item("균열 완드")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "weapon", "equip-033 expected weapon slot")
	assert_eq(item.get_grade(), "rare", "equip-033 expected rare grade")
	assert_eq(stats["atk"], 2, "equip-033 expected ATK +2")
	assert_eq(stats["mp"], 4, "equip-033 expected MP +4")
	assert_true(is_equal_approx(stats["effect_hit"], 0.10), "equip-033 expected E.Hit +10%")


func test_equip_034_sturdy_cuirass_base_stats() -> void:
	var item = _make_item("견고한 흉갑")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "armor", "equip-034 expected armor slot")
	assert_eq(item.get_grade(), "normal", "equip-034 expected normal grade")
	assert_eq(stats["hp"], 18, "equip-034 expected HP +18")
	assert_eq(stats["def"], 3, "equip-034 expected DEF +3")


func test_equip_035_hound_leather_base_stats() -> void:
	var item = _make_item("사냥견 가죽갑")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "armor", "equip-035 expected armor slot")
	assert_eq(item.get_grade(), "high", "equip-035 expected high grade")
	assert_eq(stats["hp"], 12, "equip-035 expected HP +12")
	assert_eq(stats["def"], 2, "equip-035 expected DEF +2")
	assert_eq(stats["spd"], 3, "equip-035 expected SPD +3")


func test_equip_036_ritual_robe_base_stats() -> void:
	var item = _make_item("의식가 로브")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "armor", "equip-036 expected armor slot")
	assert_eq(item.get_grade(), "rare", "equip-036 expected rare grade")
	assert_eq(stats["hp"], 10, "equip-036 expected HP +10")
	assert_eq(stats["def"], 1, "equip-036 expected DEF +1")
	assert_true(is_equal_approx(stats["effect_hit"], 0.08), "equip-036 expected E.Hit +8%")
	assert_true(is_equal_approx(stats["effect_resist"], 0.05), "equip-036 expected E.Resist +5%")


func test_equip_037_red_thread_ring_base_stats() -> void:
	var item = _make_item("붉은 실 반지")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "accessory", "equip-037 expected accessory slot")
	assert_eq(item.get_grade(), "normal", "equip-037 expected normal grade")
	assert_true(is_equal_approx(stats["crit"], 0.04), "equip-037 expected CRIT +4%")
	assert_true(is_equal_approx(stats["effect_hit"], 0.04), "equip-037 expected E.Hit +4%")


func test_equip_038_moonlight_charm_base_stats() -> void:
	var item = _make_item("달빛 부적")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "accessory", "equip-038 expected accessory slot")
	assert_eq(item.get_grade(), "high", "equip-038 expected high grade")
	assert_eq(stats["spd"], 4, "equip-038 expected SPD +4")
	assert_true(is_equal_approx(stats["effect_resist"], 0.05), "equip-038 expected E.Resist +5%")


func test_equip_039_shard_necklace_base_stats() -> void:
	var item = _make_item("파편 목걸이")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "accessory", "equip-039 expected accessory slot")
	assert_eq(item.get_grade(), "rare", "equip-039 expected rare grade")
	assert_eq(stats["hp"], 14, "equip-039 expected HP +14")
	assert_true(is_equal_approx(stats["crit"], 0.03), "equip-039 expected CRIT +3%")
	assert_true(is_equal_approx(stats["effect_hit"], 0.06), "equip-039 expected E.Hit +6%")


func test_equip_040_sealed_key_base_stats() -> void:
	var item = _make_item("봉인된 열쇠")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "trinket", "equip-040 expected trinket slot")
	assert_eq(item.get_grade(), "normal", "equip-040 expected normal grade")
	assert_eq(stats["gold_bonus"], 15, "equip-040 expected Gold +15")


func test_equip_041_sleeping_bell_base_stats() -> void:
	var item = _make_item("잠든 종")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "trinket", "equip-041 expected trinket slot")
	assert_eq(item.get_grade(), "high", "equip-041 expected high grade")
	assert_true(is_equal_approx(stats["campfire_heal"], 0.10), "equip-041 expected campfire heal +10%")


func test_equip_042_ash_fragment_base_stats() -> void:
	var item = _make_item("재의 조각")
	var stats = item.get_stats()
	assert_eq(item.get_slot(), "trinket", "equip-042 expected trinket slot")
	assert_eq(item.get_grade(), "rare", "equip-042 expected rare grade")
	assert_true(is_equal_approx(stats["burn_damage"], 0.15), "equip-042 expected burn damage +15%")
	assert_true(is_equal_approx(stats["burn_chance"], 0.05), "equip-042 expected burn chance +5%")


func _make_item(equipment_name: String):
	var instance_script = load(INSTANCE_PATH)
	assert_not_null(instance_script, "expected equipment_instance.gd to exist")
	if instance_script == null:
		return null
	return instance_script.new(equipment_name, 0)
