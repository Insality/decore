local decore = require("decore.decore")

---@class entity
---@field on_remove_event string|nil

---@class entity.on_remove_event: entity
---@field on_remove_event string
decore.register_component("on_remove_event", "")

---@class system.on_remove_event: system
---@field entities entity.on_remove_event[]
local M = {}


---@return system.on_remove_event
function M.create_system()
	return decore.system(M, "on_remove_event", "on_remove_event")
end


function M:onRemove(entity)
	self.world.event_bus:trigger(entity.on_remove_event, entity)
end


return M
