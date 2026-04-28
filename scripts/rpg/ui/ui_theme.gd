extends RefCounted

const BUTTON_SPECS := {
	"height": 56,
	"min_width": 240,
}

const BUTTON_STATES := {
	"default": {
		"brightness": 1.0,
		"ignore_click": false,
	},
	"hover": {
		"brightness": 1.08,
		"ignore_click": false,
	},
	"pressed": {
		"brightness": 0.94,
		"ignore_click": false,
	},
	"disabled": {
		"brightness": 0.6,
		"ignore_click": true,
	},
}

const BUTTON_STYLES := {
	"primary": {
		"fill": "gold",
		"text": "black",
	},
	"secondary": {
		"fill": "ivory",
		"text": "charcoal",
	},
	"destructive": {
		"fill": "red",
		"text": "white",
	},
}

const MODAL_DIM_OPACITY := 0.6
const MODAL_BLOCKS_BACKGROUND_INTERACTION := true

const CONFIRM_DIALOG := {
	"sentence_count": 1,
	"button_count": 2,
	"confirm_style": "destructive",
	"cancel_style": "secondary",
}

const TOAST_DEFAULTS := {
	"position": "top_center",
	"duration_ms": 1500,
	"colors": {
		"acquire": "gold",
		"loss": "red",
		"status": "purple",
		"fail": "gray",
	},
}
