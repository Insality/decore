local events = require("event.events")
local decore_data = require("decore.internal.decore_data")

local ecs = require("decore.ecs")

---@class entity
---@field id number|nil Unique entity id, autofilled by decore.create_entity
---@field prefab_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field pack_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field parent_prefab_id string|nil The parent prefab_id, used for prefab inheritance
---@field child_instancies decore.entities_pack_data.instance[]|nil The child instances to spawn on entity creation
---@field parent entity|nil The parent entity
---@field children entity[]|nil The children entities

decore_data.register_component("id", false)
decore_data.register_component("prefab_id", false)
decore_data.register_component("pack_id", false)
decore_data.register_component("parent_prefab_id", false)
decore_data.register_component("child_instancies", false)
decore_data.register_component("parent", false)
decore_data.register_component("children", false)


---@class system.decore: system
---@field decore decore
local M = {}


---@param decore decore
---@return system.decore
function M.create_system(decore)
	local system = setmetatable(ecs.system({ id = "decore" }), { __index = M })
	system.filter = ecs.requireAll("child_instancies")
	system.decore = decore
	return system
end


---@param world world
function M:onAddToWorld(world)
	events.subscribe("decore.create_entity", world.addEntity, world)
end


---@param world world
function M:onRemoveFromWorld(world)
	events.unsubscribe("decore.create_entity", world.addEntity, world)
end


---@param entity entity
function M:onAdd(entity)
	self:add_children(entity)
end


---@param entity entity
function M:onRemove(entity)
	self:remove_children(entity)
	self:remove_from_parent(entity)
end


---@param entity entity
function M:add_children(entity)
	-- Create real chilnd entities from prefab data
	local child_entities = entity.child_instancies
	if child_entities then
		entity.children = {}
		for index = 1, #child_entities do
			local child_entity = child_entities[index]
			local child = self.decore.create_entity(child_entity.prefab_id, child_entity.pack_id, child_entity.components)
			self.decore.apply_component(child, "transform")

			-- Add my position to child
			if entity.transform then
				child.transform.position.x = child.transform.position.x + entity.transform.position.x
				child.transform.position.y = child.transform.position.y + entity.transform.position.y
			end

			child.parent = entity
			table.insert(entity.children, child)
			self.world:addEntity(child)
		end
	end
end


---@param entity entity
function M:remove_children(entity)
	local children = entity.children
	if children then
		for index = 1, #children do
			local child = children[index]
			self.world:removeEntity(child)
		end
	end

	entity.children = nil
end


---@param entity entity
function M:remove_from_parent(entity)
	local parent = entity.parent
	if not parent then
		return
	end

	local children = parent.children
	if children then
		for index = #children, 1, -1 do
			local child = children[index]
			if child == entity then
				table.remove(children, index)
			end
		end
	end

	entity.parent = nil
end


return M
