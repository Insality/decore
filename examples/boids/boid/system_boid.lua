local decore = require("decore.decore")

---@class entity
---@field boid component.boid|nil

---@class entity.boid: entity
---@field boid component.boid

---@class component.boid
---@field separation_radius number
---@field alignment_radius number
---@field cohesion_radius number
---@field neighbors table
decore.register_component("boid", {
	speed = 100,
	separation_radius = 0,
	alignment_radius = 0,
	cohesion_radius = 0,
	neighbors = {}
})

---@class system.boid: system
---@field entities entity.boid[]
local M = {}



---@return system.boid
function M.create_system()
	return decore.system(M, "boid", { "boid", "transform", "velocity" })
end



function M:onAddToWorld()
	--self.world.command_boid = command_boid.create(self)
end



function M:update(dt)
	for _, entity in ipairs(self.entities) do
		self:process(entity, dt)
	end
end



function M:process(entity, dt)
	self:update_neighbors(entity)
	local force_x, force_y = self:calculate_forces(entity)

	-- Apply force to velocity
	local vx = force_x * entity.boid.speed * dt
	local vy = force_y * entity.boid.speed * dt
	self.world.command_velocity:add_velocity(entity, vx, vy)
end



function M:update_neighbors(entity)
	local boid = entity.boid
	local transform = entity.transform
	local neighbors = {}
	local pos_x, pos_y = transform.position_x, transform.position_y
	local max_radius = math.max(boid.separation_radius, boid.alignment_radius, boid.cohesion_radius)
	local max_radius_sq = max_radius * max_radius

	for index = 1, #self.entities do
		local other = self.entities[index]
		if other ~= entity then
			local dx = other.transform.position_x - pos_x
			local dy = other.transform.position_y - pos_y
			local dist_sq = dx * dx + dy * dy

			if dist_sq < max_radius_sq then
				table.insert(neighbors, { entity = other, dx = dx, dy = dy, dist_sq = dist_sq })
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

	for _, neighbor in ipairs(boid.neighbors) do
		local dist_sq = neighbor.dist_sq

		-- Separation
		if dist_sq < boid.separation_radius * boid.separation_radius then
			local dist = math.sqrt(dist_sq)
			local force = (boid.separation_radius - dist) / boid.separation_radius
			separation_x = separation_x - neighbor.dx / dist * force
			separation_y = separation_y - neighbor.dy / dist * force
		end

		-- Alignment
		if dist_sq < boid.alignment_radius * boid.alignment_radius then
			alignment_x = alignment_x + neighbor.entity.velocity.x
			alignment_y = alignment_y + neighbor.entity.velocity.y
			count_alignment = count_alignment + 1
		end

		-- Cohesion
		if dist_sq < boid.cohesion_radius * boid.cohesion_radius then
			cohesion_x = cohesion_x + neighbor.entity.transform.position_x
			cohesion_y = cohesion_y + neighbor.entity.transform.position_y
			count_cohesion = count_cohesion + 1
		end
	end

	-- Average alignment
	if count_alignment > 0 then
		alignment_x = (alignment_x / count_alignment) - entity.velocity.x
		alignment_y = (alignment_y / count_alignment) - entity.velocity.y
	end

	-- Average cohesion
	if count_cohesion > 0 then
		cohesion_x = (cohesion_x / count_cohesion) - entity.transform.position_x
		cohesion_y = (cohesion_y / count_cohesion) - entity.transform.position_y
	end

	-- Combine forces
	local force_x = separation_x + alignment_x + cohesion_x
	local force_y = separation_y + alignment_y + cohesion_y

	return force_x, force_y
end



return M
