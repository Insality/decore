---@class decore.event_bus
---@field events table<string, table> The current list of events
---@field stash_by_entity table<string, table<entity, table[]>> The list of entities group by event name. Array part of entities map is the order of entities event's triggers
---@field merge_callbacks table<string, fun(events: any[], new_event: any):boolean> The merge policy for events. If the merge policy returns true, the events are merged and not will be added as new event
local M = {}

local NO_ENTITY_KEY = {}

local tinsert = table.insert

---Creates a new event bus.
---@return decore.event_bus
function M.create()
	local instance = {
		events = {},
		stash_by_entity = {},
		merge_callbacks = {},
	}

	return setmetatable(instance, { __index = M })
end


---Pushes an event onto the queue, triggering it and processing the queue of callbacks.
---@param event_name string|hash The name of the event to push onto the queue.
---@param entity entity|nil The entity that triggered the event. This used for optimization and batching events.
---@param data any The data to pass to the event and its associated callbacks.
function M:trigger(event_name, entity, data)
	local entity_key = entity or NO_ENTITY_KEY

	self.stash_by_entity[event_name] = self.stash_by_entity[event_name] or {}
	-- If not entity's events, add a array and save their order in array part
	if not self.stash_by_entity[event_name][entity_key] then
		self.stash_by_entity[event_name][entity_key] = {}
		tinsert(self.stash_by_entity[event_name], entity_key)
	end

	local entity_events = self.stash_by_entity[event_name][entity_key]
	local merge_callback = self.merge_callbacks[event_name]

	local is_merged = merge_callback and merge_callback(data, entity_events, entity, self.stash_by_entity)
	if not is_merged then
		tinsert(entity_events, data or true)
	end
end


---Processes a specified event, executing the callback function with the provided context.
---@param event_name hash|string The name of the event to process.
---@param callback fun(...) The callback function to execute.
---@param context any|nil The context in which to execute the callback.
function M:process(event_name, callback, context)
	local events = self.events[event_name]
	if not events then
		return
	end

	for event_index = 1, #events do
		local entity = events[event_index]
		local entity_events = events[entity]

		if context then
			for index = 1, #entity_events do
				callback(context, entity_events[index], entity)
			end
		else
			for index = 1, #entity_events do
				callback(entity_events[index], entity)
			end
		end
	end
end


---You can set the merge policy for an event. This is useful when you want to merge events of the same type.
---@param event_name string The name of the event to set the merge policy for.
---@param merge_callback (fun(new_event: any?, entity_events: any[], entity: entity, all_events: table<entity, table[]>):boolean)|nil The callback function to merge the events. Return true if the events were merged, false otherwise.
function M:set_merge_policy(event_name, merge_callback)
	self.merge_callbacks[event_name] = merge_callback
end


function M:clear_events()
	self.events = {}
end


function M:stash_to_events()
	self.events = self.stash_by_entity
	self.stash_by_entity = {}
end


function M:get_events(event_name)
	return self.events[event_name]
end


function M:get_stash(event_name)
	return self.stash_by_entity[event_name]
end


local global_queue = M.create()
return global_queue
