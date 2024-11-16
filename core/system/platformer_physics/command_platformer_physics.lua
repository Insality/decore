---@class world
---@field command_platformer_physics command.platformer_physics

---@class command.platformer_physics
---@field platformer_physics system.platformer_physics
local M = {}


---@static
---@return command.platformer_physics
function M.create(platformer_physics)
	return setmetatable({ platformer_physics = platformer_physics }, { __index = M })
end


---@param entity entity
---@param power number Can be zero, means no input
function M:move_vertical(entity, power)
	assert(entity.platformer_physics, "entity must have platformer_physics component")
	---@cast entity entity.platformer_physics

	local pf = entity.platformer_physics
	pf.target_velocity_x = power * pf.speed
end


function M:move_horizontal(entity, power)
	assert(entity.platformer_physics, "entity must have platformer_physics component")
	---@cast entity entity.platformer_physics

	local pf = entity.platformer_physics
	pf.target_velocity_y = power * pf.speed
end


---@param entity entity
function M:jump(entity)
	entity.platformer_physics.desired_jump = true
end


return M
