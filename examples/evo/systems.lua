--require("examples.evo.system.transform")
--require("examples.evo.system.game_object")
--require("examples.evo.system.velocity")
--require("examples.evo.system.movement_controller")
--require("examples.evo.game_object.gui_menu.system_gui_menu")

---@type table<string, evolved.id>
return {
	--require("examples.evo.system.transform_clean_dirty"),
	require("examples.evo.system.transform"),
	require("examples.evo.system.game_object"),
	require("examples.evo.system.color"),
	require("examples.evo.system.velocity"),
	require("examples.evo.system.movement_controller"),
	require("examples.evo.game_object.gui_menu.system_gui_menu")
}
