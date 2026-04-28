extends RefCounted

const _STATUS_TYPES := ["출혈", "화상", "파쇄", "둔화", "약화"]

const _NORMAL_ENEMIES := [
	{
		"enemy_id": "enemy_normal_rust_swordsman",
		"name": "녹슨 검병",
		"tier": "normal",
		"max_hp": 82,
		"attack": 13,
		"defense": 5,
		"speed": 10,
		"status_effects": [],
		"pattern": ["slash", "guard_break", "slash"],
	},
	{
		"enemy_id": "enemy_normal_red_hound",
		"name": "붉은 사냥견",
		"tier": "normal",
		"max_hp": 74,
		"attack": 14,
		"defense": 4,
		"speed": 12,
		"status_effects": ["출혈"],
		"pattern": ["bite", "howl", "pounce"],
	},
	{
		"enemy_id": "enemy_normal_charred_archer",
		"name": "그을린 궁수",
		"tier": "normal",
		"max_hp": 76,
		"attack": 15,
		"defense": 4,
		"speed": 11,
		"status_effects": ["화상"],
		"pattern": ["ember_arrow", "aimed_shot", "ember_arrow"],
	},
	{
		"enemy_id": "enemy_normal_shatter_butler",
		"name": "파쇄 집사",
		"tier": "normal",
		"max_hp": 88,
		"attack": 12,
		"defense": 6,
		"speed": 9,
		"status_effects": ["파쇄"],
		"pattern": ["tray_smash", "shove", "tray_smash"],
	},
	{
		"enemy_id": "enemy_normal_rift_soldier",
		"name": "균열 병졸",
		"tier": "normal",
		"max_hp": 90,
		"attack": 12,
		"defense": 5,
		"speed": 10,
		"status_effects": ["둔화"],
		"pattern": ["jab", "dragging_sweep", "jab"],
	},
	{
		"enemy_id": "enemy_normal_moon_priest",
		"name": "달빛 사제",
		"tier": "normal",
		"max_hp": 79,
		"attack": 13,
		"defense": 4,
		"speed": 11,
		"status_effects": ["약화"],
		"pattern": ["moon_bolt", "whisper_hex", "moon_bolt"],
	},
]

const _ELITE_ENEMIES := [
	{
		"enemy_id": "enemy_elite_iron_watcher",
		"name": "철갑 감시자",
		"tier": "elite",
		"max_hp": 160,
		"attack": 17,
		"defense": 8,
		"speed": 10,
		"status_effects": [],
		"pattern": ["shield_slam", "brace", "lance_drive"],
	},
	{
		"enemy_id": "enemy_elite_flame_executioner",
		"name": "화염 집행관",
		"tier": "elite",
		"max_hp": 148,
		"attack": 20,
		"defense": 6,
		"speed": 12,
		"status_effects": ["화상"],
		"pattern": ["flame_cleave", "brand", "searing_chop"],
	},
	{
		"enemy_id": "enemy_elite_red_moon_ritualist",
		"name": "붉은 달 의식사",
		"tier": "elite",
		"max_hp": 138,
		"attack": 18,
		"defense": 7,
		"speed": 13,
		"status_effects": ["약화", "파쇄"],
		"pattern": ["hex", "blood_rite", "fracture_prayer", "moon_tithe"],
	},
]

const _UNIQUE_ENEMIES := [
	{
		"enemy_id": "enemy_unique_sealed_gatekeeper",
		"name": "봉인된 문지기",
		"tier": "unique",
		"max_hp": 190,
		"attack": 18,
		"defense": 8,
		"speed": 11,
		"status_effects": [],
		"mechanic": "반격",
		"pattern": ["seal_strike", "counter_stance", "seal_strike"],
	},
	{
		"enemy_id": "enemy_unique_moon_hunter",
		"name": "달의 사냥꾼",
		"tier": "unique",
		"max_hp": 176,
		"attack": 20,
		"defense": 6,
		"speed": 15,
		"status_effects": ["출혈"],
		"mechanic": "출혈",
		"pattern": ["lunar_dash", "tracking_mark", "carve", "finishing_pounce"],
	},
]

const _BOSS := {
	"enemy_id": "enemy_boss_red_moon_warden",
	"name": "붉은 달의 파수꾼",
	"tier": "boss",
	"max_hp": 450,
	"attack": 22,
	"defense": 8,
	"speed": 10,
	"phases": 2,
	"phase_transition_hp": 225,
	"phase_1_pattern": ["warding_slash", "moon_beam", "summon_guard"],
	"phase_2_pattern": ["blood_moon_frenzy", "crimson_wave", "eclipse_judgment"],
}

