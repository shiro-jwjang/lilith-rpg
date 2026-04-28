extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_001_rust_swordsman_stats() -> void:
	var enemy := _get_enemy("녹슨 검병")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 82, "content-001 expected HP 82")
	assert_eq(enemy["attack"], 13, "content-001 expected ATK 13")
	assert_eq(enemy["defense"], 5, "content-001 expected DEF 5")
	assert_eq(enemy["speed"], 10, "content-001 expected SPD 10")
	assert_eq(enemy["status_effects"], [], "content-001 expected no special status")


func test_content_002_red_hound_stats() -> void:
	var enemy := _get_enemy("붉은 사냥견")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 74, "content-002 expected HP 74")
	assert_eq(enemy["attack"], 14, "content-002 expected ATK 14")
	assert_eq(enemy["defense"], 4, "content-002 expected DEF 4")
	assert_eq(enemy["speed"], 12, "content-002 expected SPD 12")
	assert_eq(enemy["status_effects"], ["출혈"], "content-002 expected bleed status")


func test_content_003_charred_archer_stats() -> void:
	var enemy := _get_enemy("그을린 궁수")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 76, "content-003 expected HP 76")
	assert_eq(enemy["attack"], 15, "content-003 expected ATK 15")
	assert_eq(enemy["defense"], 4, "content-003 expected DEF 4")
	assert_eq(enemy["speed"], 11, "content-003 expected SPD 11")
	assert_eq(enemy["status_effects"], ["화상"], "content-003 expected burn status")


func test_content_004_shatter_butler_stats() -> void:
	var enemy := _get_enemy("파쇄 집사")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 88, "content-004 expected HP 88")
	assert_eq(enemy["attack"], 12, "content-004 expected ATK 12")
	assert_eq(enemy["defense"], 6, "content-004 expected DEF 6")
	assert_eq(enemy["speed"], 9, "content-004 expected SPD 9")
	assert_eq(enemy["status_effects"], ["파쇄"], "content-004 expected shatter status")


func test_content_005_rift_soldier_stats() -> void:
	var enemy := _get_enemy("균열 병졸")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 90, "content-005 expected HP 90")
	assert_eq(enemy["attack"], 12, "content-005 expected ATK 12")
	assert_eq(enemy["defense"], 5, "content-005 expected DEF 5")
	assert_eq(enemy["speed"], 10, "content-005 expected SPD 10")
	assert_eq(enemy["status_effects"], ["둔화"], "content-005 expected slow status")


func test_content_006_moon_priest_stats() -> void:
	var enemy := _get_enemy("달빛 사제")
	if enemy.is_empty():
		return
	assert_eq(enemy["max_hp"], 79, "content-006 expected HP 79")
	assert_eq(enemy["attack"], 13, "content-006 expected ATK 13")
	assert_eq(enemy["defense"], 4, "content-006 expected DEF 4")
	assert_eq(enemy["speed"], 11, "content-006 expected SPD 11")
	assert_eq(enemy["status_effects"], ["약화"], "content-006 expected weaken status")


func test_content_026_all_normal_enemies_exist_with_unique_ids() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var enemies: Array = content.get_normal_enemies()
	var expected_names := [
		"녹슨 검병",
		"붉은 사냥견",
		"그을린 궁수",
		"파쇄 집사",
		"균열 병졸",
		"달빛 사제",
	]
	assert_eq(enemies.size(), 6, "content-026 expected 6 normal enemies")
	var ids := {}
	var names := {}
	for enemy in enemies:
		assert_has(enemy, "enemy_id", "content-026 expected enemy_id field")
		assert_false(ids.has(enemy["enemy_id"]), "content-026 enemy IDs must be unique")
		ids[enemy["enemy_id"]] = true
		names[enemy["name"]] = true
	for name in expected_names:
		assert_true(names.has(name), "content-026 missing normal enemy %s" % name)


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
