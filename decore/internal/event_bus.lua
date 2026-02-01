-- Special key for events without entity
local NO_ENTITY_KEY = "system"

---@class decore.event_bus
---@field events table<string, any[]> The list of events group by event name. Array part of entities map is the order of entities event's triggers
---@field events_by_entity table<string, table<entity, any[]>> Maps event_name -> entity -> array of events for fast lookup
---@field stash table<string, any[]> Events to be processed in PostWrap
---@field stash_by_entity table<string, table<entity, any[]>> Maps event_name -> entity -> array of events for stash (fast lookup)
---@field merge_callbacks table<string, fun(new_event: any, events: any[], entity_map: table<entity, any[]>):boolean> The merge policy for events. If the merge policy returns true, the events are merged and not will be added as new event
local M = {}

---Creates a new event bus.
---@return decore.event_bus
function M.create()
	local instance = {
		events = {},
		events_by_entity = {},
		stash = {},
		stash_by_entity = {},
		merge_callbacks = {},
	}

	return setmetatable(instance, { __index = M })
end


---Pushes an event onto the queue, triggering it and processing the queue of callbacks.
---@param event_name string|hash The name of the event to push onto the queue.
---@param data any The data to pass to the event and its associated callbacks.
function M:trigger(event_name, data)
	self.stash[event_name] = self.stash[event_name] or {}
	self.stash_by_entity[event_name] = self.stash_by_entity[event_name] or {}
	local stash = self.stash[event_name]
	local stash_by_entity = self.stash_by_entity[event_name]

	local merge_callback = self.merge_callbacks[event_name]
	local entity = data and type(data) == "table" and data.entity
	local is_merged = false

	if merge_callback then
		is_merged = merge_callback(data, stash, stash_by_entity)
	end

	if not is_merged then
		local event_data = data or true
		table.insert(stash, event_data)
		local entity_key = entity or NO_ENTITY_KEY
		stash_by_entity[entity_key] = stash_by_entity[entity_key] or {}
		table.insert(stash_by_entity[entity_key], event_data)
	end
end


---Processes a specified event, returning the list of events and optionally calling callback with the full list.
---@param event_name hash|string The name of the event to process.
---@param callback fun(events: any[])|fun(context: any, events: any[])|nil Optional callback function to execute with the full list of events.
---@param context any|nil Optional context to pass as first argument to callback.
---@return any[]|nil events The list of events, or nil if no events found.
function M:process(event_name, callback, context)
	local events = self.events[event_name]
	if not events or #events == 0 then
		return nil
	end

	if callback then
		if context then
			callback(context, events)
		else
			callback(events)
		end
	end

	return events
end


---You can set the merge policy for an event. This is useful when you want to merge events of the same type.
---@param event_name string The name of the event to set the merge policy for.
---@param merge_callback (fun(new_event: any, events: any[], entity_map: table<entity, any[]>):boolean)|nil The callback function to merge the events. Return true if the events were merged, false otherwise.
function M:set_merge_policy(event_name, merge_callback)
	self.merge_callbacks[event_name] = merge_callback
end


function M:clear_events()
	self.events = {}
	self.events_by_entity = {}
end


function M:stash_to_events()
	self.events = self.stash
	self.stash = {}

	self.events_by_entity = self.stash_by_entity
	self.stash_by_entity = {}
end


function M:get_events(event_name)
	return self.events[event_name]
end


---@param event_name hash|string
---@return table[]|nil
function M:get_stash(event_name)
	return self.stash[event_name]
end


return M
