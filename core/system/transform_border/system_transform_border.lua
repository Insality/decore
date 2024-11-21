local decore = require("decore.decore")

---@class entity
---@field transform_border component.transform_border

---@class entity.transform_border: entity
---@field transform_border component.transform_border
---@field transform component.transform

---@class component.transform_border
---@field border vector4
---@field is_wrap boolean
decore.register_component("transform_border", {
	is_wrap = false,
})

---@class system.transform_border: system
---@field entities entity.transform_border[]
local M = {}


---@return system.transform_border
function M.create_system()
	return decore.system(M, "transform_border", { "transform_border", "transform" })
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param entity entity.transform
function M:process_transform_event(entity)
	if entity.transform_border and entity.transform.is_position_changed then
		local transform_border = entity.transform_border
		local border = transform_border.border
		local left, top, right, bottom = self.world.command_transform:get_transform_borders(entity)

		if left < border.x or top > border.y or right > border.z or bottom < border.w then
			local t = entity.transform

			if transform_border.is_wrap then
				local x = t.position_x
				local y = t.position_y
				local size_x_half = t.size_x/2
				local size_y_half = t.size_y/2

				-- Wrap horizontally
				if x - size_x_half > border.z then
					x = border.x + size_x_half
				elseif x + size_x_half < border.x then
					x = border.z - size_x_half
				end

				-- Wrap vertically
				if y - size_y_half > border.y then
					y = border.w + size_y_half
				elseif y + size_y_half < border.w then
					y = border.y - size_y_half
				end

				self.world.command_transform:set_position(entity, x, y)
			else
				local x = vmath.clamp(t.position_x, border.x + t.size_x/2, border.z - t.size_x/2)
				local y = vmath.clamp(t.position_y, border.w + t.size_y/2, border.y - t.size_y/2)
				self.world.command_transform:set_position(entity, x, y)
			end
		end
	end
end


return M
