local ecs = require("decore.ecs")
local event_bus = require("decore.internal.event_bus")

---@class system.bus.event: system
local M = {}


---@return system.bus.event
function M.create_system()
	return setmetatable(ecs.system({ id = "event_bus" }), { __index = M })
end


function M:onAddToWorld(world)
	world.event_bus = event_bus.create()
end


function M:postWrap()
	self.world.event_bus:stash_to_events()
end


return M
