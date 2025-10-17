local ecs = require("decore.internal.ecs")

local TYPE_STRING = "string"
local TYPE_TABLE = "table"

local M = {}

---Logger interface
---@class decore.logger
---@field trace fun(logger: decore.logger, message: string, data: any|nil)
---@field debug fun(logger: decore.logger, message: string, data: any|nil)
---@field info fun(logger: decore.logger, message: string, data: any|nil)
---@field warn fun(logger: decore.logger, message: string, data: any|nil)
---@field error fun(logger: decore.logger, message: string, data: any|nil)

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

---@type decore.logger
M.empty_logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}

---@type decore.logger
M.logger = {
	trace = function(_, msg) print("TRACE: " .. msg) end,
	debug = function(_, msg, data) print("DEBUG: " .. msg, data) end,
	info = function(_, msg, data) print("INFO: " .. msg, data) end,
	warn = function(_, msg, data) print("WARN: " .. msg, data) end,
	error = function(_, msg, data) print(data) error("ERROR: " .. msg) end
}


---Split string by separator
---@param s string
---@param sep string
function M.split(s, sep)
	sep = sep or "%s"
	local t = {}
	local i = 1
	for str in string.gmatch(s, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


---Split string by separator
---@param s string
---@param sep string[]
function M.split_by_several_separators(s, sep)
	local t = {}
	local pattern = table.concat(sep, "|")
	for str in string.gmatch(s, "([^" .. pattern .. "]+)") do
		table.insert(t, str)
	end
	return t
end


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


---Create a copy of lua table
---@param value_to_copy any
---@return any
function M.deepcopy(value_to_copy)
	local orig_type = type(value_to_copy)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, value_to_copy, nil do
			copy[M.deepcopy(orig_key)] = M.deepcopy(orig_value)
		end

		local mt = getmetatable(value_to_copy)
		if mt then
			setmetatable(copy, mt)
		end
	else -- number, string, boolean, etc
		copy = value_to_copy
	end

	return copy
end


--- Merge one table into another recursively
---@param t1 table
---@param t2 table
function M.merge_tables(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == TYPE_TABLE then
			-- If value has metatable, deep copy it (like event objects)
			if getmetatable(v) then
				t1[k] = M.deepcopy(v)
			elseif not t1[k] then
				-- No metatable, create new table and merge recursively
				t1[k] = v
			else
				-- Merge into existing table
				M.merge_tables(t1[k], v)
			end
		else
			t1[k] = v
		end
	end
end


---Remove the value from the array table by value
---@param t table
---@param v any
---@return boolean @true if value was removed
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
