extends "res://test/rpg/test_base.gd"

const CHARACTER_PATH := "res://scripts/rpg/data/character_record.gd"
const SKILL_PATH := "res://scripts/rpg/data/skill_record.gd"
const ENEMY_PATH := "res://scripts/rpg/data/enemy_record.gd"
const RELIC_PATH := "res://scripts/rpg/data/relic_record.gd"
const EQUIPMENT_PATH := "res://scripts/rpg/data/equipment_record.gd"
const NODE_PATH := "res://scripts/rpg/data/node_record.gd"
const EVENT_PATH := "res://scripts/rpg/data/event_record.gd"
const REWARD_PATH := "res://scripts/rpg/data/reward_record.gd"
const REGISTRY_PATH := "res://scripts/rpg/data/table_registry.gd"


func test_datatable_001_character_required_fields_exist() -> void:
	var result := _validate_record(CHARACTER_PATH, _character_record())
	assert_true(result["ok"], "datatable-001 expected valid character record")
	assert_eq(result["errors"].size(), 0, "datatable-001 expected no validation errors")


func test_datatable_002_character_missing_required_fields_errors() -> void:
	var result := _validate_record(CHARACTER_PATH, {
		"character_id": "char_001",
		"name": "Doki",
	})
	assert_false(result["ok"], "datatable-002 expected invalid character record")
	assert_has_all_strings(result["errors"], [
		"role",
		"max_hp",
		"max_mp",
		"attack",
		"defense",
		"speed",
		"crit_rate",
		"effect_accuracy",
		"effect_resistance",
		"skill_ids",
	], "datatable-002 missing field list mismatch")


func test_datatable_003_character_role_front_valid() -> void:
	var record := _character_record()
	record["role"] = "front"
	var result := _validate_record(CHARACTER_PATH, record)
	assert_true(result["ok"], "datatable-003 front should be valid")


func test_datatable_004_character_role_guardian_valid() -> void:
	var record := _character_record()
	record["role"] = "guardian"
	var result := _validate_record(CHARACTER_PATH, record)
	assert_true(result["ok"], "datatable-004 guardian should be valid")


func test_datatable_005_character_role_support_valid() -> void:
	var record := _character_record()
	record["role"] = "support"
	var result := _validate_record(CHARACTER_PATH, record)
	assert_true(result["ok"], "datatable-005 support should be valid")


func test_datatable_006_character_role_invalid_rejected() -> void:
	var record := _character_record()
	record["role"] = "healer"
	var result := _validate_record(CHARACTER_PATH, record)
	assert_false(result["ok"], "datatable-006 invalid role should fail")
	assert_has_error_text(result["errors"], "role", "datatable-006 expected role error")


func test_datatable_007_character_max_hp_zero_rejected() -> void:
	var record := _character_record()
	record["max_hp"] = 0
	var result := _validate_record(CHARACTER_PATH, record)
	assert_false(result["ok"], "datatable-007 max_hp=0 should fail")
	assert_has_error_text(result["errors"], "max_hp", "datatable-007 expected max_hp error")


func test_datatable_008_character_max_hp_positive_allowed() -> void:
	var record := _character_record()
	record["max_hp"] = 100
	var result := _validate_record(CHARACTER_PATH, record)
	assert_true(result["ok"], "datatable-008 max_hp=100 should pass")


func test_datatable_009_character_crit_rate_in_range() -> void:
	var record := _character_record()
	record["crit_rate"] = 0.15
	var result := _validate_record(CHARACTER_PATH, record)
	assert_true(result["ok"], "datatable-009 crit_rate in range should pass")


func test_datatable_010_character_crit_rate_out_of_range_rejected() -> void:
	var record := _character_record()
	record["crit_rate"] = 1.5
	var result := _validate_record(CHARACTER_PATH, record)
	assert_false(result["ok"], "datatable-010 crit_rate=1.5 should fail")
	assert_has_error_text(result["errors"], "crit_rate", "datatable-010 expected crit_rate error")


