local decore = require("decore.decore")
local command_velocity = require("core.system.velocity.command_velocity")

---@class entity
---@field velocity component.velocity|nil

---@class entity.velocity: entity
---@field velocity component.velocity

---@class component.velocity
---@field angle number
---@field speed number
---@field max_speed number
---@field min_speed number
---@field x number
---@field y number
decore.register_component("velocity", {
	speed = 0,
	angle = 0,
	max_speed = 0,
	min_speed = 0,
	x = 0,
	y = 0
})

---@class system.velocity: system
---@field entities entity.velocity[]
---@field debug_draw boolean
local M = {
	--interval = 0.1
}


---@return system.velocity
function M.create_system()
	return decore.processing_system(M, "velocity", { "velocity", "transform" })
end


function M:onAddToWorld()
	self.debug_draw = false
	self.world.command_velocity = command_velocity.create(self)
end


function M:set_angle(entity, angle)
	local velocity = entity.velocity
	velocity.angle = angle

	-- Update velocity components
	local rad = math.rad(angle)
	velocity.x = math.cos(rad) * velocity.speed
	velocity.y = math.sin(rad) * velocity.speed
end


function M:set_speed(entity, speed)
	local velocity = entity.velocity
	velocity.speed = speed

	-- Update velocity components
	local rad = math.rad(velocity.angle)
	velocity.x = math.cos(rad) * speed
	velocity.y = math.sin(rad) * speed
end


function M:set_velocity(entity, x, y)
	local velocity = entity.velocity

	local speed = math.sqrt(x * x + y * y)
	velocity.speed = decore.clamp(speed, velocity.min_speed, velocity.max_speed)
	velocity.angle = math.deg(math.atan2(y, x))

	-- Adjust x and y
	local rad = math.rad(velocity.angle)
	velocity.x = math.cos(rad) * velocity.speed
	velocity.y = math.sin(rad) * velocity.speed
end


---@param entity entity.velocity
function M:process(entity, dt)
	local velocity = entity.velocity

	self.world.command_transform:add_position(entity, velocity.x * dt, velocity.y * dt)
	self.world.command_transform:set_rotation(entity, velocity.angle)

	--if self.interval then
	--	self.world.command_transform:set_animate_time(entity, self.interval, go.EASING_LINEAR)
	--end

	if self.debug_draw and self.world.command_debug_draw then
		self.world.command_debug_draw:draw_line(
			entity.transform.position_x,
			entity.transform.position_y,
			entity.transform.position_x + velocity.x,
			entity.transform.position_y + velocity.y
		)
	end
end


function M:set_min_speed(entity, min_speed)
	entity.velocity.min_speed = min_speed
end


function M:set_max_speed(entity, max_speed)
	entity.velocity.max_speed = max_speed
end


return M
