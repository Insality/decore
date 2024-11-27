return {
	transform = {},
	game_object = {
		factory_url = "/spawner#coin",
		is_factory = true
	},
	collision = {
		is_remove = true,
		send_event = "score_plus",
	},
}