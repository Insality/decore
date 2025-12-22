local events = require("event.events")
local decore_data = require("decore.internal.decore_data")

local ecs = require("decore.internal.ecs")

---@class decore.entity_prefab_data
---@field prefab_id string|nil
---@field pack_id string|nil
---@field components table<string, any>|nil

---@class decore.components_data
---@field pack_id string
---@field components table<string, any>

---@class entity
---@field id number|nil Unique entity id, autofilled by decore.create_entity
---@field prefab_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field pack_id string|nil The entity id from decore collections, autofilled by decore.create_entity
---@field parent_prefab_id string|nil The parent prefab_id, used for prefab inheritance
---@field child_instancies decore.entity_prefab_data[]|nil The child instances to spawn on entity creation
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
	local self = setmetatable(ecs.system(), { __index = M }) --[[@as system.decore]]
	self.id = "decore"
	self.filter = ecs.rejectAny("")

	self.decore = decore
	self.id_to_entity = {}

	return self
end


---Apply parent transform to child transform
---@param child_transform table Transform component of child
---@param parent_transform table Transform component of parent
function M.apply_parent_transform(child_transform, parent_transform)
	-- First scale the local position
	local scaled_x = child_transform.position_x * parent_transform.scale_x
	local scaled_y = child_transform.position_y * parent_transform.scale_y

	-- Then rotate the position if parent is rotated
	local rotated_x = scaled_x
	local rotated_y = scaled_y
	local rotation = parent_transform.rotation or 0
	local rad = math.rad(rotation)
	local cos_val = math.cos(rad)
	local sin_val = math.sin(rad)
	rotated_x = scaled_x * cos_val - scaled_y * sin_val
	rotated_y = scaled_x * sin_val + scaled_y * cos_val

	-- Calculate offsets and rotate them by parent rotation
	local offset_x = parent_transform.size_x and (parent_transform.size_x / 2) or 0
	local offset_y = parent_transform.size_y and (parent_transform.size_y / 2) or 0
	local rotated_offset_x = offset_x * cos_val - offset_y * sin_val
	local rotated_offset_y = offset_x * sin_val + offset_y * cos_val

	-- Apply parent position with rotated offset adjustment
	child_transform.position_x = rotated_x + parent_transform.position_x -- rotated_offset_x
	child_transform.position_y = rotated_y + parent_transform.position_y -- rotated_offset_y

	-- Scale: Child scale * parent scale
	child_transform.scale_x = child_transform.scale_x * parent_transform.scale_x
	child_transform.scale_y = child_transform.scale_y * parent_transform.scale_y

	-- Rotation: Child rotation + parent rotation
	child_transform.rotation = child_transform.rotation + parent_transform.rotation
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
	self:spawn_children(entity)
end


---@param entity entity
function M:onRemove(entity)
	self:remove_children(entity)
	self:remove_from_parent(entity)
	self.id_to_entity[entity.id] = nil
end


---@param entity entity
function M:spawn_children(entity)
	-- Create real chilnd entities from prefab data
	local child_entities = entity.child_instancies
	if child_entities then
		entity.children_ids = {}
		for index = 1, #child_entities do
			local child_entity = child_entities[index]
			local child = self.decore.create_prefab(child_entity.prefab_id, child_entity.pack_id, child_entity.components)
			self.decore.apply_component(child, "transform")

			-- Add my position to child
			local child_transform = child.transform
			local parent_transform = entity.transform
			if parent_transform and child_transform then
				M.apply_parent_transform(child_transform, parent_transform)
			end

			-- Is in need to be here?
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
	local children_ids = parent and parent.children_ids

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
