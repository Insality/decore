local decore = require("decore.decore")
local command_transform = require("core.system.transform.command_transform")

---@class entity
---@field transform component.transform|nil

---@class entity.transform: entity
---@field transform component.transform

---@class entity.command_transform: entity
---@field transform component.transform

---@class component.transform
---@field position_x number
---@field position_y number
---@field position_z number
---@field size_x number
---@field size_y number
---@field size_z number
---@field scale_x number
---@field scale_y number
---@field scale_z number
---@field rotation number
---@field is_position_changed boolean|nil
---@field is_scale_changed boolean|nil
---@field is_rotation_changed boolean|nil
---@field is_size_changed boolean|nil
---@field animate_time number|nil
---@field easing userdata|nil
decore.register_component("transform", {
	position_x = 0,
	position_y = 0,
	position_z = 0,
	size_x = 1,
	size_y = 1,
	size_z = 1,
	scale_x = 1,
	scale_y = 1,
	scale_z = 1,
	rotation = 0,
})

---@class event.transform_event
---@field entity entity.transform The entity that was changed.
---@field is_position_changed boolean|nil If true, the position was changed.
---@field is_scale_changed boolean|nil If true, the scale was changed.
---@field is_rotation_changed boolean|nil If true, the rotation was changed.
---@field is_size_changed boolean|nil If true, the size was changed.
---@field animate_time number|nil If true, the time it took to animate the transform.
---@field easing userdata|nil The easing function used for the animation.

---@class system.transform: system
---@field entities entity.transform[]
local M = {}


---@return system.transform
function M.create_system()
	return decore.system(M, "transform", "transform")
end


function M:onAddToWorld()
	self.world.command_transform = command_transform.create(self)
	self.world.event_bus:set_merge_policy("transform_event", self.event_merge_policy)
end


function M:preWrap()
	for index = 1, #self.entities do
		local transform = self.entities[index].transform
		transform.is_position_changed = nil
		transform.is_scale_changed = nil
		transform.is_rotation_changed = nil
		transform.is_size_changed = nil
		transform.animate_time = nil
		transform.easing = nil
	end
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_position(entity, x, y, z)
	local t = entity.transform
	if t.position_x == x and t.position_y == y and t.position_z == z then
		return
	end

	t.position_x = x or t.position_x
	t.position_y = y or t.position_y
	t.position_z = z or t.position_z
	t.is_position_changed = true

	self.world.event_bus:trigger("transform_event", entity)
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_scale(entity, x, y, z)
	local t = entity.transform
	if t.scale_x == x and t.scale_y == y and t.scale_z == z then
		return
	end

	t.scale_x = x or t.scale_x
	t.scale_y = y or t.scale_y
	t.scale_z = z or t.scale_z
	t.is_scale_changed = true

	self.world.event_bus:trigger("transform_event", entity)
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_size(entity, x, y, z)
	local t = entity.transform
	if t.size_x == x and t.size_y == y and t.size_z == z then
		return
	end

	t.size_x = x or t.size_x
	t.size_y = y or t.size_y
	t.size_z = z or t.size_z
	t.is_size_changed = true

	self.world.event_bus:trigger("transform_event", entity)
end


function M:set_rotation(entity, rotation)
	local t = entity.transform
	if t.rotation == rotation then
		return
	end

	t.rotation = rotation
	t.is_rotation_changed = true

	self.world.event_bus:trigger("transform_event", entity)
end


---@param entity entity.transform
---@param animate_time number|nil
---@param easing userdata|nil
function M:set_animate_time(entity, animate_time, easing)
	self.world.event_bus:trigger("transform_event", entity)
end


---@param entities entity.transform[]
---@param entity entity.transform
function M.event_merge_policy(entities, entity)
	for index = #entities, 1, -1 do
		local compare_entity = entities[index]
		if compare_entity == entity then
			local ct = compare_entity.transform
			local t = entity.transform
			ct.is_position_changed = ct.is_position_changed or t.is_position_changed
			ct.is_scale_changed = ct.is_scale_changed or t.is_scale_changed
			ct.is_rotation_changed = ct.is_rotation_changed or t.is_rotation_changed
			ct.is_size_changed = ct.is_size_changed or t.is_size_changed
			ct.animate_time = t.animate_time or ct.animate_time
			ct.easing = t.easing or ct.easing

			return true
		end
	end

	return false
end


return M
