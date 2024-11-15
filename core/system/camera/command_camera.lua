local decore = require("decore.decore")

---@class world
---@field command_camera system.command_camera

---@class system.command_camera: command_system
---@field camera system.camera|nil @Current camera system
---@field previous_camera_state table<string, any>|nil @Previous camera state
local M = {}


---@return system.command_camera
function M.create_system(camera_system)
	local system = decore.system(M, "command_camera")
	system.camera = camera_system

	return system
end


---@private
function M:onAddToWorld()
	self.world.command_camera = self
end


---@private
function M:onRemoveFromWorld()
	self.world.command_camera = nil
end


---@param power number
---@param time number
function M:shake(power, time)
	self.camera.shake_power = power
	self.camera.shake_time = time
end


function M:world_to_screen(x, y)
	return self.camera.world_to_screen(x, y)
end


function M:screen_to_world(x, y)
	return self.camera.screen_to_world(x, y)
end


return M
