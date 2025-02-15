-- command_velocity.lua
---@class world
---@field command_velocity system.velocity.command

---@class system.velocity.command
---@field velocity system.velocity
local M = {}


---@param velocity system.velocity
---@return system.velocity.command
function M.create(velocity)
	return setmetatable({ velocity = velocity }, { __index = M })
end


function M:set_velocity(entity, x, y)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_velocity(entity, x, y)
end


function M:add_velocity(entity, x, y)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_velocity(entity, entity.velocity.x + x, entity.velocity.y + y)
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


function M:set_min_speed(entity, min_speed)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_min_speed(entity, min_speed)
end


function M:set_max_speed(entity, max_speed)
	assert(entity.velocity, "Entity does not have a velocity component.")
	---@cast entity entity.velocity
	self.velocity:set_max_speed(entity, max_speed)
end


return M
