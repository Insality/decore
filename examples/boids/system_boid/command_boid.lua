---@class world
---@field command_boid command.boid

---@class command.boid
---@field boid system.boid
local M = {}


---@return command.boid
function M.create(boid)
	return setmetatable({ boid = boid }, { __index = M })
end

function M:set_visual_range(value)
	for index = 1, #self.boid.entities do
		local entity = self.boid.entities[index]
		entity.boid.visual_range = value
	end
end

function M:set_protected_range(value)
	for index = 1, #self.boid.entities do
		local entity = self.boid.entities[index]
		entity.boid.protected_range = value
	end
end

function M:set_centering_factor(value)
	for index = 1, #self.boid.entities do
		local entity = self.boid.entities[index]
		entity.boid.centering_factor = value
	end
end

function M:set_avoid_factor(value)
	for index = 1, #self.boid.entities do
		local entity = self.boid.entities[index]
		entity.boid.avoid_factor = value
	end
end

function M:set_matching_factor(value)
	for index = 1, #self.boid.entities do
		local entity = self.boid.entities[index]
		entity.boid.matching_factor = value
	end
end

return M
