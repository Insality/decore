-- Event queue for the world.
--
-- trigger(event_id, entity?, data?)
--   entity and data are optional. Prefer:
--     bus:trigger("died", entity)             -- no alloc
--     bus:trigger("wave_start")               -- no alloc
--     bus:trigger("hit", entity, { dmg = 3 }) -- alloc only for data
--
-- process(event_id, callback, context?)
--   callback(entity, data) or callback(context, entity, data)
--   data is nil when the trigger had no payload

-- Unique sentinels for array slots (Lua arrays cannot store nil).
-- Empty tables so they never collide with real entity/data values.
local NO_ENTITY = {}
local NO_DATA = {}

---@class decore.event_bus
---@field events table<string|hash, any[]> Ordered payloads for the current frame
---@field event_entities table<string|hash, any[]> Parallel entity list (NO_ENTITY = no entity)
---@field events_by_entity table<string|hash, table<entity|string, any[]>> event_id -> entity -> payloads
---@field stash table<string|hash, any[]>
---@field stash_entities table<string|hash, any[]>
---@field stash_by_entity table<string|hash, table<entity|string, any[]>>
---@field merge_callbacks table<string|hash, fun(entity: entity|nil, data: any, datas: any[], entity_map: table): boolean>
local M = {}


---Creates a new event bus.
---@return decore.event_bus
function M.create()
	local instance = {
		events = {},
		event_entities = {},
		events_by_entity = {},
		stash = {},
		stash_entities = {},
		stash_by_entity = {},
		merge_callbacks = {},
	}

	return setmetatable(instance, { __index = M })
end


---@param self decore.event_bus
---@param event_name string|hash
---@return any[], any[], table
function M.get_or_create_stash(self, event_name)
	local datas = self.stash[event_name]
	if datas then
		return datas, self.stash_entities[event_name], self.stash_by_entity[event_name]
	end

	datas = {}
	local entities = {}
	local by_entity = {}
	self.stash[event_name] = datas
	self.stash_entities[event_name] = entities
	self.stash_by_entity[event_name] = by_entity
	return datas, entities, by_entity
end


---@param data any
---@return any|nil
function M.decode_data(data)
	if data == NO_DATA then
		return nil
	end
	return data
end


---@param entity_slot any
---@return entity|nil
function M.decode_entity(entity_slot)
	if entity_slot == NO_ENTITY then
		return nil
	end
	return entity_slot
end


---Queue an event. Entity and data are optional.
---@param event_name string|hash
---@param entity entity|nil
---@param data any|nil
function M:trigger(event_name, entity, data)
	local datas, entities, by_entity = M.get_or_create_stash(self, event_name)
	local payload = data
	if payload == nil then
		payload = NO_DATA
	end

	local merge_callback = self.merge_callbacks[event_name]
	if merge_callback and merge_callback(entity, payload == NO_DATA and nil or payload, datas, by_entity) then
		return
	end

	local index = #datas + 1
	datas[index] = payload
	entities[index] = entity or NO_ENTITY

	local entity_key = entity or "system"
	local entity_datas = by_entity[entity_key]
	if not entity_datas then
		entity_datas = {}
		by_entity[entity_key] = entity_datas
	end
	entity_datas[#entity_datas + 1] = payload
end


---Invoke callback once per event: callback(entity, data) or callback(context, entity, data).
---@param event_name hash|string
---@param callback fun(entity: entity|nil, data: any)|fun(context: any, entity: entity|nil, data: any)|nil
---@param context any|nil
---@return any[]|nil datas
---@return any[]|nil entities
function M:process(event_name, callback, context)
	local datas = self.events[event_name]
	if not datas or #datas == 0 then
		return nil
	end

	local entities = self.event_entities[event_name]
	if callback then
		if context then
			for index = 1, #datas do
				callback(context, M.decode_entity(entities[index]), M.decode_data(datas[index]))
			end
		else
			for index = 1, #datas do
				callback(M.decode_entity(entities[index]), M.decode_data(datas[index]))
			end
		end
	end

	return datas, entities
end


---Merge policy: return true if the new event was merged into an existing one.
---`entity_map[entity]` (or entity_map["system"]) is the list of payloads for that entity.
---@param event_name string|hash
---@param merge_callback (fun(entity: entity|nil, data: any, datas: any[], entity_map: table): boolean)|nil
function M:set_merge_policy(event_name, merge_callback)
	self.merge_callbacks[event_name] = merge_callback
end


function M:clear_events()
	self.events = {}
	self.event_entities = {}
	self.events_by_entity = {}
end


function M:stash_to_events()
	self.events = self.stash
	self.event_entities = self.stash_entities
	self.events_by_entity = self.stash_by_entity

	self.stash = {}
	self.stash_entities = {}
	self.stash_by_entity = {}
end


---@param event_name hash|string
---@return any[]|nil
function M:get_events(event_name)
	return self.events[event_name]
end


---@param event_name hash|string
---@return any[]|nil
function M:get_event_entities(event_name)
	return self.event_entities[event_name]
end


---@param event_name hash|string
---@return any[]|nil
function M:get_stash(event_name)
	return self.stash[event_name]
end


---@param event_name hash|string
---@return any[]|nil
function M:get_stash_entities(event_name)
	return self.stash_entities[event_name]
end


M.NO_DATA = NO_DATA
M.NO_ENTITY = NO_ENTITY


return M

