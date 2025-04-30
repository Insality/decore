---@class world
---@field command_debug system.debug.command

---@class system.debug.command
---@field debug system.debug
local M = {}


---@param debug system.debug
---@return system.debug.command
function M.create(debug)
	return setmetatable({ debug = debug }, { __index = M })
end


function M:toggle_profiler()
	for _, e in ipairs(self.debug.entities) do
		self.debug:toggle_profiler(e)
	end
end


function M:toggle_memory_record()
	for _, e in ipairs(self.debug.entities) do
		self.debug:toggle_memory_record(e)
	end
end


function M:restart()
	if html5 then
		html5.run('document.location.reload();')
	else
		msg.post("@system:", "reboot")
	end
end


function M:reset_game()
	self.debug:reset_game()
end

function M:load_slot(slot)
	self.debug:load_slot(slot)
end

function M:save_slot(slot)
	self.debug:save_slot(slot)
end


return M
