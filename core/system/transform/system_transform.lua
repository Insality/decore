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
---@field rotation number
decore.register_component("transform", {
	position = vmath.vector3(0),
	size = vmath.vector3(1),
	scale = vmath.vector3(1),
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
	if t.position.x == x and t.position.y == y and t.position.z == z then
		return
	end

	t.position.x = x or t.position.x
	t.position.y = y or t.position.y
	t.position.z = z or t.position.z

	self.world.event_bus:trigger("transform_event", { entity = entity, is_position_changed = true })
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_scale(entity, x, y, z)
	local t = entity.transform
	if t.scale.x == x and t.scale.y == y and t.scale.z == z then
		return
	end

	t.scale.x = x or t.scale.x
	t.scale.y = y or t.scale.y
	t.scale.z = z or t.scale.z

	self.world.event_bus:trigger("transform_event", { entity = entity, is_scale_changed = true })
end


---@param entity entity.transform
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M:set_size(entity, x, y, z)
	local t = entity.transform
	if t.size.x == x and t.size.y == y and t.size.z == z then
		return
	end

	t.size.x = x or t.size.x
	t.size.y = y or t.size.y
	t.size.z = z or t.size.z

	self.world.event_bus:trigger("transform_event", { entity = entity, is_size_changed = true })
end


function M:set_rotation(entity, rotation)
	local t = entity.transform
	if t.rotation == rotation then
		return
	end

	t.rotation = rotation

	self.world.event_bus:trigger("transform_event", { entity = entity, is_rotation_changed = true })
end


---@param entity entity.transform
---@param animate_time number|nil
---@param easing userdata|nil
function M:set_animate_time(entity, animate_time, easing)
	self.world.event_bus:trigger("transform_event", { entity = entity, animate_time = animate_time, easing = easing })
end


---@param events system.transform.event[]
---@param event system.transform.event
function M.event_merge_policy(events, event)
	for index = #events, 1, -1 do
		local compare_event = events[index]
		if compare_event.entity == event.entity then
			compare_event.is_position_changed = compare_event.is_position_changed or event.is_position_changed
			compare_event.is_scale_changed = compare_event.is_scale_changed or event.is_scale_changed
			compare_event.is_rotation_changed = compare_event.is_rotation_changed or event.is_rotation_changed
			compare_event.is_size_changed = compare_event.is_size_changed or event.is_size_changed
			compare_event.animate_time = event.animate_time or compare_event.animate_time
			compare_event.easing = event.easing or compare_event.easing

			return true
		end
	end
end


return M
