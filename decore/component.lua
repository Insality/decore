-- Use it to register a component to an entity.script
--[[
go.property("delay", 0.5)

local component = require("decore.component")

function init(self)
	component.init("remove_with_delay", self.delay)
end
--]]

local SET_COMPONENT = hash("set_component")
local COMPONENTS_TO_REGISTER = hash("components_to_register")

local M = {}

function M.init(component_id, component_data)
	local entity_count = go.get("#entity", COMPONENTS_TO_REGISTER)
	go.set("#entity", COMPONENTS_TO_REGISTER, entity_count + 1)

	msg.post(".", SET_COMPONENT, {
		id = component_id,
		data = component_data
	})
end

return M
