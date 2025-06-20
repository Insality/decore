local evolved = require("decore.evolved")
local components = require("examples.evo.components")

---@class components
---@field factory_url evolved.id
---@field collection_factory_url evolved.id
---@field root_url evolved.id
---@field objects evolved.id
---@field game_object evolved.id

components.factory_url = evolved.builder():name("factory_url"):default(""):spawn()
components.collection_factory_url = evolved.builder():name("collection_factory_url"):default(""):spawn()
components.root_url = evolved.builder():name("root_url"):spawn()
components.objects = evolved.builder():name("objects"):spawn()

local game_object_group = evolved.id()

evolved.builder()
	:name("system.spawn_game_object")
	:group(game_object_group)
	:include(components.factory_url)
	:exclude(components.root_url)
	:execute(function(chunk, entity_list, entity_count)
		local urls = chunk:components(components.factory_url)
		local position_x = chunk:components(components.position_x)
		local position_y = chunk:components(components.position_y)
		local position_z = chunk:components(components.position_z)
		local rotation = chunk:components(components.rotation)
		local scale_x = chunk:components(components.scale_x)

		for index = 1, entity_count do
			local url = urls[index]
			local pos = vmath.vector3(position_x[index], position_y[index], position_z[index])
			local quat = nil
			local rot = rotation[index]
			if rot ~= 0 then
				quat = vmath.quat(0, 0, math.sin(math.rad(rot) * 0.5), math.cos(math.rad(rot) * 0.5))
			end
			local object = factory.create(url, pos, quat, nil, scale_x[index])
			evolved.set(entity_list[index], components.root_url, object)
		end
	end)
	:spawn()

local TEMP_VECTOR = vmath.vector3()
evolved.builder()
	:name("system.sync_position")
	:group(game_object_group)
	:include(components.root_url, components.position, components.position_dirty)
	:execute(function(chunk, entity_list, entity_count)
		local root_urls = chunk:components(components.root_url)
		local position_x = chunk:components(components.position_x)
		local position_y = chunk:components(components.position_y)
		local position_z = chunk:components(components.position_z)

		for index = 1, entity_count do
			local root_url = root_urls[index]
			TEMP_VECTOR.x = position_x[index]
			TEMP_VECTOR.y = position_y[index]
			TEMP_VECTOR.z = position_z[index]
			go.set_position(TEMP_VECTOR, root_url)
		end
	end)
	:spawn()

return game_object_group

