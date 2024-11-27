local decore = require("decore.decore")

---@class entity
---@field debug_draw_transform component.debug_draw_transform|nil

---@class entity.debug_draw_transform: entity
---@field debug_draw_transform component.debug_draw_transform
---@field transform component.transform

---@class component.debug_draw_transform: boolean
decore.register_component("debug_draw_transform", false)

---@class system.debug_draw_transform: system
---@field entities entity.debug_draw_transform[]
---@field is_draw_rectangle boolean
local M = {}


---@return system.debug_draw_transform
function M.create_system()
	return decore.system(M, "debug_draw_transform", { "debug_draw_transform", "transform" })
end


function M:onAddToWorld()
	self.is_draw_rectangle = false
end


---@param dt number
function M:update(dt)
	if not self.is_draw_rectangle then
		return
	end

	for index = 1, #self.entities do
	local t = self.entities[index].transform
		self.world.command_debug_draw:draw_rectangle(
			t.position_x,
			t.position_y,
			t.size_x * t.scale_x,
			t.size_y * t.scale_y
		)
	end
end


return M
