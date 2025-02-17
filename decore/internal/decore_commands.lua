local decore_internal = require("decore.internal.decore_internal")

local M = {}

---@param command string Example: "system_name.function_name, arg1, arg2". Separators are : " ", "," and "\n" only
---@return any[]
function M.parse_command(command)
	if type(command) ~= "string" then
		return command
	end

	-- Split the command string into a table. check numbers, remove newlines and spaces
	local command_table = decore_internal.split_by_several_separators(command, { " ", ",", "\n" })

	-- Trim the command table
	for i = 1, #command_table do
		command_table[i] = string.gsub(command_table[i], "%s+", "")
	end

	-- Checks types
	for i = 1, #command_table do
		-- Check number
		if tonumber(command_table[i]) then
			command_table[i] = tonumber(command_table[i])
		end
		-- Check boolean
		if command_table[i] == "true" then
			command_table[i] = true
		elseif command_table[i] == "false" then
			command_table[i] = false
		end
	end

	return command_table
end


---Call command from params array. Example: {"system_name", "function_name", "arg1", "arg2", ...}
---@param world world
---@param command any[] Example: [ "command_debug", "toggle_profiler", true ],
function M.call_command(world, command)
	if not command then
		decore_internal.logger:error("Command is nil")
		print(debug.traceback())
		return
	end

	local command_system = world[command[1]]
	if not command_system then
		decore_internal.logger:error("System not found", command[1])
		return
	end

	local func = command[2]
	if not command_system[func] then
		decore_internal.logger:error("Function not found", func)
		return
	end

	local args = {}
	for i = 3, #command do
		table.insert(args, command[i])
	end

	command_system[func](command_system, unpack(args))
end


return M
