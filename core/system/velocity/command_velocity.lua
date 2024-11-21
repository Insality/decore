-- command_velocity.lua
---@class world
---@field command_velocity command.velocity

---@class command.velocity
---@field velocity system.velocity
local M = {}


---@param velocity system.velocity
---@return command.velocity
function M.create(velocity)
	return setmetatable({ velocity = velocity }, { __index = M })
end


---Set entity velocity angle
---@param entity entity
---@param angle number Angle in degrees
function M:set_angle(entity, angle)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_angle(entity, angle)
end


---Set entity velocity speed
---@param entity entity
---@param speed number Speed value
function M:set_speed(entity, speed)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_speed(entity, speed)
end


---Set entity acceleration
---@param entity entity
---@param acceleration number
function M:set_acceleration(entity, acceleration)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_acceleration(entity, acceleration)
end


---Stop entity movement
---@param entity entity
function M:stop(entity)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_speed(entity, 0)
	self.velocity:set_acceleration(entity, 0)
end


return M