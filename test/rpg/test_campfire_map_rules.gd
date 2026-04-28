extends "res://test/rpg/test_base.gd"

const CAMPFIRE_MANAGER_PATH := "res://scripts/rpg/campfire/campfire_manager.gd"


func test_campfire_009_act_campfire_count_never_drops_below_one() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	for _index in range(1000):
		var count := int(manager.roll_campfire_count())
		assert_ge(count, 1, "campfire-009 expected campfire count >= 1")


func test_campfire_010_act_campfire_count_never_exceeds_two() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	for _index in range(1000):
		var count := int(manager.roll_campfire_count())
		assert_true(count <= 2, "campfire-010 expected campfire count <= 2")


func test_campfire_011_act_campfire_count_can_hit_one() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	assert_eq(int(manager.roll_campfire_count({"forced_count": 1})), 1, "campfire-011 expected forced count 1")


func test_campfire_012_act_campfire_count_can_hit_two() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	assert_eq(int(manager.roll_campfire_count({"forced_count": 2})), 2, "campfire-012 expected forced count 2")


func _make_manager(config: Dictionary = {}):
	var script = load(CAMPFIRE_MANAGER_PATH)
	assert_not_null(script, "expected campfire_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)