func test_datatable_011_skill_required_fields_exist() -> void:
	var result := _validate_record(SKILL_PATH, _skill_record())
	assert_true(result["ok"], "datatable-011 expected valid skill record")
	assert_eq(result["errors"].size(), 0, "datatable-011 expected no validation errors")


func test_datatable_012_skill_target_type_all_valid_values() -> void:
	for target_type in ["single_enemy", "all_enemies", "single_ally", "all_allies", "self"]:
		var record := _skill_record()
		record["target_type"] = target_type
		var result := _validate_record(SKILL_PATH, record)
		assert_true(result["ok"], "datatable-012 target_type=%s should pass" % target_type)


func test_datatable_013_skill_target_type_invalid_rejected() -> void:
	var record := _skill_record()
	record["target_type"] = "random"
	var result := _validate_record(SKILL_PATH, record)
	assert_false(result["ok"], "datatable-013 invalid target_type should fail")
	assert_has_error_text(result["errors"], "target_type", "datatable-013 expected target_type error")


func test_datatable_014_skill_mp_cost_negative_rejected() -> void:
	var record := _skill_record()
	record["mp_cost"] = -1
	var result := _validate_record(SKILL_PATH, record)
	assert_false(result["ok"], "datatable-014 negative mp_cost should fail")
	assert_has_error_text(result["errors"], "mp_cost", "datatable-014 expected mp_cost error")


func test_datatable_015_skill_mp_cost_zero_allowed() -> void:
	var record := _skill_record()
	record["mp_cost"] = 0
	var result := _validate_record(SKILL_PATH, record)
	assert_true(result["ok"], "datatable-015 mp_cost=0 should pass")


func test_datatable_016_skill_damage_ratio_negative_rejected() -> void:
	var record := _skill_record()
	record["damage_ratio"] = -0.5
	var result := _validate_record(SKILL_PATH, record)
	assert_false(result["ok"], "datatable-016 negative damage_ratio should fail")
	assert_has_error_text(result["errors"], "damage_ratio", "datatable-016 expected damage_ratio error")


func test_datatable_017_skill_base_status_chance_in_range() -> void:
	var record := _skill_record()
	record["base_status_chance"] = 0.3
	var result := _validate_record(SKILL_PATH, record)
	assert_true(result["ok"], "datatable-017 base_status_chance in range should pass")


func test_datatable_018_skill_base_status_chance_out_of_range_rejected() -> void:
	var record := _skill_record()
	record["base_status_chance"] = 1.2
	var result := _validate_record(SKILL_PATH, record)
	assert_false(result["ok"], "datatable-018 base_status_chance=1.2 should fail")
	assert_has_error_text(result["errors"], "base_status_chance", "datatable-018 expected base_status_chance error")


func test_datatable_019_enemy_required_fields_exist() -> void:
	var result := _validate_record(ENEMY_PATH, _enemy_record())
	assert_true(result["ok"], "datatable-019 expected valid enemy record")
	assert_eq(result["errors"].size(), 0, "datatable-019 expected no validation errors")


func test_datatable_020_enemy_tier_all_valid_values() -> void:
	for tier in ["normal", "elite", "unique", "boss"]:
		var record := _enemy_record()
		record["tier"] = tier
		var result := _validate_record(ENEMY_PATH, record)
		assert_true(result["ok"], "datatable-020 tier=%s should pass" % tier)


func test_datatable_021_enemy_tier_invalid_rejected() -> void:
	var record := _enemy_record()
	record["tier"] = "legendary"
	var result := _validate_record(ENEMY_PATH, record)
	assert_false(result["ok"], "datatable-021 invalid tier should fail")
	assert_has_error_text(result["errors"], "tier", "datatable-021 expected tier error")


