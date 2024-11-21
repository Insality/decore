local decore = require("decore.decore")
local command_velocity = require("core.system.velocity.command_velocity")

---@class entity
---@field velocity component.velocity|nil

---@class entity.velocity: entity
---@field velocity component.velocity

---@class component.velocity
---@field angle number
---@field speed number
---@field acceleration number
---@field max_speed number
---@field min_speed number
---@field max_acceleration number
---@field min_acceleration number
---@field x number
---@field y number
decore.register_component("velocity", {
	speed = 0,
	angle = 0,
	acceleration = 0,
	max_speed = 0,
	min_speed = 0,
	max_acceleration = 0,
	min_acceleration = 0,
	x = 0,
	y = 0,
})

---@class system.velocity: system
---@field entities entity.velocity[]
local M = {}


---@return system.velocity
function M.create_system()
	return decore.processing_system(M, "velocity", { "velocity", "transform" })
end


function M:onAddToWorld()
	self.world.command_velocity = command_velocity.create(self)
end


function M:set_angle(entity, angle)
	local velocity = entity.velocity
	velocity.angle = angle
end


function M:set_speed(entity, speed)
	local velocity = entity.velocity
	if velocity.max_speed > 0 then
		speed = math.min(speed, velocity.max_speed)
	end
	if velocity.min_speed > 0 then
		speed = math.max(speed, velocity.min_speed)
	end
	velocity.speed = speed
end


function M:set_acceleration(entity, acceleration)
	local velocity = entity.velocity
	if velocity.max_acceleration > 0 then
		acceleration = math.min(acceleration, velocity.max_acceleration)
	end
	if velocity.min_acceleration > 0 then
		acceleration = math.max(acceleration, velocity.min_acceleration)
	end
	velocity.acceleration = acceleration
end


function M:process(entity, dt)
	local velocity = entity.velocity

	velocity.angle = velocity.angle + 1
	-- Apply acceleration
	velocity.speed = velocity.speed + velocity.acceleration * dt

	-- Clamp speed
	if velocity.max_speed > 0 then
		velocity.speed = math.min(velocity.speed, velocity.max_speed)
	end
	if velocity.min_speed > 0 then
		velocity.speed = math.max(velocity.speed, velocity.min_speed)
	end

	-- Update velocity components
	local rad = math.rad(velocity.angle)
	velocity.x = math.cos(rad) * velocity.speed
	velocity.y = math.sin(rad) * velocity.speed

	self.world.command_transform:add_position(entity, velocity.x * dt, velocity.y * dt)
	self.world.command_transform:set_rotation(entity, velocity.angle)
end


return M
