local decore_data = require("decore.internal.decore_data")

local ecs = require("decore.ecs")

---@class entity
---@field id number|nil Unique entity id, autofilled by decore.create_entity
---@field prefab_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field pack_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field parent_prefab_id string|nil The parent prefab_id, used for prefab inheritance
---@field child_instancies decore.entities_pack_data.instance[]|nil The child instances to spawn on entity creation

decore_data.register_component("id", false)
decore_data.register_component("prefab_id", false)
decore_data.register_component("pack_id", false)
decore_data.register_component("parent_prefab_id", false)
decore_data.register_component("child_instancies", false)


---@class system.decore: system
local M = {}


---@return system.decore
function M.create_system()
	return setmetatable(ecs.system({id = "decore"}), { __index = M })
end


---@param entity entity
function M:onAdd(entity)
	local child_instancies = entity.child_instancies
	if child_instancies then
		for _, child_instance in ipairs(child_instancies) do
			self.world:addEntity(child_instance)
		end
	end
end


return M
