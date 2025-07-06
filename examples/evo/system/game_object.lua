local evolved = require("decore.evolved")
local components = require("decore.components")

---@class components
---@field factory_url evolved.id
---@field collection_factory_url evolved.id
---@field root_url evolved.id
---@field objects evolved.id
---@field game_object evolved.id

local go_setter = go_position_setter.new()

components.factory_url = evolved.builder():name("factory_url"):on_set(function(entity, fragment, component)
	local pos_x = evolved.get(entity, components.position_x)
	local pos_y = evolved.get(entity, components.position_y)
	local pos_z = evolved.get(entity, components.position_z)
	local pos = vmath.vector3(pos_x, pos_y, pos_z)
	local rot = evolved.get(entity, components.rotation)
	local quat = nil
	if rot ~= 0 then
		quat = vmath.quat(0, 0, math.sin(math.rad(rot) * 0.5), math.cos(math.rad(rot) * 0.5))
	end
	local scale_x = evolved.get(entity, components.scale_x)

	local object = factory.create(component, pos, quat, nil, scale_x)
	evolved.set(entity, components.root_url, object)

	go_setter:add(object, evolved.get(entity, components.position), evolved.get(entity, components.quat))
end):spawn()

components.collection_factory_url = evolved.builder():name("collection_factory_url"):default(""):spawn()
components.root_url = evolved.builder():name("root_url"):on_remove(function(entity, fragment, component)
	go_setter:remove(component)
	go.delete(component)
end):spawn()
components.objects = evolved.builder():name("objects"):spawn()

local game_object_group = evolved.id()

evolved.builder()
	:name("system.sync_position")
	:group(game_object_group)
	:execute(function()
		go_setter:update()
	end)
	:spawn()

return game_object_group

