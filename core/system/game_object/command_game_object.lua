---@class world
---@field command_game_object system.game_object.command

---@class system.game_object.command
---@field game_object system.game_object
local M = {}


---@return system.game_object.command
function M.create(game_object)
	return setmetatable({ game_object = game_object }, { __index = M })
end


---@param entity entity
function M:refresh_transform(entity)
	assert(entity.game_object, "Entity should have game_object component")
	assert(entity.transform, "Entity should have transform component")
	---@cast entity entity.game_object
	self.game_object:refresh_transform(entity)
end


return M