func test_datatable_022_enemy_boss_max_hp_positive_allowed() -> void:
	var record := _enemy_record()
	record["tier"] = "boss"
	record["max_hp"] = 500
	var result := _validate_record(ENEMY_PATH, record)
	assert_true(result["ok"], "datatable-022 boss max_hp positive should pass")


func test_datatable_023_relic_required_fields_exist() -> void:
	var result := _validate_record(RELIC_PATH, _relic_record())
	assert_true(result["ok"], "datatable-023 expected valid relic record")
	assert_eq(result["errors"].size(), 0, "datatable-023 expected no validation errors")


func test_datatable_024_relic_missing_required_fields_errors() -> void:
	var result := _validate_record(RELIC_PATH, {
		"relic_id": "rel_001",
	})
	assert_false(result["ok"], "datatable-024 expected invalid relic record")
	assert_has_all_strings(result["errors"], [
		"name",
		"rarity",
		"trigger_condition",
		"effect_text",
		"stack_rule",
	], "datatable-024 missing field list mismatch")


func test_datatable_025_equipment_required_fields_exist() -> void:
	var result := _validate_record(EQUIPMENT_PATH, _equipment_record())
	assert_true(result["ok"], "datatable-025 expected valid equipment record")
	assert_eq(result["errors"].size(), 0, "datatable-025 expected no validation errors")


func test_datatable_026_equipment_slot_all_valid_values() -> void:
	for slot in ["weapon", "armor", "accessory", "trinket"]:
		var record := _equipment_record()
		record["slot"] = slot
		var result := _validate_record(EQUIPMENT_PATH, record)
		assert_true(result["ok"], "datatable-026 slot=%s should pass" % slot)


func test_datatable_027_equipment_slot_invalid_rejected() -> void:
	var record := _equipment_record()
	record["slot"] = "helmet"
	var result := _validate_record(EQUIPMENT_PATH, record)
	assert_false(result["ok"], "datatable-027 invalid slot should fail")
	assert_has_error_text(result["errors"], "slot", "datatable-027 expected slot error")


func test_datatable_028_equipment_upgrade_level_max_one_allowed() -> void:
	var record := _equipment_record()
	record["upgrade_level_max"] = 1
	var result := _validate_record(EQUIPMENT_PATH, record)
	assert_true(result["ok"], "datatable-028 upgrade_level_max=1 should pass")


func test_datatable_029_equipment_upgrade_level_max_zero_rejected() -> void:
	var record := _equipment_record()
	record["upgrade_level_max"] = 0
	var result := _validate_record(EQUIPMENT_PATH, record)
	assert_false(result["ok"], "datatable-029 upgrade_level_max=0 should fail")
	assert_has_error_text(result["errors"], "upgrade_level_max", "datatable-029 expected upgrade_level_max error")


func test_datatable_030_node_required_fields_exist() -> void:
	var result := _validate_record(NODE_PATH, _node_record())
	assert_true(result["ok"], "datatable-030 expected valid node record")
	assert_eq(result["errors"].size(), 0, "datatable-030 expected no validation errors")


func test_datatable_031_node_type_all_valid_values() -> void:
	for node_type in ["combat", "event", "treasure", "shop", "campfire", "unique", "boss"]:
		var record := _node_record()
		record["node_type"] = node_type
		var result := _validate_record(NODE_PATH, record)
		assert_true(result["ok"], "datatable-031 node_type=%s should pass" % node_type)


func test_datatable_032_node_type_invalid_rejected() -> void:
	var record := _node_record()
	record["node_type"] = "minigame"
	var result := _validate_record(NODE_PATH, record)
	assert_false(result["ok"], "datatable-032 invalid node_type should fail")
	assert_has_error_text(result["errors"], "node_type", "datatable-032 expected node_type error")


