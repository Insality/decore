local decore = require("decore.decore")
local command_transform = require("core.system.transform.command_transform")

---@class entity
---@field transform component.transform|nil

---@class entity.transform: entity
---@field transform component.transform

---@class entity.command_transform: entity
---@field transform component.transform

---@class component.transform
---@field position vector3 The position vector
---@field size vector3 The size vector
---@field scale vector3 The scale vector
---@field quaternion quaternion The quaternion
---@field rotation number
decore.register_component("transform", {
	position = vmath.vector3(0),
	size = vmath.vector3(1),
	scale = vmath.vector3(1),
	quaternion = vmath.quat(0, 0, 0, 1),
	rotation = 0,
})

---@class system.transform.event
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


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_position(entity, x, y, z)
	local t = entity.transform
	x = x or t.position.x
	y = y or t.position.y
	z = z or t.position.z

	if t.position.x == x and t.position.y == y and t.position.z == z then
		return
	end

	t.position.x = x
	t.position.y = y
	t.position.z = z

	self.world.event_bus:trigger("transform_event", entity, true)
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_scale(entity, x, y, z)
	local t = entity.transform
	x = x or t.scale.x
	y = y or t.scale.y
	z = z or t.scale.z

	if t.scale.x == x and t.scale.y == y and t.scale.z == z then
		return
	end

	t.scale.x = x
	t.scale.y = y
	t.scale.z = z

	self.world.event_bus:trigger("transform_event", entity, true)
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_size(entity, x, y, z)
	local t = entity.transform
	x = x or t.size.x
	y = y or t.size.y
	z = z or t.size.z

	if t.size.x == x and t.size.y == y and t.size.z == z then
		return
	end

	t.size.x = x
	t.size.y = y
	t.size.z = z

	self.world.event_bus:trigger("transform_event", entity, true)
end


---@param entity entity.transform
---@param rotation number In degrees
function M:set_rotation(entity, rotation)
	local t = entity.transform
	if t.rotation == rotation then
		return
	end

	t.rotation = rotation
	t.quaternion.z = math.sin(math.rad(rotation) * 0.5)
	t.quaternion.w = math.cos(math.rad(rotation) * 0.5)

	self.world.event_bus:trigger("transform_event", entity, true)
end


---@param entity entity.transform
---@param animate_time number|nil
---@param easing userdata|nil
function M:set_animate_time(entity, animate_time, easing)
	self.world.event_bus:trigger("transform_event", entity, true)
end


---@param events system.transform.event[]
---@param event system.transform.event
---@param entity entity.transform The entity that triggered the event.
---@param entity_events system.transform.event[] Grouped events by entity it belongs
---@return boolean is_merged
function M.event_merge_policy(events, event, entity, entity_events)
	if #entity_events == 0 then
		return false
	end

	return true
end


return M
