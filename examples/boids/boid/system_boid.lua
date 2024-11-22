local decore = require("decore.decore")
local command_boid = require("examples.boids.boid.command_boid")

---@class entity
---@field boid component.boid|nil

---@class entity.boid: entity
---@field boid component.boid

---@class component.boid
---@field speed number
---@field separation_radius number
---@field alignment_radius number
---@field cohesion_radius number
---@field max_speed number
---@field max_force number
---@field neighbors table
---@field separation_weight number
---@field alignment_weight number
---@field cohesion_weight number
decore.register_component("boid", {
	speed = 100,
	separation_radius = 70,
	alignment_radius = 100,
	cohesion_radius = 120,
	max_speed = 100,
	max_force = 100,
	neighbors = {},
	separation_weight = 1.0,
	alignment_weight = 1.0,
	cohesion_weight = 1.0
})

---@class system.boid: system
---@field entities entity.boid[]
local M = {}

function M.create_system()
	return decore.processing_system(M, "boid", { "boid", "transform", "velocity" })
end


function M:onAddToWorld()
	self.world.command_boid = command_boid.create(self)
end

function M:process(entity, dt)
	self:update_neighbors(entity)
	local force_x, force_y = self:calculate_forces(entity)

	local boid = entity.boid
	local velocity = entity.velocity

	local vx = force_x * dt * boid.speed
	local vy = force_y * dt * boid.speed

	-- Update velocity
	self.world.command_velocity:add_velocity(entity, vx, vy)
end

function M:update_neighbors(entity)
	local boid = entity.boid
	local transform = entity.transform
	local neighbors = boid.neighbors
	local pos_x, pos_y = transform.position_x, transform.position_y
	local max_radius = math.max(boid.separation_radius, boid.alignment_radius, boid.cohesion_radius)
	local max_radius_sq = max_radius * max_radius

	-- Get border dimensions
	local border = entity.transform_border and entity.transform_border.border
	if border and entity.transform_border.is_wrap then
		local border_left = border.x
		local border_top = border.y
		local border_right = border.z
		local border_bottom = border.w

		local border_width = border_right - border_left
		local border_height = border_top - border_bottom

		for index = 1, #self.entities do
			local other = self.entities[index]
			local dx = other.transform.position_x - pos_x
			local dy = other.transform.position_y - pos_y

			-- Wrap dx
			if dx > border_width / 2 then
				dx = dx - border_width
			elseif dx < -border_width / 2 then
				dx = dx + border_width
			end

			-- Wrap dy
			if dy > border_height / 2 then
				dy = dy - border_height
			elseif dy < -border_height / 2 then
				dy = dy + border_height
			end

			local dist_sq = dx * dx + dy * dy

			if dist_sq < max_radius_sq then
				if not neighbors[other] then
					neighbors[other] = {}
					table.insert(neighbors, neighbors[other])
				end
				neighbors[other].dx = dx
				neighbors[other].dy = dy
				neighbors[other].dist_sq = dist_sq
				neighbors[other].entity = other
			end
		end
	else
		-- No wrapping
		for index = 1, #self.entities do
			local other = self.entities[index]
			local dx = other.transform.position_x - pos_x
			local dy = other.transform.position_y - pos_y
			local dist_sq = dx * dx + dy * dy

			if dist_sq < max_radius_sq then
				if not neighbors[other] then
					neighbors[other] = {}
					table.insert(neighbors, neighbors[other])
				end
				neighbors[other].dx = dx
				neighbors[other].dy = dy
				neighbors[other].dist_sq = dist_sq
				neighbors[other].entity = other
			end
		end
	end

	boid.neighbors = neighbors
end

function M:calculate_forces(entity)
	local boid = entity.boid
	local separation_x, separation_y = 0, 0
	local alignment_x, alignment_y = 0, 0
	local cohesion_x, cohesion_y = 0, 0
	local count_alignment = 0
	local count_cohesion = 0

	for i = 1, #boid.neighbors do
		local neighbor = boid.neighbors[i]
		local other = neighbor.entity
		local t = entity.transform
		local dist_sq = neighbor.dist_sq

		-- Separation
		if dist_sq < boid.separation_radius * boid.separation_radius then
			local dist = math.sqrt(dist_sq)
			if dist > 0 then
				local force = (boid.separation_radius - dist) / boid.separation_radius
				separation_x = separation_x - neighbor.dx / dist * force
				separation_y = separation_y - neighbor.dy / dist * force
			end
		end

		-- Alignment
		if dist_sq < boid.alignment_radius * boid.alignment_radius then
			alignment_x = alignment_x + other.velocity.x
			alignment_y = alignment_y + other.velocity.y
			count_alignment = count_alignment + 1
		end

		-- Cohesion
		if dist_sq < boid.cohesion_radius * boid.cohesion_radius then
			cohesion_x = cohesion_x + t.position_x
			cohesion_y = cohesion_y + t.position_y
			count_cohesion = count_cohesion + 1
		end
	end

	-- Average alignment
	if count_alignment > 0 then
		alignment_x = (alignment_x / count_alignment) - entity.velocity.x
		alignment_y = (alignment_y / count_alignment) - entity.velocity.y

		-- Normalize alignment
		local mag = math.sqrt(alignment_x * alignment_x + alignment_y * alignment_y)
		if mag > 0 then
			alignment_x = (alignment_x / mag) * boid.max_force
			alignment_y = (alignment_y / mag) * boid.max_force
		end
	end

	-- Average cohesion
	if count_cohesion > 0 then
		cohesion_x = (cohesion_x / count_cohesion) - entity.transform.position_x
		cohesion_y = (cohesion_y / count_cohesion) - entity.transform.position_y

		-- Normalize cohesion
		local mag = math.sqrt(cohesion_x * cohesion_x + cohesion_y * cohesion_y)
		if mag > 0 then
			cohesion_x = (cohesion_x / mag) * boid.max_force
			cohesion_y = (cohesion_y / mag) * boid.max_force
		end
	end

	-- Normalize separation
	local mag = math.sqrt(separation_x * separation_x + separation_y * separation_y)
	if mag > 0 then
		separation_x = (separation_x / mag) * boid.max_force
		separation_y = (separation_y / mag) * boid.max_force
	end

	-- Apply weights
	local force_x = (separation_x * boid.separation_weight) + (alignment_x * boid.alignment_weight) + (cohesion_x * boid.cohesion_weight)
	local force_y = (separation_y * boid.separation_weight) + (alignment_y * boid.alignment_weight) + (cohesion_y * boid.cohesion_weight)

	-- Limit force
	local force_mag_sq = force_x * force_x + force_y * force_y
	if force_mag_sq > boid.max_force * boid.max_force then
		local scale = boid.max_force / math.sqrt(force_mag_sq)
		force_x = force_x * scale
		force_y = force_y * scale
	end

	return force_x, force_y
end

return M
