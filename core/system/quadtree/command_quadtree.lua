---@class world
---@field command_quadtree system.quadtree.command

---@class system.quadtree.command
---@field quadtree system.quadtree
local M = {}


---@return system.quadtree.command
function M.create(quadtree)
	return setmetatable({ quadtree = quadtree }, { __index = M })
end


---@param entity entity
---@param radius number
function M:get_neighbors(entity, radius, callback)
	assert(entity.transform, "entity must have transform component")
	---@cast entity entity.transform
	return self.quadtree:get_neighbors(entity, radius, callback)
end


return M
