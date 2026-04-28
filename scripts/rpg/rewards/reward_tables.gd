extends RefCounted

const GOLD_RANGES := {
	"normal": {"min": 20, "max": 35},
	"elite": {"min": 60, "max": 80},
	"unique": {"min": 80, "max": 100},
	"boss": {"min": 120, "max": 120},
}

const ITEM_POOLS := {
	"normal": [
		{"category": "normal_equipment", "weight": 0.4, "id": "녹슨 검"},
		{"category": "potion", "weight": 0.6, "id": "소형 치료 물약"},
	],
	"elite": [
		{"category": "high_equipment", "weight": 0.5, "id": "붉은 달 단도"},
		{"category": "relic_candidate", "weight": 0.3, "id": "균열 실타래"},
		{"category": "rare_equipment", "weight": 0.2, "id": "균열 지팡이"},
	],
	"unique": [
		{"category": "high_equipment", "weight": 0.3, "id": "의식의 로브"},
		{"category": "relic_candidate", "weight": 0.5, "id": "붉은 달의 파편"},
		{"category": "rare_equipment", "weight": 0.2, "id": "잠든 종"},
	],
}

const BOSS_RELIC := {"id": "붉은 달의 파편"}
const TREASURE_RELIC := {"id": "균열 실타래"}

const EVENT_REWARDS := {
	"A": {"gold": 30, "items": [], "relics": []},
	"B": {"gold": 0, "items": [{"category": "potion", "id": "정화 물약"}], "relics": []},
	"C": {"gold": 0, "items": [{"category": "normal_equipment", "id": "녹슨 검"}], "relics": []},
}
