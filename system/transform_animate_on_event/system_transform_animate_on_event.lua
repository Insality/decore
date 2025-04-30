local decore = require("decore.decore")

local HASH_EMPTY = hash("")

---@class entity
---@field transform_animate_on_event component.transform_animate_on_event|nil

---@class entity.transform_animate_on_event: entity
---@field transform_animate_on_event component.transform_animate_on_event
---@field transform component.transform

---@class component.transform_animate_on_event
---@field event_id hash|nil
---@field easing constant
---@field time number
---@field trigger_on_add boolean
---@field is_position_relative boolean
---@field position vector3 x, y, z
---@field is_rotation_relative boolean
---@field rotation vector3 x, y, z
---@field is_scale_relative boolean
---@field scale vector3 x, y, z
---@field is_size_relative boolean
---@field size vector3 x, y, z
decore.register_component("transform_animate_on_event", {
	event_id = nil,
	easing = nil,
	time = 0,

	trigger_on_add = false,

	is_position_relative = false,
	position = nil,

	is_rotation_relative = false,
	rotation = nil,

	is_scale_relative = false,
	scale = nil,

	is_size_relative = false,
	size = nil,
})

---@class system.transform_animate_on_event: system
---@field entities entity.transform_animate_on_event[]
---@field event_to_entities table<string, entity.transform_animate_on_event[]>
---@field event_to_trigger_on_add entity.transform_animate_on_event[]
local M = {}

---@return system.transform_animate_on_event
function M.create_system()
	local system = decore.system(M, "transform_animate_on_event", { "transform_animate_on_event", "transform" })
	system.event_to_entities = {}
	system.event_to_trigger_on_add = {}
	return system
end


function M:postWrap()
	for event_id, entities in pairs(self.event_to_entities) do
		self.world.event_bus:process(event_id, function(event, entity)
			for index = 1, #entities do
				self:process_event(entities[index])
			end
		end)
	end
end


function M:onAdd(entity)
	local event_id = entity.transform_animate_on_event.event_id
	if event_id and event_id ~= HASH_EMPTY then
		self.event_to_entities[event_id] = self.event_to_entities[event_id] or {}
		table.insert(self.event_to_entities[event_id], entity)
	end

	if entity.transform_animate_on_event.trigger_on_add then
		table.insert(self.event_to_trigger_on_add, entity)
	end
end


function M:onRemove(entity)
	local event_id = entity.transform_animate_on_event.event_id
	if event_id and event_id ~= HASH_EMPTY then
		local entities = self.event_to_entities[event_id]
		if not entities then
			return
		end

		for index = #entities, 1, -1 do
			if entities[index] == entity then
				table.remove(entities, index)
				break
			end
		end
	end
end


function M:update()
	for index = #self.event_to_trigger_on_add, 1, -1 do
		self:process_event(self.event_to_trigger_on_add[index])
		self.event_to_trigger_on_add[index] = nil
	end
end


---@param entity entity.transform_animate_on_event
function M:process_event(entity)
	local transform = entity.transform
	local animate_transform = entity.transform_animate_on_event

	local position = animate_transform.position
	if position then
		local x, y, z = position.x, position.y, position.z
		if animate_transform.is_position_relative then
			x, y, z = x + transform.position_x, y + transform.position_y, z + transform.position_z
		end
		self.world.command_transform:set_position(entity, x, y, z)
	end

	local rotation = animate_transform.rotation
	if rotation then
		local euler_z = rotation.z
		if animate_transform.is_rotation_relative then
			euler_z = euler_z + transform.rotation
		end
		self.world.command_transform:set_rotation(entity, euler_z)
	end

	local scale = animate_transform.scale
	if scale then
		local x, y, z = scale.x, scale.y, scale.z
		if animate_transform.is_scale_relative then
			x, y, z = x + transform.scale_x, y + transform.scale_y, z + transform.scale_z
		end
		self.world.command_transform:set_scale(entity, x, y, z)
	end

	local size = animate_transform.size
	if size then
		local x, y, z = size.x, size.y, size.z
		if animate_transform.is_size_relative then
			x, y, z = x + transform.size_x, y + transform.size_y, z + transform.size_z
		end
		self.world.command_transform:set_size(entity, x, y, z)
	end

	self.world.command_transform:set_animate_time(entity, animate_transform.time, animate_transform.easing)
end


return M
