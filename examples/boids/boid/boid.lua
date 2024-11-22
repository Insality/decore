---@diagnostic disable: missing-fields
---@class entity.boid: entity
return {
	boid = {
		alignment_radius = 0,
		cohesion_radius = 0,
		separation_radius = 7000,
		speed = 10,
	},
	transform = {},
	transform_border = {
		border = vmath.vector4(-960/2, 640/2, 960/2, -640/2),
		is_wrap = true
	},
	velocity = {
		max_speed = 2000,
	},
	game_object = {
		factory_url = "/spawner#boid",
		is_factory = true
	},
}