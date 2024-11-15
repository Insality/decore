return {
	transform = {},
	game_object = {
		remove_delay = 0.5,
	},
	collision = true,
	on_collision_remove = true,
	panthera = {
		animation_path = require("examples.basic_collision.entity.coin_panthera"),
		play_on_remove = "on_remove"
	},
	on_remove_event = "score_plus"
}