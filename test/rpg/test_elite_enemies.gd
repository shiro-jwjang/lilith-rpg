extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_007_iron_watcher_stats_and_loop() -> void:
	var enemy := _get_enemy("철갑 감시자")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 160, "content-007 expected HP 160")
	assert_eq(enemy["attack"], 17, "content-007 expected ATK 17")
	assert_eq(enemy["defense"], 8, "content-007 expected DEF 8")
	assert_eq(enemy["speed"], 10, "content-007 expected SPD 10")
	assert_eq(enemy["pattern"].size(), 3, "content-007 expected 3-turn loop")


func test_content_008_flame_executioner_stats_status_and_loop() -> void:
	var enemy := _get_enemy("화염 집행관")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 148, "content-008 expected HP 148")
	assert_eq(enemy["attack"], 20, "content-008 expected ATK 20")
	assert_eq(enemy["defense"], 6, "content-008 expected DEF 6")
	assert_eq(enemy["speed"], 12, "content-008 expected SPD 12")
	assert_eq(enemy["status_effects"], ["화상"], "content-008 expected burn status")
	assert_eq(enemy["pattern"].size(), 3, "content-008 expected 3-turn loop")


func test_content_009_red_moon_ritualist_stats_statuses_and_loop() -> void:
	var enemy := _get_enemy("붉은 달 의식사")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 138, "content-009 expected HP 138")
	assert_eq(enemy["attack"], 18, "content-009 expected ATK 18")
	assert_eq(enemy["defense"], 7, "content-009 expected DEF 7")
	assert_eq(enemy["speed"], 13, "content-009 expected SPD 13")
	assert_eq(enemy["pattern"].size(), 4, "content-009 expected 4-turn loop")
	assert_true(enemy["status_effects"].has("약화"), "content-009 expected weaken status")
	assert_true(enemy["status_effects"].has("파쇄"), "content-009 expected shatter status")


func test_content_027_all_elite_loop_lengths_match_spec() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var enemies: Array = content.get_elite_enemies()
	var expected_loops := {
		"철갑 감시자": 3,
		"화염 집행관": 3,
		"붉은 달 의식사": 4,
	}
	assert_eq(enemies.size(), 3, "content-027 expected 3 elite enemies")
	for enemy in enemies:
		var enemy_name: String = str(enemy["name"])
		assert_true(expected_loops.has(enemy_name), "content-027 unexpected elite %s" % enemy_name)
		assert_eq(enemy["pattern"].size(), expected_loops[enemy_name], "content-027 wrong loop length for %s" % enemy_name)


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
