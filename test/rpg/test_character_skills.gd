extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_014_front_basic_attack() -> void:
	_assert_damage_skill("전위딜러", "기본공격", 0, "single", 1.0, [], 0.0, "content-014")


func test_content_015_front_heavy_strike() -> void:
	_assert_damage_skill("전위딜러", "강타", 5, "single", 1.3, [], 0.0, "content-015")


func test_content_016_front_charge_slash() -> void:
	_assert_damage_skill("전위딜러", "돌진베기", 8, "single", 1.6, ["출혈"], 0.3, "content-016")


func test_content_017_front_whirlwind() -> void:
	_assert_damage_skill("전위딜러", "회전참격", 12, "all", 0.7, [], 0.0, "content-017")


func test_content_018_guardian_basic_attack() -> void:
	_assert_damage_skill("수호자", "기본공격", 0, "single", 1.0, [], 0.0, "content-018")


func test_content_019_guardian_defense_stance() -> void:
	var skill := _get_skill("수호자", "방어태세")
	if skill.is_empty():
		return
	assert_eq(skill["mp_cost"], 3, "content-019 expected 3 MP")
	assert_eq(skill["target"], "self", "content-019 expected self target")
	assert_eq(skill["effect"], "def_boost", "content-019 expected def_boost effect")
	assert_eq(skill["value"], 0.3, "content-019 expected +30 percent defense")


func test_content_020_guardian_taunt() -> void:
	var skill := _get_skill("수호자", "도발")
	if skill.is_empty():
		return
	assert_eq(skill["mp_cost"], 5, "content-020 expected 5 MP")
	assert_eq(skill["target"], "all_enemies", "content-020 expected all enemies target")
	assert_eq(skill["effect"], "taunt", "content-020 expected taunt effect")


func test_content_021_guardian_shield_bash() -> void:
	_assert_damage_skill("수호자", "방패타격", 8, "single", 1.3, ["둔화"], 0.4, "content-021")


func test_content_022_support_basic_attack() -> void:
	_assert_damage_skill("마법지원가", "기본공격", 0, "single", 1.0, [], 0.0, "content-022")


func test_content_023_support_flame() -> void:
	_assert_damage_skill("마법지원가", "화염", 6, "single", 1.3, ["화상"], 0.35, "content-023")


func test_content_024_support_heal() -> void:
	var skill := _get_skill("마법지원가", "치유")
	if skill.is_empty():
		return
	assert_eq(skill["mp_cost"], 8, "content-024 expected 8 MP")
	assert_eq(skill["target"], "ally_single", "content-024 expected ally_single target")
	assert_eq(skill["effect"], "heal_max_hp_percent", "content-024 expected heal effect")
	assert_eq(skill["value"], 0.2, "content-024 expected 20 percent heal")


func test_content_025_support_weaken_curse() -> void:
	_assert_damage_skill("마법지원가", "약화저주", 10, "single", 0.8, ["약화"], 0.5, "content-025")


func test_content_029_all_character_skills_registered() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var expected_counts := {
		"전위딜러": 4,
		"수호자": 4,
		"마법지원가": 4,
	}
	var total := 0
	for character_name in expected_counts:
		var skills: Array = content.get_skills_for_character(character_name)
		assert_eq(skills.size(), expected_counts[character_name], "content-029 wrong skill count for %s" % character_name)
		total += skills.size()
	assert_eq(total, 12, "content-029 expected 12 total skills")


func test_content_030_mp_is_spent_when_casting_mp_skill() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var skill := _get_skill("전위딜러", "강타")
	if skill.is_empty():
		return
	assert_eq(content.spend_mp(10, skill), 5, "content-030 expected 5 MP remaining after 강타")


func test_content_031_skill_cannot_be_used_without_enough_mp() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var skill := _get_skill("전위딜러", "회전참격")
	if skill.is_empty():
		return
	assert_false(content.can_use_skill(5, skill), "content-031 expected 회전참격 to be unusable at 5 MP")


func _assert_damage_skill(character_name: String, skill_name: String, mp_cost: int, target: String, multiplier: float, status_effects: Array, status_chance: float, test_id: String) -> void:
	var skill := _get_skill(character_name, skill_name)
	if skill.is_empty():
		return
	assert_eq(skill["mp_cost"], mp_cost, "%s expected MP %d" % [test_id, mp_cost])
	assert_eq(skill["target"], target, "%s expected target %s" % [test_id, target])
	assert_eq(skill["multiplier"], multiplier, "%s expected multiplier %s" % [test_id, multiplier])
	assert_eq(skill["status_effects"], status_effects, "%s expected statuses %s" % [test_id, str(status_effects)])
	assert_eq(skill["status_chance"], status_chance, "%s expected status chance %s" % [test_id, status_chance])


func _get_skill(character_name: String, skill_name: String) -> Dictionary:
	var content = _make_content_data()
	if content == null:
		return {}
	var skill = content.get_skill(character_name, skill_name)
	assert_not_null(skill, "expected skill data for %s/%s" % [character_name, skill_name])
	if skill == null:
		return {}
	return skill


func _make_content_data():
	var script: Script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()
