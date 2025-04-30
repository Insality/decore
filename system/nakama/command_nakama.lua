---@class world
---@field command_nakama command.nakama

---@class command.nakama
---@field nakama system.nakama
local M = {}


---@param nakama system.nakama
---@return command.nakama
function M.create(nakama)
	return setmetatable({ nakama = nakama }, { __index = M })
end


return M
