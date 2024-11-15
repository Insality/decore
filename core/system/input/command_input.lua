---@class world
---@field command_input command.input

---@class command.input
---@field input system.input
local M = {}


---@return command.input
function M.create(input)
	return setmetatable({ input = input }, { __index = M })
end


function M:on_input(action_id, action)
	self.input:on_input(action_id, action)
end


return M
