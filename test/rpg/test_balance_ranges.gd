extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_035_normal_enemy_hp_range() -> void:
	var content = _make_content_data()
	if content == null:
		return
	for enemy in content.get_normal_enemies():
		assert_ge(enemy["max_hp"], 70, "content-035 expected normal HP >= 70 for %s" % enemy["name"])
		assert_true(enemy["max_hp"] <= 95, "content-035 expected normal HP <= 95 for %s" % enemy["name"])


func test_content_036_elite_enemy_hp_range() -> void:
	var content = _make_content_data()
	if content == null:
		return
	for enemy in content.get_elite_enemies():
		assert_ge(enemy["max_hp"], 130, "content-036 expected elite HP >= 130 for %s" % enemy["name"])
		assert_true(enemy["max_hp"] <= 170, "content-036 expected elite HP <= 170 for %s" % enemy["name"])


func test_content_037_unique_enemy_hp_minimum() -> void:
	var content = _make_content_data()
	if content == null:
		return
	for enemy in content.get_unique_enemies():
		assert_ge(enemy["max_hp"], 176, "content-037 expected unique HP >= 176 for %s" % enemy["name"])


func test_content_038_boss_hp_is_at_least_double_unique_max_hp() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var boss: Dictionary = content.get_boss()
	var unique_max_hp := 0
	for enemy in content.get_unique_enemies():
		if enemy["max_hp"] > unique_max_hp:
			unique_max_hp = enemy["max_hp"]
	assert_eq(boss["max_hp"], 450, "content-038 expected boss HP 450")
	assert_eq(unique_max_hp, 190, "content-038 expected unique max HP 190")
	assert_ge(boss["max_hp"], unique_max_hp * 2, "content-038 expected boss HP at least double unique max HP")


func _make_content_data():
	var script: Script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()
