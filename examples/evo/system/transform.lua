local evolved = require("decore.evolved")
local components = require("examples.evo.components")

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
components.position = evolved.builder():name("position"):tag():require(components.position_x, components.position_y, components.position_z):spawn()
components.scale_x = evolved.builder():name("scale_x"):default(1):spawn()
components.scale_y = evolved.builder():name("scale_y"):default(1):spawn()
components.scale_z = evolved.builder():name("scale_z"):default(1):spawn()
components.scale = evolved.builder():name("scale"):tag():require(components.scale_x, components.scale_y, components.scale_z):spawn()
components.rotation = evolved.builder():name("rotation"):default(0):spawn()
components.size_x = evolved.builder():name("size_x"):default(1):spawn()
components.size_y = evolved.builder():name("size_y"):default(1):spawn()
components.size_z = evolved.builder():name("size_z"):default(1):spawn()
components.size = evolved.builder():name("size"):tag():require(components.size_x, components.size_y, components.size_z):spawn()
components.size_dirty = evolved.builder():name("size_dirty"):tag():spawn()
components.position_dirty = evolved.builder():name("position_dirty"):tag():spawn()
components.scale_dirty = evolved.builder():name("scale_dirty"):tag():spawn()
components.rotation_dirty = evolved.builder():name("rotation_dirty"):tag():spawn()
components.transform = evolved.builder():name("transform"):tag():require(components.position, components.scale, components.rotation, components.size):spawn()

---@param chunk evolved.chunk
---@param entity_list evolved.entity[]
---@param entity_count number
local function update(chunk, entity_list, entity_count)
	local names = chunk:components(evolved.NAME)
	local pos_x = chunk:components(components.position_x)
	local pos_y = chunk:components(components.position_y)
	for index = 1, entity_count do
		--print(index, names[index], pos_x[index], pos_y[index])
	end
end

return evolved.builder()
	:include(components.transform)
	:execute(update)
	:spawn()
