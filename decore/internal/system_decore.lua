local events = require("event.events")
local decore_data = require("decore.internal.decore_data")

local ecs = require("decore.ecs")

---@class entity
---@field id number|nil Unique entity id, autofilled by decore.create_entity
---@field prefab_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field pack_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field parent_prefab_id string|nil The parent prefab_id, used for prefab inheritance
---@field child_instancies decore.entities_pack_data.instance[]|nil The child instances to spawn on entity creation
---@field parent_id number|nil The parent id
---@field children_ids number[]|nil The children ids

decore_data.register_component("id", false)
decore_data.register_component("prefab_id", false)
decore_data.register_component("pack_id", false)
decore_data.register_component("parent_prefab_id", false)
decore_data.register_component("child_instancies", false)
decore_data.register_component("parent_id", false)
decore_data.register_component("children_ids", false)


---System Decore class to manage child-parent relationships and default components
---@class system.decore: system
---@field decore decore
---@field id_to_entity table<number, entity> The entity id to entity map
local M = {}


---@param decore decore
---@return system.decore
function M.create_system(decore)
	local system = setmetatable(ecs.system({ id = "decore" }), { __index = M })
	system.filter = ecs.requireAll("child_instancies")
	system.decore = decore
	system.id_to_entity = {}

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
	self.id_to_entity[entity.id] = entity
	self:add_children(entity)
end


---@param entity entity
function M:onRemove(entity)
	self.id_to_entity[entity.id] = nil
	self:remove_children(entity)
	self:remove_from_parent(entity)
end


---@param entity entity
function M:add_children(entity)
	-- Create real chilnd entities from prefab data
	local child_entities = entity.child_instancies
	if child_entities then
		entity.children_ids = {}
		for index = 1, #child_entities do
			local child_entity = child_entities[index]
			local child = self.decore.create_entity(child_entity.prefab_id, child_entity.pack_id, child_entity.components)
			self.decore.apply_component(child, "transform")

			-- Add my position to child
			if entity.transform then
				child.transform.position_x = child.transform.position_x + entity.transform.position_x
				child.transform.position_y = child.transform.position_y + entity.transform.position_y
			end

			if child.tiled_id and entity.tiled_id then
				child.tiled_id = entity.tiled_id .. "/" .. child.tiled_id
			end

			child.parent_id = entity.id
			table.insert(entity.children_ids, child.id)
			self.world:addEntity(child)
		end
	end
end


---@param entity entity
function M:remove_children(entity)
	local children_ids = entity.children_ids
	if children_ids then
		for index = 1, #children_ids do
			local child_id = children_ids[index]
			local child = self.id_to_entity[child_id]
			if child then
				self.world:removeEntity(child)
			end
		end
	end

	entity.children_ids = nil
end


---@param entity entity
function M:remove_from_parent(entity)
	local parent_id = entity.parent_id
	local parent = self.id_to_entity[parent_id]

	local children_ids = parent.children_ids
	if children_ids then
		for index = #children_ids, 1, -1 do
			local child_id = children_ids[index]
			if child_id == entity.id then
				table.remove(children_ids, index)
			end
		end
	end

	entity.parent_id = nil
end


return M
