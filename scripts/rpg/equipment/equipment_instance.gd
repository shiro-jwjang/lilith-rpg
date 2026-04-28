extends RefCounted

const CALCULATOR_PATH := "res://scripts/rpg/equipment/enhancement_calculator.gd"

const EQUIPMENT_DATA := {
	"녹슨 검": {
		"slot": "weapon",
		"grade": "normal",
		"stats": {"atk": 4},
	},
	"붉은 달 단도": {
		"slot": "weapon",
		"grade": "high",
		"stats": {"atk": 3, "spd": 2, "crit": 0.05},
	},
	"균열 완드": {
		"slot": "weapon",
		"grade": "rare",
		"stats": {"atk": 2, "mp": 4, "effect_hit": 0.10},
	},
	"견고한 흉갑": {
		"slot": "armor",
		"grade": "normal",
		"stats": {"hp": 18, "def": 3},
	},
	"사냥견 가죽갑": {
		"slot": "armor",
		"grade": "high",
		"stats": {"hp": 12, "def": 2, "spd": 3},
	},
	"의식가 로브": {
		"slot": "armor",
		"grade": "rare",
		"stats": {"hp": 10, "def": 1, "effect_hit": 0.08, "effect_resist": 0.05},
	},
	"붉은 실 반지": {
		"slot": "accessory",
		"grade": "normal",
		"stats": {"crit": 0.04, "effect_hit": 0.04},
	},
	"달빛 부적": {
		"slot": "accessory",
		"grade": "high",
		"stats": {"spd": 4, "effect_resist": 0.05},
	},
	"파편 목걸이": {
		"slot": "accessory",
		"grade": "rare",
		"stats": {"hp": 14, "crit": 0.03, "effect_hit": 0.06},
	},
	"봉인된 열쇠": {
		"slot": "trinket",
		"grade": "normal",
		"stats": {"gold_bonus": 15},
	},
	"잠든 종": {
		"slot": "trinket",
		"grade": "high",
		"stats": {"campfire_heal": 0.10},
	},
	"재의 조각": {
		"slot": "trinket",
		"grade": "rare",
		"stats": {"burn_damage": 0.15, "burn_chance": 0.05},
	},
}

var _name: String = ""
var _slot: String = ""
var _grade: String = ""
var _upgrade_level: int = 0
var _base_stats: Dictionary = {}


func _init(equipment_name: String, upgrade_level := 0) -> void:
	var record: Dictionary = EQUIPMENT_DATA.get(equipment_name, {})
	_name = equipment_name
	_slot = str(record.get("slot", ""))
	_grade = str(record.get("grade", ""))
	_base_stats = record.get("stats", {}).duplicate(true)
	_upgrade_level = clampi(int(upgrade_level), 0, 3)


func get_name() -> String:
	return _name


func get_slot() -> String:
	return _slot


func get_grade() -> String:
	return _grade


func get_upgrade_level() -> int:
	return _upgrade_level


func set_upgrade_level(level: int) -> void:
	_upgrade_level = clampi(level, 0, 3)


func get_base_stats() -> Dictionary:
	return _base_stats.duplicate(true)


func get_stats() -> Dictionary:
	var calculator = load(CALCULATOR_PATH)
	var scaled_stats := {}
	for stat_name in _base_stats:
		var base_value = _base_stats[stat_name]
		if base_value is int or base_value is float:
			if calculator == null:
				scaled_stats[stat_name] = base_value
			else:
				scaled_stats[stat_name] = calculator.scale_stat(float(base_value), _upgrade_level)
		else:
			scaled_stats[stat_name] = base_value
	return scaled_stats
