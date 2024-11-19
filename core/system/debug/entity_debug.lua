---@return entity.debug
return {
	debug = {},
	on_key_released = {
		key_p = { "command_debug", "toggle_profiler", true },
		--key_1 = { "command_debug", "save_slot", "save_debug.json" },
		--key_2 = { "command_debug", "load_slot", "save_debug.json" },
		--key_r = { "command_debug", "restart", true },
		--key_n = { "command_debug", "reset_game", true },
		key_m = { "command_debug", "toggle_memory_record" },
		key_i = { "command_debug", "inspect", true },
	}
}