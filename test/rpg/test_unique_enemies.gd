extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_010_sealed_gatekeeper_stats_mechanic_and_loop() -> void:
	var enemy := _get_enemy("봉인된 문지기")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 190, "content-010 expected HP 190")
	assert_eq(enemy["attack"], 18, "content-010 expected ATK 18")
	assert_eq(enemy["defense"], 8, "content-010 expected DEF 8")
	assert_eq(enemy["speed"], 11, "content-010 expected SPD 11")
	assert_eq(enemy["mechanic"], "반격", "content-010 expected counter mechanic")
	assert_eq(enemy["pattern"].size(), 3, "content-010 expected 3-turn loop")


func test_content_011_moon_hunter_stats_status_and_loop() -> void:
	var enemy := _get_enemy("달의 사냥꾼")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 176, "content-011 expected HP 176")
	assert_eq(enemy["attack"], 20, "content-011 expected ATK 20")
	assert_eq(enemy["defense"], 6, "content-011 expected DEF 6")
	assert_eq(enemy["speed"], 15, "content-011 expected SPD 15")
	assert_eq(enemy["status_effects"], ["출혈"], "content-011 expected bleed status")
	assert_eq(enemy["pattern"].size(), 4, "content-011 expected 4-turn loop")


func test_content_028_all_unique_mechanics_and_loops_match_spec() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var enemies: Array = content.get_unique_enemies()
	var expected := {
		"봉인된 문지기": {
			"mechanic": "반격",
			"loop": 3,
		},
		"달의 사냥꾼": {
			"status": "출혈",
			"loop": 4,
		},
	}
	assert_eq(enemies.size(), 2, "content-028 expected 2 unique enemies")
	for enemy in enemies:
		var enemy_name: String = str(enemy["name"])
		assert_true(expected.has(enemy_name), "content-028 unexpected unique %s" % enemy_name)
		var rule: Dictionary = expected[enemy_name]
		assert_eq(enemy["pattern"].size(), rule["loop"], "content-028 wrong loop length for %s" % enemy_name)
		if rule.has("mechanic"):
			assert_eq(enemy["mechanic"], rule["mechanic"], "content-028 wrong mechanic for %s" % enemy_name)
		if rule.has("status"):
			assert_true(enemy["status_effects"].has(rule["status"]), "content-028 wrong status for %s" % enemy_name)


func _get_enemy(name: String) -> Dictionary:
	var content = _make_content_data()
	if content == null:
		return {}
	var enemy = content.get_enemy_by_name(name)
	assert_not_null(enemy, "expected enemy data for %s" % name)
	if enemy == null:
		return {}
	return enemy


func _make_content_data():
	var script: Script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()
