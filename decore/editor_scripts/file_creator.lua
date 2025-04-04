local templates = require("decore.editor_scripts.templates")

local M = {}


---@param path string
---@param content string
local function write_file(path, content)
	-- Check if file already exists
	local exists = io.open(path, "r")
	if exists then
		exists:close()
		print("Warning: File already exists at " .. path .. ". Skipping creation.")
		return false
	end

	local file = io.open(path, "w")
	if not file then
		print("Error: Could not create file at", path)
		return false
	end
	file:write(content)
	file:close()
	print("Created file at", path)
	return true
end


---@param path string
---@param placeholder string
---@param insert_code string
local function insert_at_placeholder(path, placeholder, insert_code)
	local absolute_path = editor.external_file_attributes(".").path .. path

	-- Read the file
	local file = io.open(absolute_path, "r")
	if not file then
		print("Error: Could not read file at", absolute_path)
		return false
	end

	local content = file:read("*a")
	file:close()

	-- Find the placeholder and extract its indentation
	local lines = {}
	local indentation = ""
	local placeholder_found = false

	for line in content:gmatch("([^\n]*)\n?") do
		table.insert(lines, line)

		if line:find(placeholder, 1, true) then
			indentation = line:match("^(%s*)")
			placeholder_found = true
		end
	end

	if not placeholder_found then
		print("Warning: Placeholder '" .. placeholder .. "' not found in file", absolute_path)
		return false
	end

	-- Add indentation to the insert code
	local indented_code = indentation .. insert_code

	-- Create new content with the insert code before the placeholder
	local new_content = ""
	placeholder_found = false

	for i, line in ipairs(lines) do
		if not placeholder_found and line:find(placeholder, 1, true) then
			-- Add the new code before the placeholder
			new_content = new_content .. indented_code .. "\n" .. line .. "\n"
			placeholder_found = true
		else
			new_content = new_content .. line
			if i < #lines then
				new_content = new_content .. "\n"
			end
		end
	end

	-- Write the file
	file = io.open(absolute_path, "w")
	if not file then
		print("Error: Could not write file at", absolute_path)
		return false
	end

	file:write(new_content)
	file:close()
	print("Updated file at", absolute_path)
	return true
end


---@return table
local function load_game_project_config()
	local config = {}

	-- Directly get values from game.project using editor.get()
	config.assistant_systems_path = editor.get("/game.project", "decore.assistant_systems_path")
	config.assistant_entities_path = editor.get("/game.project", "decore.assistant_entities_path")
	config.assistant_tests_path = editor.get("/game.project", "decore.assistant_tests_path")
	config.assistant_spawner_path = editor.get("/game.project", "decore.assistant_spawner_path")

	-- Get placeholders
	config.assistant_systems_placeholder = editor.get("/game.project", "decore.assistant_systems_placeholder") or "{NEW_SYSTEMS_HERE}"
	config.assistant_entities_placeholder = editor.get("/game.project", "decore.assistant_entities_placeholder") or "{NEW_ENTITIES_HERE}"
	config.assistant_tests_placeholder = editor.get("/game.project", "decore.assistant_tests_placeholder") or "{NEW_TESTS_HERE}"

	return config
end


---@param name string
---@param options table
---@param folder_path string
function M.create_system_files(name, options, folder_path)
	local absolute_folder_path = editor.external_file_attributes(".").path .. folder_path

	-- Create system file
	local system_path = absolute_folder_path .. "system_" .. name:lower() .. ".lua"
	local system_template = templates.get_system_template(name, options)
	write_file(system_path, system_template)

	-- Create command file if needed
	if options.include_command then
		local command_path = absolute_folder_path .. "command_" .. name:lower() .. ".lua"
		local command_template = templates.get_command_template(name, options)
		write_file(command_path, command_template)
	end

	-- Register in the appropriate files if integration is enabled
	local config = load_game_project_config()

	-- Register system if system registration is enabled
	local systems_path = config.assistant_systems_path
	if options.register_in_systems and systems_path then
		local registration_code = templates.get_system_registration_code(name)
		local placeholder = config.assistant_systems_placeholder or "{NEW_SYSTEMS_HERE}"
		insert_at_placeholder(systems_path, placeholder, registration_code)
	end

	-- Register test if test registration is enabled
	if options.register_in_tests and options.include_test and config.assistant_tests_path then
		local test_registration = templates.get_test_registration_code(name)
		local test_placeholder = config.assistant_tests_placeholder or "{NEW_TESTS_HERE}"
		insert_at_placeholder(config.assistant_tests_path, test_placeholder, test_registration)
	end
end


