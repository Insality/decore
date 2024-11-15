---@class world
---@field command_fsm command.fsm

---@class command.fsm
---@field fsm system.fsm
local M = {}


---@return command.fsm
function M.create(fsm)
	return setmetatable({ fsm = fsm }, { __index = M })
end


---@param entity entity.fsm
---@param event string
function M:trigger(entity, event)
	assert(entity.fsm, "Entity does not have a fsm component.")
	self.fsm:trigger(entity, event)
end


---@param entity entity.fsm
---@return string state Current state of the entity.
function M:get_state(entity)
	assert(entity.fsm, "Entity does not have a fsm component.")
	---@cast entity entity.fsm
	return entity.fsm.state
end


return M
