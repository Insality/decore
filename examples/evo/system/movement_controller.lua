local events = require("event.events")
local evolved = require("decore.evolved")
local components = require("decore.components")

---@class components
---@field movement_controller evolved.id

components.movement_controller = evolved.builder():name("movement_controller"):default(0):spawn()

local ACTION_ID_TO_SIDE = {
	[hash("key_w")] = { y = 1, id = "up" },
	[hash("key_s")] = { y = -1, id = "down" },
	[hash("key_a")] = { x = -1, id = "left" },
	[hash("key_d")] = { x = 1, id = "right" },
	[hash("key_up")] = { y = 1, id = "up" },
	[hash("key_down")] = { y = -1, id = "down" },
	[hash("key_left")] = { x = -1, id = "left" },
	[hash("key_right")] = { x = 1, id = "right" },
}

local input_keys = {}
local direction_x = 0
local direction_y = 0

events.subscribe("input_event", function(action_id, action)
	local side = ACTION_ID_TO_SIDE[action_id]
	if side then
		if action.pressed then
			input_keys[side.id] = true
		end
		if action.released then
			input_keys[side.id] = nil
		end

		do -- direction_x
			direction_x = 0
			if input_keys["left"] then
				direction_x = direction_x - 1
			end
			if input_keys["right"] then
				direction_x = direction_x + 1
			end
		end

		do -- direction_y
			direction_y = 0
			if input_keys["up"] then
				direction_y = direction_y + 1
			end
			if input_keys["down"] then
				direction_y = direction_y - 1
			end
		end
	end
end)

local query = evolved.builder()
	:include(components.velocity_x, components.velocity_y)
	:include(components.movement_controller)
	:spawn()

return evolved.builder()
	:query(query)
	:execute(function(chunk, entity_list, entity_count)
		local movement_controller = chunk:components(components.movement_controller)
		local velocity_x = chunk:components(components.velocity_x)
		local velocity_y = chunk:components(components.velocity_y)

		--evolved.batch_set(query, components.velocity_x, direction_x * 250)
		--evolved.batch_set(query, components.velocity_y, direction_y * 250)

		for index = 1, entity_count do
			local speed = movement_controller[index]
			evolved.set(entity_list[index], components.velocity_x, direction_x * speed)
			evolved.set(entity_list[index], components.velocity_y, direction_y * speed)
		end
	end)
	:spawn()
