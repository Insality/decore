--- Use this module to get the latest created world instance

---@class world
local M = {}
local METATABLE = { __index = nil }

---@param world world
function M.set_world(world)
	METATABLE.__index = world
end

return setmetatable(M, METATABLE)
