---@class world
---@field command_level_loader command.level_loader

---@class command.level_loader
---@field level_loader system.level_loader
local M = {}


---@param level_loader system.level_loader
---@return command.level_loader
function M.create(level_loader)
	return setmetatable({ level_loader = level_loader }, { __index = M })
end



---@param world_id string
---@param pack_id string|nil
---@param offset_x number|nil
---@param offset_y number|nil
---@param slot_id string|nil
function M:load_world(world_id, pack_id, offset_x, offset_y, slot_id)
	self.level_loader:load_world(world_id, pack_id, offset_x, offset_y, slot_id)
end


function M:load_level(collection_url, slot_id)
	self.level_loader:load_level(collection_url, slot_id)
end


function M:unload_level(slot_id)
	self.level_loader:unload_level(slot_id)
end


return M