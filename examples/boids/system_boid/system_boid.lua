local decore = require("decore.decore")
local command_boid = require("examples.boids.system_boid.command_boid")
local bindings = require("druid.bindings")

---@class entity
---@field boid component.boid|nil

---@class entity.boid: entity
---@field boid component.boid
---@field transform component.transform
---@field transform_border component.transform_border|nil
---@field velocity component.velocity

---@class component.boid.neighbor
---@field dx number
---@field dy number
---@field dist_sq number
---@field entity entity.boid

---@class component.boid
---@field widget gui.boid_sensor
---@field speed number
---@field separation_radius number
---@field alignment_radius number
---@field cohesion_radius number
---@field max_force number
---@field neighbors component.boid.neighbor[]
---@field separation_weight number
---@field alignment_weight number
---@field cohesion_weight number
---@field turn_factor number -- new
---@field visual_range number
---@field protected_range number
---@field centering_factor number
---@field avoid_factor number The force to avoid other boids
---@field matching_factor number
---@field max_bias number
---@field bias_increment number
---@field bias_val number
decore.register_component("boid", {
	neighbors = {},
	turn_factor = 180,
	visual_range = 40,
	protected_range = 8,
	centering_factor = 0.0005,
	avoid_factor = 0.05,
	matching_factor = 0.05,
})

---@class system.boid: system
---@field entities entity.boid[]
---@field debug_draw_force boolean
local M = {}


local COLOR_FORCE = vmath.vector4(1, 0, 0, 1)

function M.create_system()
	return decore.system(M, "boid", { "boid", "transform", "velocity" })
end


function M:onAddToWorld()
	self.debug_draw_force = false
	self.world.command_boid = command_boid.create(self)
end


function M:onAdd(entity)
	--c_system_boid.add_entity(entity)
	--local widget = bindings.get_widget(entity.game_object.root)
	--entity.boid.widget = widget
end

function M:onRemove(entity)
	--c_system_boid.remove_entity(entity)
end


function M:update(dt)
	--c_system_boid.update(dt)

	--local divider = 60
	--local entities_per_frame = math.ceil(#self.entities / 60 * divider)
	--self.current_index = self.current_index or 1
	--local entities_from = self.current_index
	--local entities_to = math.min(self.current_index + entities_per_frame - 1, #self.entities)
	--self.current_index = entities_to + 1
	--if self.current_index > #self.entities then
	--	self.current_index = 1
	--end

	for index = 1, #self.entities do
		local entity = self.entities[index]
		self:process(entity, dt)

		--entity.boid.widget:set_position(entity.transform.position_x, entity.transform.position_y)
		--entity.boid.widget:set_rotation(entity.transform.rotation)
	end
end


function M:process(entity, dt)
	local force_x, force_y = self:calculate_forces_new(entity)
	self.world.command_velocity:add_velocity(entity, force_x * dt, force_y * dt)

	if self.debug_draw_force and self.world.command_debug_draw then
		self.world.command_debug_draw:draw_line(
			entity.transform.position_x,
			entity.transform.position_y,
			entity.transform.position_x + force_x,
			entity.transform.position_y + force_y,
			COLOR_FORCE
		)
	end
end


---@param entity entity.boid
function M:calculate_forces_new(entity)
	local boid = entity.boid
	local protected_rande_sq = boid.protected_range * boid.protected_range

	self._entity = entity
	self._protected_rande_sq = protected_rande_sq
	self._average_position_x = 0
	self._average_position_y = 0
	self._average_velocity_x = 0
	self._average_velocity_y = 0
	self._neighboring_boids = 0
	self._close_dx = 0
	self._close_dy = 0

	self.calculate_neighbor = self.calculate_neighbor or function(other_boid)
		if other_boid ~= self._entity then
			local dx = other_boid.transform.position_x - self._entity.transform.position_x
			local dy = other_boid.transform.position_y - self._entity.transform.position_y
			local dist = dx * dx + dy * dy

			if dist < self._protected_rande_sq then
				self._close_dx = self._close_dx + dx
				self._close_dy = self._close_dy + dy
			elseif dist < boid.visual_range * boid.visual_range then
				self._average_position_x = self._average_position_x + other_boid.transform.position_x
				self._average_position_y = self._average_position_y + other_boid.transform.position_y
				self._average_velocity_x = self._average_velocity_x + other_boid.velocity.x
				self._average_velocity_y = self._average_velocity_y + other_boid.velocity.y
				self._neighboring_boids = self._neighboring_boids + 1
			end
		end
	end

	self.world.command_quadtree:get_neighbors(entity, math.max(boid.visual_range, boid.protected_range), self.calculate_neighbor)

	local average_position_x, average_position_y = self._average_position_x, self._average_position_y
	local average_velocity_x, average_velocity_y = self._average_velocity_x, self._average_velocity_y
	local neighboring_boids = self._neighboring_boids
	local close_dx, close_dy = self._close_dx, self._close_dy
	local force_x = 0
	local force_y = 0

	if neighboring_boids > 0 then
		average_position_x = average_position_x / neighboring_boids
		average_position_y = average_position_y / neighboring_boids
		average_velocity_x = average_velocity_x / neighboring_boids
		average_velocity_y = average_velocity_y / neighboring_boids

		force_x = force_x + (average_position_x - entity.transform.position_x) * boid.centering_factor
				+ (average_velocity_x - entity.velocity.x) * boid.matching_factor

		force_y = force_y + (average_position_y - entity.transform.position_y) * boid.centering_factor
	end

	if close_dx ~= 0 or close_dy ~= 0 then
		force_x = force_x - close_dx * boid.avoid_factor
		force_y = force_y - close_dy * boid.avoid_factor
	end

	-- Here can be turn factor around edges
	local border = entity.transform_border and entity.transform_border.border
	local transform = entity.transform
	if border then
		if transform.position_y > border.y then
			force_y = force_y - boid.turn_factor
		end
		if transform.position_y < border.w then
			force_y = force_y + boid.turn_factor
		end
		if transform.position_x > border.z then
			force_x = force_x - boid.turn_factor
		end
		if transform.position_x < border.x then
			force_x = force_x + boid.turn_factor
		end
	end

	return force_x, force_y
end


return M
