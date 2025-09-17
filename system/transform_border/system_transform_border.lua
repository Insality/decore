local decore = require("decore.decore")

---@class entity
---@field transform_border component.transform_border|nil

---@class entity.transform_border: entity
---@field transform_border component.transform_border
---@field transform component.transform

---@class component.transform_border
---@field border vector4
---@field is_wrap boolean
---@field is_limit boolean
---@field random_position boolean If true, the entity will be placed randomly within the border
decore.register_component("transform_border", {
	is_wrap = false,
	is_limit = true,
	random_position = false,
})

---@class system.transform_border: system
---@field entities entity.transform_border[]
local M = {}


---@return system.transform_border
function M.create()
	return decore.system(M, "transform_border", { "transform_border", "transform" })
end


---@param entity entity.transform_border
function M:onAdd(entity)
	if entity.transform_border.random_position then
		local border = entity.transform_border.border
		local x = math.random(border.x, border.z)
		local y = math.random(border.w, border.y)
		self.world.command_transform:set_position(entity, x, y)
	end
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param event system.transform.event
function M:process_transform_event(event)
	local entity = event.entity
	local transform_border = entity.transform_border

	if transform_border then
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
			elseif transform_border.is_limit then
				local x = decore.clamp(t.position_x, border.x + t.size_x/2, border.z - t.size_x/2)
				local y = decore.clamp(t.position_y, border.w + t.size_y/2, border.y - t.size_y/2)
				self.world.command_transform:set_position(entity, x, y)
			end
		end
	end
end


return M