func test_datatable_033_node_outgoing_edges_empty_array_allowed() -> void:
	var record := _node_record()
	record["outgoing_edges"] = []
	var result := _validate_record(NODE_PATH, record)
	assert_true(result["ok"], "datatable-033 empty outgoing_edges should pass")


func test_datatable_034_event_required_fields_exist() -> void:
	var result := _validate_record(EVENT_PATH, _event_record())
	assert_true(result["ok"], "datatable-034 expected valid event record")
	assert_eq(result["errors"].size(), 0, "datatable-034 expected no validation errors")


func test_datatable_035_event_options_two_allowed() -> void:
	var record := _event_record()
	record["options"] = [
		{"text": "A", "outcome": "success"},
		{"text": "B", "outcome": "neutral"},
	]
	var result := _validate_record(EVENT_PATH, record)
	assert_true(result["ok"], "datatable-035 two options should pass")


func test_datatable_036_event_options_one_rejected() -> void:
	var record := _event_record()
	record["options"] = [
		{"text": "A", "outcome": "success"},
	]
	var result := _validate_record(EVENT_PATH, record)
	assert_false(result["ok"], "datatable-036 one option should fail")
	assert_has_error_text(result["errors"], "options", "datatable-036 expected options error")


func test_datatable_037_event_options_empty_rejected() -> void:
	var record := _event_record()
	record["options"] = []
	var result := _validate_record(EVENT_PATH, record)
	assert_false(result["ok"], "datatable-037 empty options should fail")
	assert_has_error_text(result["errors"], "options", "datatable-037 expected options error")


func test_datatable_038_event_options_three_allowed() -> void:
	var record := _event_record()
	record["options"] = [
		{"text": "A"},
		{"text": "B"},
		{"text": "C"},
	]
	var result := _validate_record(EVENT_PATH, record)
	assert_true(result["ok"], "datatable-038 three options should pass")


func test_datatable_039_event_missing_required_fields_errors() -> void:
	var result := _validate_record(EVENT_PATH, {
		"event_id": "evt_001",
	})
	assert_false(result["ok"], "datatable-039 expected invalid event record")
	assert_has_all_strings(result["errors"], [
		"title",
		"options",
		"required_conditions",
		"success_outcomes",
		"failure_outcomes",
		"followup_node_type",
	], "datatable-039 missing field list mismatch")


func test_datatable_040_reward_required_fields_exist() -> void:
	var result := _validate_record(REWARD_PATH, _reward_record())
	assert_true(result["ok"], "datatable-040 expected valid reward record")
	assert_eq(result["errors"].size(), 0, "datatable-040 expected no validation errors")


func test_datatable_041_reward_missing_required_fields_errors() -> void:
	var result := _validate_record(REWARD_PATH, {
		"reward_group_id": "rwg_001",
	})
	assert_false(result["ok"], "datatable-041 expected invalid reward record")
	assert_has_all_strings(result["errors"], [
		"guaranteed_rewards",
		"optional_rewards",
		"selection_count",
		"rarity_floor",
		"pity_rule",
	], "datatable-041 missing field list mismatch")


func test_datatable_042_reward_selection_count_zero_allowed() -> void:
	var record := _reward_record()
	record["selection_count"] = 0
	var result := _validate_record(REWARD_PATH, record)
	assert_true(result["ok"], "datatable-042 selection_count=0 should pass")


func test_datatable_043_reward_selection_count_negative_rejected() -> void:
	var record := _reward_record()
	record["selection_count"] = -1
	var result := _validate_record(REWARD_PATH, record)
	assert_false(result["ok"], "datatable-043 selection_count=-1 should fail")
	assert_has_error_text(result["errors"], "selection_count", "datatable-043 expected selection_count error")


func test_datatable_044_reward_guaranteed_rewards_empty_array_allowed() -> void:
	var record := _reward_record()
	record["guaranteed_rewards"] = []
	var result := _validate_record(REWARD_PATH, record)
	assert_true(result["ok"], "datatable-044 empty guaranteed_rewards should pass")


