local decore = require("decore.decore")

---@class event.input_event: action

---@class system.input: system
---@field entities entity[]
local M = {}


---@return system.input
function M.create_system()
	return decore.system(M, "input")
end


function M:onAddToWorld()
	msg.post(".", "acquire_input_focus")
end


function M:onRemoveFromWorld()
	msg.post(".", "release_input_focus")
end


return M
