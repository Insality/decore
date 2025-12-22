local ecs = require("decore.internal.ecs")

local TYPE_TABLE = "table"

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


---Create a copy of lua table
---@param value_to_copy any
---@return any
function M.deepcopy(value_to_copy)
	local orig_type = type(value_to_copy)
	local copy
	if orig_type == "table" then
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
