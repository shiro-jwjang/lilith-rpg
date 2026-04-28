extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_031_generated_nodes_only_use_allowed_types() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var allowed := {
		"combat": true,
		"event": true,
		"treasure": true,
		"shop": true,
		"campfire": true,
		"unique": true,
		"boss": true,
	}
	var helper = _helper()
	for node in helper.flatten_nodes(act):
		assert_true(allowed.has(node.type), "map-031 unexpected node type %s" % node.type)


func test_map_032_invalid_node_type_is_rejected() -> void:
	var helper = _helper()
	var script = helper.load_script(helper.NODE_PATH)
	assert_not_null(script, "expected node.gd to exist")
	if script == null:
		return
	var result = script.validate_type("invalid_type")
	assert_false(result["ok"], "map-032 invalid node type should be rejected")
	assert_has(result, "error", "map-032 invalid node type should provide an error message")


func _generate_act() -> Dictionary:
	var helper = _helper()
	var script = helper.load_script(helper.GENERATOR_PATH)
	assert_not_null(script, "expected map_generator.gd to exist")
	if script == null:
		return {}
	return helper.generate_act()


func _helper():
	return load(HELPER_PATH).new()
