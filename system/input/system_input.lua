local evolved = require("decore.evolved")
local command_input = require("system.input.command_input")

---@class system.input.event: action

---@class system.input: evolved.id
local M = {}


---@return evolved.id
function M.create_system()
	return evolved.builder()
		:include()
		:execute(function(chunk, entity_list, entity_count)
			for i = 1, entity_count do
				local entity = entity_list[i]

			end
		end)
		:spawn()
end


function M:update(chunk, entity_list, entity_count)
	msg.post(".", "acquire_input_focus")
	self.world.command_input = command_input.create(self)
end


function M:onRemoveFromWorld()
	msg.post(".", "release_input_focus")
end


---@param action_id hash
---@param action action
---@return boolean
function M:on_input(action_id, action)
	action.action_id = action_id
	self.world.event_bus:trigger("input_event", action)
	return false
end


return M
