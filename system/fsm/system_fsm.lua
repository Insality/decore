local decore = require("decore.decore")
local command_fsm = require("system.fsm.command_fsm")

local logger = decore.get_logger("system.fsm")

---@class entity
---@field fsm component.fsm|nil

---@class entity.fsm: entity
---@field fsm component.fsm

---@class component.fsm
---@field state string|nil
---@field events table<string, table<string, string>>|nil
decore.register_component("fsm")

---@class system.fsm.event
---@field entity entity
---@field event string
---@field state_before string
---@field state_new string

---@class system.fsm: system
---@field entities entity.fsm[]
local M = {}


---@return system.fsm
function M.create_system()
	return decore.system(M, "fsm", "fsm")
end


function M:onAddToWorld()
	self.world.command_fsm = command_fsm.create(self)
end


---@param entity entity.fsm
---@param event string
function M:trigger(entity, event)
	local next_state = self:get_next_state(entity, event)
	if next_state then
		local state_before = entity.fsm.state
		entity.fsm.state = next_state

		self.world.event_bus:trigger("fsm_event", {
			entity = entity,
			event = event,
			state_before = state_before,
			state_new = next_state,
		})

		logger:info("FSM event triggered", {
			entity = entity,
			event = event,
			state_before = state_before,
			state_new = next_state,
		})
	end
end


---Return next state if event will be triggered.
---@param entity entity.fsm
---@param event string
---@return string|nil next_state Next state if event will be triggered. Nil if event is not allowed.
function M:get_next_state(entity, event)
	local events = entity.fsm.events[event]
	if events then
		return events[entity.fsm.state] or events["*"] or nil
	end

	return nil
end


return M
