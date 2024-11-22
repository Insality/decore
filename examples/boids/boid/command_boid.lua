---@class world
---@field command_boid command.boid

---@class command.boid
---@field boid system.boid
local M = {}


---@return command.boid
function M.create(boid)
	return setmetatable({ boid = boid }, { __index = M })
end


function M:set_speed(speed)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.speed = speed
	end
end


function M:set_separation_radius(radius)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.separation_radius = radius
	end
end


function M:set_alignment_radius(radius)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.alignment_radius = radius
	end
end


function M:set_cohesion_radius(radius)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.cohesion_radius = radius
	end
end


function M:set_max_speed(speed)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.max_speed = speed
	end
end


function M:set_max_force(force)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.max_force = force
	end
end


function M:set_separation_weight(weight)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.separation_weight = weight
	end
end


function M:set_alignment_weight(weight)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.alignment_weight = weight
	end
end


function M:set_cohesion_weight(weight)
	for _, entity in ipairs(self.boid.entities) do
		entity.boid.cohesion_weight = weight
	end
end


return M
