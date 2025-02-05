local decore = require("decore.decore")

---@class entity
---@field on_collision_remove boolean|nil
decore.register_component("on_collision_remove", false)

---@class system.on_collision_remove: system
local M = {}

---@static
---@return system.on_collision_remove
function M.create_system()
	return decore.system(M, "on_collision_remove")
end


function M:postWrap()
	self.world.event_bus:process("collision_event", self.process_collision_event, self)
end


---@param collision_event system.collision.event
function M:process_collision_event(collision_event)
	local entity = collision_event.entity
	local on_collision_remove = entity.on_collision_remove
	if on_collision_remove then
		self.world:removeEntity(entity)
	end
end


return M
