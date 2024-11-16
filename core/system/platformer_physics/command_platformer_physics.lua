local decore = require("decore.decore")

---@class world
---@field command_platformer_physics system.command_platformer_physics

---@class system.command_platformer_physics: command_system
---@field platformer_physics system.platformer_physics
local M = {}


---@static
---@return system.command_platformer_physics
function M.create_system(platformer_physics)
	local system = decore.system(M, "command_platformer_physics")
	system.platformer_physics = platformer_physics

	return system
end


---@private
function M:onAddToWorld()
	self.world.command_platformer_physics = self
end


---@private
function M:onRemoveFromWorld()
	self.world.command_platformer_physics = nil
end


---@param entity entity
---@param power number Can be zero, means no input
function M:move_vertical(entity, power)
	assert(entity.platformer_physics, "entity must have platformer_physics component")
	---@cast entity entity.platformer_physics

	local pf = entity.platformer_physics
	pf.target_velocity_x = power * pf.max_speed
end


function M:move_horizontal(entity, power)
	assert(entity.platformer_physics, "entity must have platformer_physics component")
	---@cast entity entity.platformer_physics

	local pf = entity.platformer_physics
	pf.target_velocity_y = power * pf.max_speed
end


---@param entity entity
function M:jump(entity)
	entity.platformer_physics.desired_jump = true
end


return M
