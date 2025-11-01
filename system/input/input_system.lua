local decore = require("decore.decore")

---@class world
---@field input system.input

---@class system.input.event: action

---@class system.input: system
local M = {}


---@return system.input
function M.create()
	return decore.system(M, "input")
end


---@protected
function M:onAddToWorld()
	msg.post(".", "acquire_input_focus")
	self.world.input = self
end


---@public
---@param action_id hash
---@param action action
---@return boolean
function M:on_input(action_id, action)
	action.action_id = action_id
	self.world.event_bus:trigger("input_event", action)
	return false
end


return M
