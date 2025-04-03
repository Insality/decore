local log = require("log.log")
local saver = require("saver.saver")
local decore = require("decore.decore")

local logger = log.get_logger("debug")

local command_debug = require("core.system.debug.command_debug")

---@class entity
---@field debug component.debug|nil

---@class entity.debug: entity
---@field debug component.debug

---@class component.debug
---@field is_profiler_active boolean
---@field profiler_mode userdata|nil
---@field timer_memory_record number|nil
decore.register_component("debug", {
	is_profiler_active = false,
	profiler_mode = nil,
	timer_memory_record = nil,
})

---@class system.debug: system
---@field entities entity.debug[]
local M = {}


---@return system.debug
function M.create_system()
	return decore.system(M, "debug", "debug")
end


function M:onAddToWorld()
	self.world.command_debug = command_debug.create(self)
end


---@param entity entity.debug
function M:toggle_profiler(entity)
	local d = entity.debug

	if not d.profiler_mode then
		d.profiler_mode = profiler.VIEW_MODE_MINIMIZED
		profiler.enable_ui(true)
		profiler.set_ui_view_mode(d.profiler_mode)
	elseif d.profiler_mode == profiler.VIEW_MODE_MINIMIZED then
		d.profiler_mode = profiler.VIEW_MODE_FULL
		profiler.enable_ui(true)
		profiler.set_ui_view_mode(d.profiler_mode)
	else
		profiler.enable_ui(false)
		d.profiler_mode = nil
	end

	logger:info("Profiler is active: " .. tostring(d.is_profiler_active))
end


---@param entity entity.debug
function M:toggle_memory_record(entity)
	local d = entity.debug

	if d.timer_memory_record then
		timer.cancel(d.timer_memory_record)
		d.timer_memory_record = nil
		logger:info("Memory record stopped")
		collectgarbage("restart")
		collectgarbage("collect")
	else
		collectgarbage("collect")
		collectgarbage("stop")
		local memory = collectgarbage("count")
		d.timer_memory_record = timer.delay(1, true, function()
			local new_memory = collectgarbage("count")
			logger:info("Memory: " .. new_memory - memory)
			memory = new_memory
		end)
		logger:info("Memory record started")
	end
end


function M:reset_game()
	logger:debug("Game reset")
	saver.delete_game_state()
	sys.reboot()
end


function M:load_slot(slot)
	logger:debug("Game loaded from slot: " .. slot)
	sys.reboot("--config=saver.save_name=" .. slot, "--config=saver.autosave_timer=0")
end


function M:save_slot(slot)
	saver.save_game_state(slot)
	logger:debug("Game saved to slot: " .. slot)
end


function M:restart()
	if html5 then
		html5.run('document.location.reload();')
	else
		msg.post("@system:", "reboot")
	end
end


return M
