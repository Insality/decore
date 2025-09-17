---@class decore.event_bus
---@field events table<string, table[]> The list of events group by event name. Array part of entities map is the order of entities event's triggers
---@field stash table<string, table[]> Events to be processed in PostWrap
---@field merge_callbacks table<string, fun(events: any[], new_event: any):boolean> The merge policy for events. If the merge policy returns true, the events are merged and not will be added as new event
local M = {}

local tinsert = table.insert

---Creates a new event bus.
---@return decore.event_bus
function M.create()
	local instance = {
		events = {},
		stash = {},
		merge_callbacks = {},
	}

	return setmetatable(instance, { __index = M })
end


---Pushes an event onto the queue, triggering it and processing the queue of callbacks.
---@param event_name string|hash The name of the event to push onto the queue.
---@param data any The data to pass to the event and its associated callbacks.
function M:trigger(event_name, data)
	self.stash[event_name] = self.stash[event_name] or {}
	local stash = self.stash[event_name]

	local merge_callback = self.merge_callbacks[event_name]
	local is_merged = merge_callback and merge_callback(data, stash)
	if not is_merged then
		tinsert(stash, data or true)
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

	if context then
		for i = 1, #events do
			callback(context, events[i])
		end
	else
		for i = 1, #events do
			callback(events[i])
		end
	end
end


---You can set the merge policy for an event. This is useful when you want to merge events of the same type.
---@param event_name string The name of the event to set the merge policy for.
---@param merge_callback (fun(events: any[], new_event: any):boolean)|nil The callback function to merge the events. Return true if the events were merged, false otherwise.
function M:set_merge_policy(event_name, merge_callback)
	self.merge_callbacks[event_name] = merge_callback
end


function M:clear_events()
	self.events = {}
end


function M:stash_to_events()
	self.events = self.stash
	self.stash = {}
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
