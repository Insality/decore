local evolved = require("decore.evolved")
local components = require("examples.evo.components")

---@return evolved.builder
return evolved.builder()
	:name("Object")
	:set(components.transform)
	:set(components.factory_url, "/spawner#object")
	:set(components.velocity_x, 5)
	:set(components.velocity_y, 5)
	:set(components.movement_controller, 400)