---@param name string
---@param options table
---@param folder_path string
function M.create_entity_files(name, options, folder_path)
	local absolute_folder_path = editor.external_file_attributes(".").path .. folder_path

	-- Create entity file if requested
	if options.create_entity then
		local entity_path = absolute_folder_path .. "entity_" .. name:lower() .. ".lua"
		local entity_template = templates.get_entity_template(name, options)
		write_file(entity_path, entity_template)

		-- Register entity if entity registration is enabled
		local config = load_game_project_config()
		if options.register_in_entities and config.assistant_entities_path then
			local entity_registration = templates.get_entity_registration_code(name)
			local entity_placeholder = config.assistant_entities_placeholder or "{NEW_ENTITIES_HERE}"
			insert_at_placeholder(config.assistant_entities_path, entity_placeholder, entity_registration)
		end

		-- Create collection file if needed
		if options.is_collection then
			local collection_path = absolute_folder_path .. name:lower() .. ".collection"
			local collection_template = templates.get_collection_template(name, options)
			write_file(collection_path, collection_template)
		end

		-- Create GUI files if needed (only when creating an entity)
		if options.is_gui then
			-- Create GUI file
			local gui_path = absolute_folder_path .. name:lower() .. ".gui"
			local gui_template = templates.get_gui_template(name, options)
			write_file(gui_path, gui_template)

			-- Create GUI script only if it's not a Druid widget (widget uses druid_widget.gui_script)
			if not options.is_druid_widget then
				local gui_script_path = absolute_folder_path .. name:lower() .. ".gui_script"
				local gui_script_template = templates.get_gui_script_template(name, options)
				write_file(gui_script_path, gui_script_template)
			else
				-- For Druid widgets, create a Lua module instead of a GUI script
				local lua_module_path = absolute_folder_path .. name:lower() .. ".lua"
				local widget_template = templates.get_druid_widget_template(name, options)
				write_file(lua_module_path, widget_template)
			end
		end
	end

	-- Create system file if needed
	if options.create_system then
		local system_path = absolute_folder_path .. "system_" .. name:lower() .. ".lua"
		local system_template = templates.get_system_template(name, options)
		write_file(system_path, system_template)

		-- Create command if needed
		if options.include_command then
			local command_path = absolute_folder_path .. "command_" .. name:lower() .. ".lua"
			local command_template = templates.get_command_template(name, options)
			write_file(command_path, command_template)
		end

		-- Register system if system registration is enabled
		local config = load_game_project_config()
		if options.register_in_systems and config.assistant_systems_path then
			local registration_code = templates.get_system_registration_code(name)
			local placeholder = config.assistant_systems_placeholder or "{NEW_SYSTEMS_HERE}"
			insert_at_placeholder(config.assistant_systems_path, placeholder, registration_code)
		end
	end

	-- Create test files if needed
	if options.include_test then
		-- Create test directory
		editor.create_directory(absolute_folder_path .. "test")

		local config = load_game_project_config()

		if options.is_gui then
			-- Create test GUI script for GUI entities
			local test_gui_script_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".gui_script"
			local test_gui_script_template = templates.get_test_gui_script_template(name, options)
			write_file(test_gui_script_path, test_gui_script_template)

			-- Create test GUI file
			local test_gui_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".gui"
			local test_gui_template = templates.get_test_gui_template(name, options)
			write_file(test_gui_path, test_gui_template)

			-- Create test collection that includes the GUI
			local test_collection_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".collection"
			local test_collection_template = templates.get_test_gui_collection_template(name, options)
			write_file(test_collection_path, test_collection_template)
		else
			-- Regular test file
			local test_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".lua"
			local test_template = templates.get_test_template(name, options)
			write_file(test_path, test_template)

			-- Create test collection file
			local test_collection_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".collection"
			local test_collection_template = templates.get_collection_template(name, options)
			write_file(test_collection_path, test_collection_template)
		end

		-- Register test if test registration is enabled
		if options.register_in_tests and config.assistant_tests_path then
			local test_registration = templates.get_test_registration_code(name)
			local test_placeholder = config.assistant_tests_placeholder or "{NEW_TESTS_HERE}"
			insert_at_placeholder(config.assistant_tests_path, test_placeholder, test_registration)
		end
	end

	-- Create test system if requested (now independent from options.include_test)
	if options.add_test_system then
		-- Ensure the test directory exists (even if options.include_test is false)
		editor.create_directory(absolute_folder_path .. "test")

		local config = load_game_project_config()
		local test_system_path = absolute_folder_path .. "test/test_system_" .. name:lower() .. ".lua"
		local test_system_template = templates.get_test_system_template(name, options)
		write_file(test_system_path, test_system_template)

		-- Register test system if test registration is enabled
		if options.register_in_tests and config.assistant_tests_path then
			local test_system_registration = templates.get_test_system_registration_code(name)
			local test_placeholder = config.assistant_tests_placeholder or "{NEW_TESTS_HERE}"
			insert_at_placeholder(config.assistant_tests_path, test_placeholder, test_system_registration)
		end
	end

	-- If we have a spawner path for game objects/collections and spawner registration is enabled
	if options.register_in_spawner and (options.is_collection or not options.is_gui) and options.create_entity then
		local config = load_game_project_config()
		if config.assistant_spawner_path then
			-- TODO: Add more sophisticated integration with the spawner
			print("Note: You might need to manually register the entity in the spawner at " .. config.assistant_spawner_path)
		end
	end
end


---@param options table
function M.count_files_to_create(options)
	local count = 0

	-- Entity file
	if options.create_entity then
		count = count + 1
	end

	-- System file
	if options.create_system then
		count = count + 1
	end

	-- Command file
	if options.include_command then
		count = count + 1
	end

	-- GUI files (script + layout)
	if options.is_gui then
		count = count + 1 -- GUI file

		-- Only add script file if not a Druid widget
		if not options.is_druid_widget then
			count = count + 1 -- GUI script
		else
			count = count + 1 -- Lua module
		end
	end

	-- Collection file
	if options.is_collection then
		count = count + 1
	end

	-- Test Collection files
	if options.include_test then
		if options.is_gui then
			count = count + 3 -- Test GUI script + GUI layout + collection file
		else
			count = count + 2 -- Regular test file + collection file
		end
	end

	-- Test system file (independent from test collection)
	if options.add_test_system then
		count = count + 1
	end

	return count
end


return M
