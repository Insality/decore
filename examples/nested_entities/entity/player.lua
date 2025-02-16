--@class entity
return {
	transform = {},
	game_object = {
		object_scheme = {
			["#label"] = true,
			["#sprite"] = true,
		},
	},
	transform_border = {
		border = vmath.vector4(-1920/2, 1080/2, 1920/2, -1080/2),
	},
	text_game_timer = {
		label_url = "#label",
	},
	movement_controller = {
		speed = 20
	}
}
