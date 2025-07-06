local evolved = require("decore.evolved")
local components = require("decore.components")

---@class components
---@field velocity_x evolved.id
---@field velocity_y evolved.id
---@field velocity_z evolved.id
---@field velocity evolved.id

components.velocity_x = evolved.builder():name("velocity_x"):default(0):spawn()
components.velocity_y = evolved.builder():name("velocity_y"):default(0):spawn()
components.velocity_z = evolved.builder():name("velocity_z"):default(0):spawn()
components.velocity = evolved.builder():name("velocity"):tag():require(components.velocity_x, components.velocity_y):spawn()

return evolved.builder()
	:include(components.velocity_x, components.velocity_y, components.position_x, components.position_y)
	:execute(function(chunk, entity_list, entity_count)
		local dt = evolved.get(components.dt, components.dt)
		local velocity_x = chunk:components(components.velocity_x)
		local velocity_y = chunk:components(components.velocity_y)
		local position_x = chunk:components(components.position_x)
		local position_y = chunk:components(components.position_y)
		for index = 1, entity_count do
			local vx = velocity_x[index] * dt
			local vy = velocity_y[index] * dt

			if vx ~= 0 or vy ~= 0 then
				evolved.set(entity_list[index], components.position_x, position_x[index] + vx)
				evolved.set(entity_list[index], components.position_y, position_y[index] + vy)
				evolved.set(entity_list[index], components.position_dirty)
			end
		end
	end)
	:spawn()
