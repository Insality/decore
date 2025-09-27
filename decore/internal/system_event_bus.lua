local ecs = require("decore.ecs")
local event_bus = require("decore.internal.event_bus")

---System to manage event bus inside the world
---@class system.bus.event: system
local M = {}


---@return system.bus.event
function M.create_system()
	local self = setmetatable(ecs.system(), { __index = M }) --[[@as system.bus.event]]
	self.id = "event_bus"

	return self
end


function M:onAddToWorld(world)
	world.event_bus = event_bus.create()
end


function M:postWrap()
	self.world.event_bus:stash_to_events()
end


return M