func test_datatable_045_reward_pity_rule_structure_validated() -> void:
	var record := _reward_record()
	record["pity_rule"] = {
		"threshold": 5,
		"guaranteed_rarity": "rare",
	}
	var valid_result := _validate_record(REWARD_PATH, record)
	assert_true(valid_result["ok"], "datatable-045 valid pity_rule should pass")

	record["pity_rule"] = {
		"threshold": 0,
		"guaranteed_rarity": "rare",
	}
	var invalid_result := _validate_record(REWARD_PATH, record)
	assert_false(invalid_result["ok"], "datatable-045 pity_rule threshold=0 should fail")
	assert_has_error_text(invalid_result["errors"], "pity_rule", "datatable-045 expected pity_rule error")


func test_datatable_046_character_skill_ids_empty_array_allowed() -> void:
	var record := _character_record()
	record["skill_ids"] = []
	var result := _validate_record(CHARACTER_PATH, record)
	assert_true(result["ok"], "datatable-046 empty skill_ids should pass")


func test_datatable_047_skill_status_effect_ids_empty_array_allowed() -> void:
	var record := _skill_record()
	record["status_effect_ids"] = []
	var result := _validate_record(SKILL_PATH, record)
	assert_true(result["ok"], "datatable-047 empty status_effect_ids should pass")


func test_datatable_048_enemy_status_immunities_empty_array_allowed() -> void:
	var record := _enemy_record()
	record["status_immunities"] = []
	var result := _validate_record(ENEMY_PATH, record)
	assert_true(result["ok"], "datatable-048 empty status_immunities should pass")


func test_datatable_049_registry_detects_duplicate_ids() -> void:
	var registry_result := _register_records(CHARACTER_PATH, [
		_character_record({"character_id": "char_001"}),
		_character_record({"character_id": "char_001", "name": "Other"}),
	])
	assert_false(registry_result["ok"], "datatable-049 duplicate IDs should fail registration")
	assert_has_error_text(registry_result["errors"], "duplicate", "datatable-049 expected duplicate error")


func test_datatable_050_registry_allows_empty_table_registration() -> void:
	var registry_result := _register_records(CHARACTER_PATH, [])
	assert_true(registry_result["ok"], "datatable-050 empty table should be allowed")
	assert_eq(registry_result["errors"].size(), 0, "datatable-050 expected no errors")


func _validate_record(script_path: String, data: Dictionary) -> Dictionary:
	var script: Script = load(script_path)
	if script == null:
		return {
			"ok": false,
			"errors": ["Missing script: %s" % script_path],
		}

	var instance = script.new(data)
	var errors = instance.validate()
	return {
		"ok": errors.is_empty(),
		"errors": errors,
	}


func _register_records(script_path: String, records: Array) -> Dictionary:
	var registry_script: Script = load(REGISTRY_PATH)
	if registry_script == null:
		return {
			"ok": false,
			"errors": ["Missing script: %s" % REGISTRY_PATH],
		}

	var registry = registry_script.new()
	var record_instances: Array = []
	var record_script: Script = load(script_path)
	if record_script == null:
		return {
			"ok": false,
			"errors": ["Missing script: %s" % script_path],
		}

	for record_data in records:
		record_instances.append(record_script.new(record_data))

	var register_errors = registry.register(record_instances)
	var validate_errors = registry.validate_all()
	var errors: Array = []
	for item in register_errors:
		errors.append(item)
	for item in validate_errors:
		errors.append(item)
	return {
		"ok": errors.is_empty(),
		"errors": errors,
	}


func _character_record(overrides := {}) -> Dictionary:
	var record := {
		"character_id": "char_001",
		"name": "Doki",
		"role": "front",
		"max_hp": 100,
		"max_mp": 30,
		"attack": 15,
		"defense": 10,
		"speed": 12,
		"crit_rate": 0.05,
		"effect_accuracy": 0.9,
		"effect_resistance": 0.1,
		"skill_ids": ["sk_001"],
	}
	return _merge_dict(record, overrides)


