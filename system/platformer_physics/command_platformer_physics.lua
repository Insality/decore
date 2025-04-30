---@class world
---@field command_platformer_physics system.platformer_physics.command

---@class system.platformer_physics.command
---@field platformer_physics system.platformer_physics
local M = {}


---@static
---@return system.platformer_physics.command
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

	if self.platformer_physics:sign(pf.target_velocity_x) > 0 and pf.contact_timers[3] > 0 then
		pf.target_velocity_x = 0
	end
	if self.platformer_physics:sign(pf.target_velocity_x) < 0 and pf.contact_timers[1] > 0 then
		pf.target_velocity_x = 0
	end
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
