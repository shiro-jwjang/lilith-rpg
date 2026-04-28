extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_032_charge_slash_applies_bleed_near_thirty_percent() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var skill: Dictionary = content.get_skill("전위딜러", "돌진베기")
	assert_not_null(skill, "content-032 expected 돌진베기 data")
	if skill == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 12032
	var applied := 0
	for _i in range(1000):
		if content.should_apply_status(skill, rng):
			applied += 1
	var rate := float(applied) / 1000.0
	assert_ge(rate, 0.25, "content-032 expected bleed rate >= 0.25")
	assert_true(rate <= 0.35, "content-032 expected bleed rate <= 0.35")


func test_content_033_all_five_status_types_are_defined() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var status_types: Array = content.get_status_types()
	var expected := ["출혈", "화상", "파쇄", "둔화", "약화"]
	assert_eq(status_types.size(), 5, "content-033 expected 5 status types")
	for status_type in expected:
		assert_true(status_types.has(status_type), "content-033 missing status type %s" % status_type)


func _make_content_data():
	var script: Script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()
