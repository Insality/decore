local ecs = require("decore.internal.ecs")
local decore_userdata = require("decore.internal.decore_userdata")

local TYPE_TABLE = "table"
local TYPE_USERDATA = "userdata"

local M = {}


---Clamp value between min and max (either can be nil)
---@param value number
---@param v1 number
---@param v2 number
---@return number
function M.clamp(value, v1, v2)
	v1 = v1 or -math.huge
	v2 = v2 or math.huge
	if v1 > v2 then
		v1, v2 = v2, v1
	end

	return math.max(v1, math.min(value, v2))
end


---Create a copy of lua table. Preserves internal aliases (same table referenced twice)
---and is safe on cyclic structures.
---The copies map is a recursion accumulator built here: callers pass nothing.
---@param value_to_copy any
---@param copies table<table, table>|nil internal: source table -> its copy
---@return any
function M.deepcopy(value_to_copy, copies)
	if type(value_to_copy) ~= TYPE_TABLE then
		return value_to_copy
	end

	copies = copies or {}
	local existing = copies[value_to_copy]
	if existing then
		return existing
	end

	local copy = {}
	copies[value_to_copy] = copy

	for key, value in next, value_to_copy, nil do
		local value_type = type(value)
		if value_type == TYPE_TABLE then
			value = M.deepcopy(value, copies)
		elseif value_type == TYPE_USERDATA then
			value = decore_userdata.copy(value)
		end
		-- Keys stay as they are: a hash key must keep its identity
		if type(key) == TYPE_TABLE then
			key = M.deepcopy(key, copies)
		end
		copy[key] = value
	end

	local mt = getmetatable(value_to_copy)
	if mt then
		setmetatable(copy, mt)
	end

	return copy
end


---Check if value is an object: a table with a metatable (event, promise, ...).
---Objects are copied as a whole instead of being merged field-wise.
---@param value any
---@return boolean
function M.is_object(value)
	return type(value) == TYPE_TABLE and getmetatable(value) ~= nil
end


---Copy table without touching nested values: they stay by reference.
---@param source table
---@return table
local function copy_shallow(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end


--- Merge one table into another recursively.
--- Nested plain tables are kept by reference when the key is missing in t1.
--- Nested tables that already exist in t1 can be shared with a prefab template,
--- so they are copied before being written into (copy-on-write).
--- Objects (tables with a metatable) replace the value and are deepcopied.
---@param t1 table
---@param t2 table
function M.merge_tables(t1, t2)
	for key, value in pairs(t2) do
		if type(value) == TYPE_TABLE then
			if getmetatable(value) then
				t1[key] = M.deepcopy(value)
			else
				local target = t1[key]
				if type(target) ~= TYPE_TABLE then
					-- Nothing to merge into: share the nested plain table by reference
					t1[key] = value
				else
					-- Target can be shared with a prefab template or with other
					-- instances, so it has to be owned before being written into
					target = copy_shallow(target)
					t1[key] = target
					M.merge_tables(target, value)
				end
			end
		else
			t1[key] = value
		end
	end
end


---Write component data into target[component_id]: plain tables are merged,
---scalars are set as is, objects replace the whole value.
---@param target table entity or prefab template
---@param component_id string
---@param component_data any
---@param is_prototype boolean copy objects instead of taking them by reference
local function assign_component(target, component_id, component_data, is_prototype)
	if type(component_data) ~= TYPE_TABLE then
		target[component_id] = component_data
		return
	end

	-- Objects (event, promise, ...) are never merged field-wise: that would share
	-- their inner state tables between entities
	if getmetatable(component_data) then
		target[component_id] = is_prototype and M.deepcopy(component_data) or component_data
		return
	end

	-- A component default can be a scalar (false, number, ...) with nothing to merge into
	if type(target[component_id]) ~= TYPE_TABLE then
		target[component_id] = {}
	end

	M.merge_tables(target[component_id], component_data)
end


---Write a value handed over by the caller into target[component_id].
---Objects are taken as is: the caller still holds the object and may have already
---subscribed to it, so a copy would silently break those subscriptions.
---@param target table entity or prefab template
---@param component_id string
---@param component_data any
function M.assign_component_value(target, component_id, component_data)
	assign_component(target, component_id, component_data, false)
end


---Write prototype data (component registry, prefab data) into target[component_id].
---Objects are deepcopied so instances never share the prototype state.
---@param target table entity or prefab template
---@param component_id string
---@param component_data any
function M.assign_component_prototype(target, component_id, component_data)
	assign_component(target, component_id, component_data, true)
end


---Clone entity/template for spawn: own top-level component tables, nested plain tables by reference.
---Objects (tables with a metatable) and mutable Defold userdata are copied so that their
---state is never shared between entities.
---@param template table
---@return table
function M.instantiate_template(template)
	local entity = {}

	for key, value in pairs(template) do
		local value_type = type(value)
		if value_type == TYPE_TABLE then
			if getmetatable(value) then
				entity[key] = M.deepcopy(value)
			else
				local component = {}
				for component_key, component_value in pairs(value) do
					local component_type = type(component_value)
					if component_type == TYPE_TABLE and getmetatable(component_value) then
						component_value = M.deepcopy(component_value)
					elseif component_type == TYPE_USERDATA then
						component_value = decore_userdata.copy(component_value)
					end
					component[component_key] = component_value
				end
				entity[key] = component
			end
		elseif value_type == TYPE_USERDATA then
			entity[key] = decore_userdata.copy(value)
		else
			entity[key] = value
		end
	end

	return entity
end


---Remove the value from the array table by value
---@param t table
---@param v any
---@return boolean true if value was removed
function M.remove_by_value(t, v)
	for index = 1, #t do
		if t[index] == v then
			table.remove(t, index)
			return true
		end
	end

	return false
end


---@generic T
---@param ecs_system system
---@param system_module T
---@param system_id string
---@param require_all_filters string|string[]|nil
---@return T
function M.create_system(ecs_system, system_module, system_id, require_all_filters)
	local system = setmetatable(ecs_system, { __index = system_module })
	system.id = system_id

	-- Filters must be presence-only (component key exists). Value-based filters
	-- break the prefab shape -> system-list cache in ecs.lua.
	if require_all_filters then
		if type(require_all_filters) == TYPE_TABLE then
			---@cast require_all_filters string[]
			system.filter = ecs.requireAll(unpack(require_all_filters))
		else
			system.filter = ecs.requireAll(require_all_filters)
		end
	end

	return system
end


return M
