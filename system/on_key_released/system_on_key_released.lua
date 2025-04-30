local decore = require("decore.decore")

---@class entity
---@field on_key_released component.on_key_released|nil

---@class entity.on_key_released: entity
---@field on_key_released component.on_key_released

---@class component.on_key_released
---@field key_to_command_json string|nil @JSON string table<key_id, table<component_id: component_data>>. Will override key_to_command if exists
---@field key_to_command table<string, table<string, table>>|nil @ table<key_id, table<component_id: component_data>>.
decore.register_component("on_key_released")

---@class system.on_key_released: system
---@field entities entity.on_key_released[]
---@field hash_to_string table<hash, string>
local M = {}


---@return system.on_key_released
function M.create_system()
	local system = decore.system(M, "on_key_released", "on_key_released")
	system.hash_to_string = {}

	return system
end


function M:postWrap()
	self.world.event_bus:process("input_event", self.process_input_event, self)
end


---@param entity entity.on_key_released
function M:onAdd(entity)
	local on_key_released = entity.on_key_released

	for key_id, key_command in pairs(on_key_released) do
		local hash_id = hash(key_id)
		if not self.hash_to_string[hash_id] then
			self.hash_to_string[hash_id] = key_id
		end
	end
end


---@param input_event system.input.event
function M:process_input_event(input_event)
	if not input_event.released then
		return
	end

	local key_id = self.hash_to_string[input_event.action_id]
	if not key_id then
		return
	end

	local entities = self.entities
	for index = 1, #entities do
		local entity = entities[index]
		self:on_input_released(entity, input_event.action_id, input_event)
	end
end


---@param entity entity.on_key_released
function M:on_input_released(entity, action_id, action)
	local on_key_released = entity.on_key_released

	local key_id = self.hash_to_string[action_id]
	if on_key_released[key_id] then
		decore.call_command(self.world, on_key_released[key_id])
	end
end


return M