const _SKILLS := {
	"전위딜러": [
		{
			"skill_id": "skill_front_basic_attack",
			"name": "기본공격",
			"mp_cost": 0,
			"target": "single",
			"multiplier": 1.0,
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_front_heavy_strike",
			"name": "강타",
			"mp_cost": 5,
			"target": "single",
			"multiplier": 1.3,
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_front_charge_slash",
			"name": "돌진베기",
			"mp_cost": 8,
			"target": "single",
			"multiplier": 1.6,
			"status_effects": ["출혈"],
			"status_chance": 0.3,
		},
		{
			"skill_id": "skill_front_whirlwind",
			"name": "회전참격",
			"mp_cost": 12,
			"target": "all",
			"multiplier": 0.7,
			"status_effects": [],
			"status_chance": 0.0,
		},
	],
	"수호자": [
		{
			"skill_id": "skill_guardian_basic_attack",
			"name": "기본공격",
			"mp_cost": 0,
			"target": "single",
			"multiplier": 1.0,
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_guardian_defense_stance",
			"name": "방어태세",
			"mp_cost": 3,
			"target": "self",
			"effect": "def_boost",
			"value": 0.3,
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_guardian_taunt",
			"name": "도발",
			"mp_cost": 5,
			"target": "all_enemies",
			"effect": "taunt",
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_guardian_shield_bash",
			"name": "방패타격",
			"mp_cost": 8,
			"target": "single",
			"multiplier": 1.3,
			"status_effects": ["둔화"],
			"status_chance": 0.4,
		},
	],
	"마법지원가": [
		{
			"skill_id": "skill_support_basic_attack",
			"name": "기본공격",
			"mp_cost": 0,
			"target": "single",
			"multiplier": 1.0,
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_support_flame",
			"name": "화염",
			"mp_cost": 6,
			"target": "single",
			"multiplier": 1.3,
			"status_effects": ["화상"],
			"status_chance": 0.35,
		},
		{
			"skill_id": "skill_support_heal",
			"name": "치유",
			"mp_cost": 8,
			"target": "ally_single",
			"effect": "heal_max_hp_percent",
			"value": 0.2,
			"status_effects": [],
			"status_chance": 0.0,
		},
		{
			"skill_id": "skill_support_weaken_curse",
			"name": "약화저주",
			"mp_cost": 10,
			"target": "single",
			"multiplier": 0.8,
			"status_effects": ["약화"],
			"status_chance": 0.5,
		},
	],
}


func get_normal_enemies() -> Array:
	return _duplicate_array(_NORMAL_ENEMIES)


func get_elite_enemies() -> Array:
	return _duplicate_array(_ELITE_ENEMIES)


func get_unique_enemies() -> Array:
	return _duplicate_array(_UNIQUE_ENEMIES)


func get_boss() -> Dictionary:
	return _BOSS.duplicate(true)


func get_enemy_by_name(name: String) -> Dictionary:
	var groups := [_NORMAL_ENEMIES, _ELITE_ENEMIES, _UNIQUE_ENEMIES, [_BOSS]]
	for group in groups:
		for enemy in group:
			if enemy["name"] == name:
				return enemy.duplicate(true)
	return {}


func get_skills_for_character(character_name: String) -> Array:
	if not _SKILLS.has(character_name):
		return []
	return _duplicate_array(_SKILLS[character_name])


func get_skill(character_name: String, skill_name: String) -> Dictionary:
	if not _SKILLS.has(character_name):
		return {}
	for skill in _SKILLS[character_name]:
		if skill["name"] == skill_name:
			return skill.duplicate(true)
	return {}


func can_use_skill(current_mp: int, skill: Dictionary) -> bool:
	return current_mp >= int(skill.get("mp_cost", 0))


func spend_mp(current_mp: int, skill: Dictionary) -> int:
	return current_mp - int(skill.get("mp_cost", 0))


func should_apply_status(skill: Dictionary, rng: RandomNumberGenerator) -> bool:
	var chance := float(skill.get("status_chance", 0.0))
	if chance <= 0.0:
		return false
	return rng.randf() < chance


func get_status_types() -> Array:
	return _STATUS_TYPES.duplicate()


func should_boss_transition_phase(current_hp: int) -> bool:
	return current_hp <= int(_BOSS["phase_transition_hp"])


func _duplicate_array(items: Array) -> Array:
	var result: Array = []
	for item in items:
		result.append(item.duplicate(true))
	return result
