local evolved = require("decore.evolved")
local components = require("decore.components")

---@return evolved.builder
return evolved.builder()
	:name("Object")
	:set(components.transform)
	:set(components.factory_url, "/spawner#object")
	:set(components.color, vmath.vector4(1, 0, 1, 1))
	:set(components.color_dirty)
	:set(components.velocity_x, 5)
	:set(components.velocity_y, 5)
	:set(components.movement_controller, 400)
