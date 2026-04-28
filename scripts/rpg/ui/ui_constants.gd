extends RefCounted

const CANVAS_WIDTH := 1920
const CANVAS_HEIGHT := 1080
const ASPECT_RATIO := 16.0 / 9.0
const ASPECT_RATIO_LABEL := "16:9"
const ASPECT_LOCKED := true

const RESIZE_POLICY := {
	"maintain_aspect": true,
	"use_letterbox": true,
	"use_pillarbox": true,
}

const SAFE_AREA := {
	"top": 48,
	"bottom": 48,
	"left": 48,
	"right": 48,
}

const UI_BOUNDS := {
	"left": 48,
	"top": 48,
	"right": 1872,
	"bottom": 1032,
}

const Z_LAYERS := {
	"background": 0,
	"info_panel": 10,
	"interaction": 20,
	"modal_toast": 30,
}

const FONT_FAMILIES := [
	"Pretendard",
	"Noto Sans KR",
]

const FONT_SIZES := {
	"body": 24,
	"warning": 28,
	"important": 28,
}

const HUD_FONT_SIZES := {
	"body_number": 24,
	"label": 20,
	"important_number": 28,
}

const BATTLE_HUD_ALWAYS_VISIBLE := [
	"HP_bar",
	"MP_bar",
	"turn_order",
	"status_effects",
]

const SKILL_PREVIEW := {
	"position": "bottom_center",
	"fields": [
		"name",
		"mp",
		"description",
	],
}

const MAP_NODE_OPACITY := {
	"selectable": 1.0,
	"unselectable": 0.35,
}

const CURRENT_NODE_INDICATOR := {
	"ring_color": "white",
	"pulse_duration_ms": 1500,
}

const EVENT_OPTIONS := {
	"min": 2,
	"max": 4,
}

const EVENT_FLOW_PHASES := [
	"description_panel",
	"choice_buttons",
	"result_toast",
]

const FEEDBACK := {
	"damage_number_display_ms": 200,
	"hp_bar_animation_ms": 250,
}

const CRITICAL_FEEDBACK := {
	"color": "gold",
	"scale": 1.2,
	"unique_sound": true,
}

const PARTICLE_LIMITS := {
	"max_per_skill": 12,
}

const CAMERA := {
	"shake_max_percent": 6,
}
