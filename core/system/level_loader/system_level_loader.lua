local decore = require("decore.decore")

local logger = decore.get_logger("system.level_loader")

local command_level_loader = require("core.system.level_loader.command_level_loader")

---@class system.level_loader: system
---@field entity_by_slot table<string, entity> @slot_id -> entity
local M = {}


---@static
---@return system.level_loader
function M.create_system()
	local system = decore.system(M, "level_loader")

	system.entity_by_slot = {}

	return system
end


function M:onAddToWorld()
	self.world.command_level_loader = command_level_loader.create(self)
end


function M:load_level(collection_url, slot_id)
	self:unload_level(slot_id)

	local entity = decore.create_entity(nil, nil, {
		transform = {},
		game_object = {
			factory_url = collection_url,
		}
	})
	self.world:addEntity(entity)
	self.entity_by_slot[slot_id] = entity
end


function M:unload_level(slot_id)
	if slot_id and self.entity_by_slot[slot_id] then
		self.world:removeEntity(self.entity_by_slot[slot_id])
		self.entity_by_slot[slot_id] = nil
	end
end


---@param world_id string
---@param pack_id string|nil
---@param offset_x number|nil
---@param offset_y number|nil
---@param slot_id string|nil
function M:load_world(world_id, pack_id, offset_x, offset_y, slot_id)
	logger:debug("load_world", { world_id = world_id,
		pack_id = pack_id,
		offset_x = offset_x,
		offset_y = offset_y,
		slot_id = slot_id
	})

	offset_x = offset_x or 0
	offset_y = offset_y or 0

	local entities = decore.create_world(world_id, pack_id)
	if not entities then
		logger:error("Failed to load world", world_id)
		return
	end

	-- Spawn new world
	for index = 1, #entities do
		local new_entity = entities[index]

		if new_entity.transform then
			new_entity.transform.position_x = new_entity.transform.position_x + offset_x
			new_entity.transform.position_y = new_entity.transform.position_y + offset_y
		end

		self.world:addEntity(new_entity)
	end
end


return M