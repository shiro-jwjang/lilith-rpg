extends RefCounted

const NORMAL := {
	1: 20,
	2: 35,
	3: 60,
}

const HIGH := {
	1: 35,
	2: 55,
	3: 90,
}

const RARE := {
	2: 80,
	3: 120,
}


static func get_cost(grade: String, target_level: int) -> int:
	match grade:
		"normal":
			return int(NORMAL.get(target_level, -1))
		"high":
			return int(HIGH.get(target_level, -1))
		"rare":
			return int(RARE.get(target_level, -1))
		_:
			return -1
