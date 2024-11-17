---@class world
---@field command_game_object command.game_object

---@class command.game_object
---@field game_object system.game_object
local M = {}


---@return command.game_object
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
