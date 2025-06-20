local evolved = require("decore.evolved")
local components = require("examples.evo.components")

---@return evolved.builder
return evolved.builder()
	:name("GUI Menu")
	:set(components.transform)
	:set(components.factory_url, "/spawner#gui_menu")
	:set(components.gui_menu)

