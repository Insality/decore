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
---@field ground_timer number
---@field contact_timers number[]
---@field velocity_x number
---@field velocity_y number
---@field target_velocity_x number
---@field target_velocity_y number
---@field speed number
---@field acceleration number
---@field deceleration number
---@field air_acceleration number
---@field air_deceleration number
---@field turn_speed number
---@field air_turn_speed number
---@field desired_jump boolean
---@field time_to_jump_apex number
---@field jump_height number
---@field jump_speed number
---@field downward_movement_multiplier number
---@field is_instant_movement boolean
---@field jump_duration number
---@field is_double_jump boolean
---@field coyote_time number
---@field jump_buffer number
---@field terminal_velocity number
---@field air_control number
---@field air_brake number
---@field jump_cutoff boolean
---@field correction vector3
decore.register_component("platformer_physics", {
	gravity_x = 0,
	gravity_y = 0,
	gravity_multiplier = 1,
	gravity_scale = 1,
	ground_timer = 0,
	contact_timers = { 0, 0, 0, 0 },

	velocity_x = 0,
	velocity_y = 0,
	target_velocity_x = 0,
	target_velocity_y = 0,

	speed = 10,
	acceleration = 52,
	deceleration = 52,
	air_acceleration = 52,
	air_deceleration = 52,
	turn_speed = 80,
	air_turn_speed = 80,

	desired_jump = false,
	time_to_jump_apex = 0.3,
	jump_height = 7.3,
	jump_speed = 0,
	upward_movement_multiplier = 1,
	downward_movement_multiplier = 6.17,

	jump_buffer_counter = 0,
	coyote_time_counter = 0,

	jump_cutoff = false,
	jump_duration = 0,
	is_double_jump = false,
	coyote_time = 0,
	jump_buffer = 0,
	terminal_velocity = 0,
	air_control = 0,
	air_brake = 0,

	correction = vmath.vector3(),
})

---@class system.platformer_physics: system
---@field entities entity.platformer_physics[]
local M = {}

local RAYCAST_GROUPS = { hash("level") }
local FROM, TO = vmath.vector3(), vmath.vector3()

---@static
---@return system.platformer_physics
function M.create_system()
	return decore.system(M, "platformer_physics", { "platformer_physics", "transform" })
end


function M:onAddToWorld()
	self.world.command_platformer_physics = command_platformer_physics.create(self)
end


function M:postWrap()
	self.world.event_bus:process("collision_event", self.process_collision_event, self)
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

		pf.ground_timer = math.max(0, pf.ground_timer - dt)
		for i = 1, #pf.contact_timers do
			pf.contact_timers[i] = math.max(0, pf.contact_timers[i] - dt)
		end

		-- apply the compensation to the player character
		local corr = pf.correction
		self.world.command_transform:add_position(entity, corr.x, corr.y, corr.z)
		pf.correction.x = 0
		pf.correction.y = 0
		pf.correction.z = 0

		-- update velocity
		self:update_velocity(entity, dt)
	end
end


---@param entity entity.platformer_physics
function M:update_velocity(entity, dt)
	local t = entity.transform
	local pf = entity.platformer_physics

	local is_on_ground = pf.contact_timers[4] > 0
	local is_on_left_wall = pf.contact_timers[1] > 0
	local is_on_ceiling = pf.contact_timers[2] > 0
	local is_on_right_wall = pf.contact_timers[3] > 0

	-- Acceleration
	local acceleration = is_on_ground and pf.acceleration or pf.air_acceleration
	local deceleration = is_on_ground and pf.deceleration or pf.air_deceleration
	local turn_speed = is_on_ground and pf.turn_speed or pf.air_turn_speed

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

	pf.velocity_y = pf.velocity_y + pf.gravity_y * dt

	if is_on_ground then
		pf.velocity_y = math.max(pf.velocity_y, 0)
	end
	if is_on_ceiling then
		pf.velocity_y = math.min(pf.velocity_y, 0)
	end
	if is_on_left_wall then
		pf.velocity_x = math.max(pf.velocity_x, 0)
	end
	if is_on_right_wall then
		pf.velocity_x = math.min(pf.velocity_x, 0)
	end

	local velocity_x = pf.velocity_x
	local velocity_y = pf.velocity_y
	if velocity_x ~= 0 or velocity_y ~= 0 then
		local target_x = t.position_x + velocity_x * dt
		local target_y = t.position_y + velocity_y * dt
		self.world.command_transform:set_position(entity, target_x, target_y)
	end
end


---@param entity entity.platformer_physics
function M:jump(entity)
	local pf = entity.platformer_physics

	if pf.contact_timers[4] > 0 then
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


---@param collision_event event.collision_event
function M:process_collision_event(collision_event)
	local contact_point_event = collision_event.contact_point_event

	if contact_point_event then
		 -- project the correction vector onto the contact normal
		-- (the correction vector is the 0-vector for the first contact point)
		local entity = collision_event.entity
		local pf = entity.platformer_physics
		local normal = collision_event.contact_point_event.b.normal
		if not normal then
			normal = collision_event.contact_point_event.a.normal
		end

		if not normal or not pf then
			return
		end

		local distance = collision_event.contact_point_event.distance

		local proj = vmath.dot(pf.correction, normal)
		-- calculate the compensation we need to make for this contact point
		local comp = (distance - proj) * normal
		-- add it to the correction vector
		pf.correction = pf.correction + comp

		-- check if the normal points enough up to consider the player standing on the ground
		-- (0.7 is roughly equal to 45 degrees deviation from pure vertical direction)
		pf.ground_timer = normal.y > 0.7 and 0.06 or 0

		pf.contact_timers[1] = normal.x > 0.7 and 0.06 or pf.contact_timers[1]
		pf.contact_timers[2] = normal.y < -0.7 and 0.06 or pf.contact_timers[2]
		pf.contact_timers[3] = normal.x < -0.7 and 0.06 or pf.contact_timers[3]
		pf.contact_timers[4] = normal.y > 0.7 and 0.06 or pf.contact_timers[4]

		local velocity = vmath.vector3(0)
		-- project the velocity onto the normal
		proj = vmath.dot(velocity, normal)
		-- if the projection is negative, it means that some of the velocity points towards the contact point
		if proj < 0 then
			-- remove that component in that case
			local c = proj * normal
			pf.velocity_x = pf.velocity_x - c.x
			pf.velocity_y = pf.velocity_y - c.y
		end

		if pf.contact_timers[4] > 0 then
			pf.velocity_y = math.max(0, pf.velocity_y)
		end
	end
end


return M
