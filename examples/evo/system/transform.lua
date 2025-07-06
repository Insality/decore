local evolved = require("decore.evolved")
local components = require("decore.components")

---@class components
---@field position_x evolved.id
---@field position_y evolved.id
---@field position_z evolved.id
---@field position evolved.id
---@field scale evolved.id
---@field scale_x evolved.id
---@field scale_y evolved.id
---@field scale_z evolved.id
---@field rotation evolved.id
---@field quat evolved.id
---@field size_x evolved.id
---@field size_y evolved.id
---@field size_z evolved.id
---@field size evolved.id
---@field transform evolved.id
---@field position_dirty evolved.id
---@field scale_dirty evolved.id
---@field rotation_dirty evolved.id
---@field size_dirty evolved.id

components.position_x = evolved.builder():name("position_x"):default(0):spawn()
components.position_y = evolved.builder():name("position_y"):default(0):spawn()
components.position_z = evolved.builder():name("position_z"):default(0):spawn()
components.position = evolved.builder():name("position"):require(components.position_x, components.position_y, components.position_z):default(vmath.vector3(0, 0, 0)):duplicate(function(value)
	return vmath.vector3(value)
end):spawn()
components.scale_x = evolved.builder():name("scale_x"):default(1):spawn()
components.scale_y = evolved.builder():name("scale_y"):default(1):spawn()
components.scale_z = evolved.builder():name("scale_z"):default(1):spawn()
components.scale = evolved.builder():name("scale"):tag():require(components.scale_x, components.scale_y, components.scale_z):spawn()
components.rotation = evolved.builder():name("rotation"):default(0):spawn()
components.quat = evolved.builder():name("quat"):default(vmath.quat(0, 0, 0, 1)):duplicate(function(value)
	return vmath.quat(value)
end):spawn()
components.size_x = evolved.builder():name("size_x"):default(1):spawn()
components.size_y = evolved.builder():name("size_y"):default(1):spawn()
components.size_z = evolved.builder():name("size_z"):default(1):spawn()
components.size = evolved.builder():name("size"):tag():require(components.size_x, components.size_y, components.size_z):spawn()

components.position_dirty = evolved.builder():name("position_dirty"):tag():spawn()
components.scale_dirty = evolved.builder():name("scale_dirty"):tag():spawn()
components.size_dirty = evolved.builder():name("size_dirty"):tag():spawn()
components.rotation_dirty = evolved.builder():name("rotation_dirty"):tag():spawn()

components.transform = evolved.builder():name("transform"):tag():require(components.position, components.scale, components.rotation, components.size, components.quat):spawn()

return evolved.builder()
	:include(components.position_dirty)
	:execute(function(chunk, entity_list, entity_count)
		local position_x = chunk:components(components.position_x)
		local position_y = chunk:components(components.position_y)
		local position_z = chunk:components(components.position_z)
		local position = chunk:components(components.position)
		for index = 1, entity_count do
			local pos = position[index]
			pos.x = position_x[index]
			pos.y = position_y[index]
			pos.z = position_z[index]
		end
	end)
	:spawn()
