local decore = require("decore.decore")
--local command_transform_border = require("core.system.transform_border.command_transform_border")

---@class entity
---@field transform_border vector4

---@class entity.transform_border: entity
---@field transform_border component.transform_border
---@field transform component.transform

---@class component.transform_border
decore.register_component("transform_border")

---@class system.transform_border: system
---@field entities entity.transform_border[]
local M = {}


---@return system.transform_border
function M.create_system()
	return decore.system(M, "transform_border", { "transform_border", "transform" })
end


function M:onAddToWorld()
	--self.world.command_transform_border = command_transform_border.create(self)
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param event event.transform_event
function M:process_transform_event(event)
	local entity = event.entity
	if entity.transform_border and event.is_position_changed then
		local border = entity.transform_border
		local left, top, right, bottom = self.world.command_transform:get_transform_borders(entity)

		if left < border.x or top > border.y or right > border.z or bottom < border.w then
			local t = entity.transform
			local x = vmath.clamp(t.position_x, border.x + t.size_x/2, border.z - t.size_x/2)
			local y = vmath.clamp(t.position_y, border.w + t.size_y/2, border.y - t.size_y/2)
			self.world.command_transform:set_position(entity, x, y)
		end
	end
end


return M
