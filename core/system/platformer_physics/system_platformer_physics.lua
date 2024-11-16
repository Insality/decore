local decore = require("decore.decore")

local command_platformer_physics = require("core.system.platformer_physics.command_platformer_physics")

---@class entity
---@field platformer_physics component.platformer_physics|nil

---@class entity.platformer_physics: entity
---@field platformer_physics component.platformer_physics
---@field transform component.transform

---@class component.platformer_physics
---@field gravity_x number
---@field gravity_y number
---@field gravity_multiplier number
---@field gravity_scale number
---@field is_on_ground boolean
---@field velocity_x number
---@field velocity_y number
---@field target_velocity_x number
---@field target_velocity_y number
---@field max_speed number
---@field max_acceleration number
---@field max_deceleration number
---@field max_air_acceleration number
---@field max_air_deceleration number
---@field max_turn_speed number
---@field max_air_turn_speed number
---@field desired_jump boolean
---@field time_to_jump_apex number
---@field jump_height number
---@field jump_speed number
---@field downward_movement_multiplier number
decore.register_component("platformer_physics", {
	gravity_x = 0,
	gravity_y = 0,
	gravity_multiplier = 1,
	gravity_scale = 1,
	is_on_ground = false,

	velocity_x = 0,
	velocity_y = 0,
	target_velocity_x = 0,
	target_velocity_y = 0,

	max_speed = 10,
	max_acceleration = 52,
	max_deceleration = 52,
	max_air_acceleration = 52,
	max_air_deceleration = 52,
	max_turn_speed = 80,
	max_air_turn_speed = 80,

	desired_jump = false,
	time_to_jump_apex = 0.3,
	jump_height = 7.3,
	jump_speed = 0,
	upward_movement_multiplier = 1,
	downward_movement_multiplier = 6.17,

	jump_buffer_counter = 0,
	coyote_time_counter = 0,
})

---@class system.platformer_physics: system
---@field entities entity.platformer_physics[]
local M = {}

local RAYCAST_GROUPS = { hash("level") }
local FROM, TO = vmath.vector3(), vmath.vector3()

---@static
---@return system.platformer_physics
function M.create_system()
	return decore.processing_system(M, "platformer_physics", { "platformer_physics", "transform" })
end


function M:onAddToWorld()
	self.world.command_platformer_physics = command_platformer_physics.create(self)
end


---@param entity entity.platformer_physics
function M:process(entity, dt)
	local t = entity.transform
	local pf = entity.platformer_physics

	pf.is_on_ground = self:is_on_ground(entity)

	-- Acceleration
	local acceleration = pf.is_on_ground and pf.max_acceleration or pf.max_air_acceleration
	local deceleration = pf.is_on_ground and pf.max_deceleration or pf.max_air_deceleration
	local turn_speed = pf.is_on_ground and pf.max_turn_speed or pf.max_air_turn_speed

	local max_speed_change = deceleration * dt
	if pf.target_velocity_x ~= 0 then
		if self:sign(pf.target_velocity_x) ~= self:sign(pf.velocity_x) then
			max_speed_change = turn_speed * dt
		else
			max_speed_change = acceleration * dt
		end
	end

	pf.velocity_x = self:step(pf.velocity_x, pf.target_velocity_x, max_speed_change)

	local gravity_y = (-2 * pf.jump_height) / (pf.time_to_jump_apex * pf.time_to_jump_apex)
	pf.gravity_scale = (gravity_y / pf.gravity_y) * pf.gravity_multiplier

	if not pf.is_on_ground then
		pf.velocity_y = pf.velocity_y + pf.gravity_y * dt
	else
		if pf.velocity_y < 0 then
			pf.velocity_y = 0
		end
	end

	local velocity_x = pf.velocity_x
	local velocity_y = pf.velocity_y
	if velocity_x ~= 0 or velocity_y ~= 0 then
		local target_x = t.position_x + velocity_x * dt
		local target_y = t.position_y + velocity_y * dt
		self.world.command_transform:set_position(entity, target_x, target_y)
	end
end


function M:fixed_update(dt)
	for index = 1, #self.entities do
		local entity = self.entities[index]
		local pf = entity.platformer_physics

		if pf.desired_jump then
			self:jump(entity)
			return
		end

		if pf.velocity_y == 0 then
			pf.gravity_multiplier = 1
		end
		if pf.velocity_y < -0.01 then
			pf.gravity_multiplier = pf.downward_movement_multiplier
		end

	end
end


---@param entity entity.platformer_physics
function M:jump(entity)
	local pf = entity.platformer_physics

	if pf.is_on_ground then
		pf.desired_jump = false
		pf.jump_speed = math.sqrt(-2 * pf.gravity_y * pf.jump_height * pf.gravity_scale)

		if pf.velocity_y > 0 then
			pf.jump_speed = math.max(pf.jump_speed - pf.velocity_y, 0)
		elseif pf.velocity_y < 0 then
			pf.jump_speed = pf.jump_speed + math.abs(pf.velocity_y)
		end

		pf.velocity_y = pf.velocity_y + pf.jump_speed
	end

	pf.desired_jump = false
end


---@param entity entity.platformer_physics
---@return boolean
function M:is_on_ground(entity)
	local t = entity.transform
	local pf = entity.platformer_physics

	FROM.x = t.position_x
	FROM.y = t.position_y
	TO.x = t.position_x
	TO.y = t.position_y - t.size_y/2 - 1
	return not not (physics.raycast(FROM, TO, RAYCAST_GROUPS))
end


function M:sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	else
		return 0
	end
end


---Move value from current to target value with step amount
---@param current number Current value
---@param target number Target value
---@param step number Step amount
---@return number New value
function M:step(current, target, step)
	if current < target then
		return math.min(current + step, target)
	else
		return math.max(target, current - step)
	end
end


return M
