---@diagnostic disable: missing-fields
---@class entity.boid: entity
return {
	boid = {},
	transform = {},
	transform_border = {
		border = vmath.vector4(-960/2, 640/2, 960/2, -640/2),
		is_wrap = true
	},
	velocity = {
		max_speed = 120,
	},
	game_object = {
		factory_url = "/spawner#boid",
		is_factory = true
	},
}