func _skill_record(overrides := {}) -> Dictionary:
	var record := {
		"skill_id": "sk_001",
		"name": "Basic Attack",
		"mp_cost": 5,
		"target_type": "single_enemy",
		"damage_ratio": 1.0,
		"base_status_chance": 0.0,
		"status_effect_ids": [],
		"status_duration": 0,
		"tags": ["attack"],
	}
	return _merge_dict(record, overrides)


func _enemy_record(overrides := {}) -> Dictionary:
	var record := {
		"enemy_id": "enm_001",
		"name": "Mushroom",
		"tier": "normal",
		"max_hp": 50,
		"attack": 8,
		"defense": 5,
		"speed": 7,
		"reward_group_id": "rwg_001",
		"ai_pattern_id": "ai_001",
		"loot_table_id": "loot_001",
		"status_immunities": [],
	}
	return _merge_dict(record, overrides)


func _relic_record(overrides := {}) -> Dictionary:
	var record := {
		"relic_id": "rel_001",
		"name": "Sweet Cookie",
		"rarity": "rare",
		"trigger_condition": "turn_start",
		"effect_text": "Recover 10 HP",
		"stack_rule": "no_stack",
		"penalty_text": null,
	}
	return _merge_dict(record, overrides)


func _equipment_record(overrides := {}) -> Dictionary:
	var record := {
		"equipment_id": "eqp_001",
		"name": "Club",
		"slot": "weapon",
		"rarity": "common",
		"primary_bonus": {
			"stat": "attack",
			"value": 5,
		},
		"secondary_bonus": null,
		"upgrade_level_max": 5,
		"special_effect_text": null,
	}
	return _merge_dict(record, overrides)


func _node_record(overrides := {}) -> Dictionary:
	var record := {
		"node_id": "nd_001",
		"node_type": "combat",
		"unlock_condition": null,
		"outgoing_edges": ["nd_002"],
		"encounter_pool_id": "enc_001",
		"reward_group_id": "rwg_001",
	}
	return _merge_dict(record, overrides)


func _event_record(overrides := {}) -> Dictionary:
	var record := {
		"event_id": "evt_001",
		"title": "Mysterious Bread",
		"options": [
			{"text": "Eat it", "outcome": "success"},
			{"text": "Ignore it", "outcome": "neutral"},
		],
		"required_conditions": [],
		"success_outcomes": [{"type": "heal", "value": 20}],
		"failure_outcomes": [{"type": "damage", "value": 15}],
		"followup_node_type": "campfire",
	}
	return _merge_dict(record, overrides)


func _reward_record(overrides := {}) -> Dictionary:
	var record := {
		"reward_group_id": "rwg_001",
		"guaranteed_rewards": [{"type": "gold", "amount": 50}],
		"optional_rewards": [{"type": "equipment", "pool_id": "eqp_pool_001"}],
		"selection_count": 1,
		"rarity_floor": "common",
		"pity_rule": {
			"threshold": 5,
			"guaranteed_rarity": "rare",
		},
	}
	return _merge_dict(record, overrides)


func _merge_dict(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var merged := base.duplicate(true)
	for key in overrides:
		merged[key] = overrides[key]
	return merged


func assert_has_error_text(errors: Array, fragment: String, message := "") -> void:
	var found := false
	for error_text in errors:
		if fragment.to_lower() in str(error_text).to_lower():
			found = true
			break
	assert_true(found, message if not message.is_empty() else "Expected error containing '%s'" % fragment)


func assert_has_all_strings(errors: Array, fragments: Array, message := "") -> void:
	for fragment in fragments:
		assert_has_error_text(errors, str(fragment), message if not message.is_empty() else "Expected error containing '%s'" % fragment)
