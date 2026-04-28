extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_043_validator_rejects_map_with_too_few_treasures() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "combat"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}, "shop"],
		3: ["unique", "boss"],
	})
	var result = _validate(act)
	assert_false(result["ok"], "map-043 expected treasure minimum violation")
	assert_has(result["errors"], "treasure_minimum", "map-043 should report treasure minimum")


func test_map_044_validator_rejects_map_with_too_many_treasures() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "treasure"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}, "treasure"],
		3: ["treasure", "unique", "boss"],
	})
	var result = _validate(act)
	assert_false(result["ok"], "map-044 expected treasure maximum violation")
	assert_has(result["errors"], "treasure_maximum", "map-044 should report treasure maximum")


func test_map_045_validator_rejects_map_with_two_uniques() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "campfire"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}, "unique"],
		3: ["unique", "boss"],
	})
	var result = _validate(act)
	assert_false(result["ok"], "map-045 expected unique count violation")
	assert_has(result["errors"], "unique_exactly_one", "map-045 should report unique count violation")


func test_map_046_validator_rejects_unique_on_floor_one() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "unique"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}],
		3: ["boss"],
	})
	var result = _validate(act)
	assert_false(result["ok"], "map-046 expected unique floor violation")
	assert_has(result["errors"], "unique_floor", "map-046 should report unique floor violation")


func test_map_047_validator_rejects_duplicate_event_catalog_entries() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "campfire"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}, "shop"],
		3: ["unique", {"type": "event", "event_id": "evt_c"}, "boss"],
	}, {"event_catalog": ["evt_a", "evt_a", "evt_b", "evt_c"]})
	var result = _validate(act)
	assert_false(result["ok"], "map-047 expected duplicate event catalog violation")
	assert_has(result["errors"], "event_duplicate", "map-047 should report duplicate events")


func test_map_048_validator_rejects_same_event_on_consecutive_floors() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "campfire"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_a"}, "shop"],
		3: ["unique", {"type": "event", "event_id": "evt_c"}, "boss"],
	})
	var result = _validate(act)
	assert_false(result["ok"], "map-048 expected consecutive event violation")
	assert_has(result["errors"], "event_consecutive_floor", "map-048 should report consecutive event violation")


func test_map_049_validator_rejects_floor_three_without_boss() -> void:
	var act = _helper().build_manual_act({
		1: ["combat", {"type": "event", "event_id": "evt_a"}, "campfire"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}, "shop"],
		3: ["unique", {"type": "event", "event_id": "evt_c"}, {"type": "combat", "tier": "normal"}],
	})
	var result = _validate(act)
	assert_false(result["ok"], "map-049 expected missing boss violation")
	assert_has(result["errors"], "boss_required", "map-049 should report missing boss")


func test_map_050_validator_accepts_a_complete_valid_map() -> void:
	var act = _helper().build_manual_act({
		1: [{"type": "combat", "tier": "normal"}, {"type": "event", "event_id": "evt_a"}, "campfire"],
		2: [{"type": "combat", "tier": "normal"}, {"type": "combat", "tier": "elite"}, {"type": "event", "event_id": "evt_b"}, "shop"],
		3: ["treasure", "unique", "boss"],
	}, {"event_catalog": ["evt_a", "evt_b", "evt_c", "evt_d"]})
	var result = _validate(act)
	assert_true(result["ok"], "map-050 expected valid map to pass validation")
	assert_eq(result["errors"].size(), 0, "map-050 expected no validation errors")


func _validate(act: Dictionary) -> Dictionary:
	var helper = _helper()
	var script = helper.load_script(helper.VALIDATOR_PATH)
	assert_not_null(script, "expected map_validator.gd to exist")
	if script == null:
		return {"ok": false, "errors": ["missing_validator"]}
	var validator = helper.make_validator()
	return validator.validate_act(act)


func _helper():
	return load(HELPER_PATH).new()
