local color = require("druid.color")

local display_width = sys.get_config_int("display.width")
local display_height = sys.get_config_int("display.height")

---@diagnostic disable: missing-fields
---@class entity.boid: entity
return {
	quadtree = true,
	debug_draw_transform = false,
	boid = {
		neighbors = {},
		visual_range = 140,
		protected_range = 70,
		centering_factor = 0.6,
		avoid_factor = 0.3,
		matching_factor = 0.5,
		turn_factor = 360, -- When boid around edges it tries to turn around
	},
	color = {
		sprites = "#sprite",
		random_color = { color.hex2vector4("#A1D7F5"), color.hex2vector4("#1890D3") }
	},
	transform = {
		size_x = 10,
		size_y = 10,
	},
	transform_border = {
		border = vmath.vector4(-display_width / 2, display_width / 2, display_height / 2, -display_height / 2),
		is_wrap = false,
		is_limit = false,
		random_position = false
	},
	velocity = {
		min_speed = 150,
		max_speed = 250
	},
	game_object = {
		factory_url = "/spawner#boid",
		is_factory = true
	},
}