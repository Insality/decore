local templates = require("decore.editor_scripts.templates")

local M = {}


---@param path string
---@param content string
local function write_file(path, content)
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
---@param content string
local function append_to_file(path, content)
    local file = io.open(path, "a")
    if not file then
        print("Error: Could not append to file at", path)
        return false
    end
    file:write(content)
    file:close()
    print("Appended to file at", path)
    return true
end


---@param path string
---@param pattern string
---@param replacement string
local function replace_in_file(path, pattern, replacement)
    -- Read the file
    local file = io.open(path, "r")
    if not file then
        print("Error: Could not read file at", path)
        return false
    end

    local content = file:read("*a")
    file:close()

    -- Replace the pattern
    local new_content, replacements = content:gsub(pattern, replacement)
    if replacements == 0 then
        print("Warning: Pattern not found in file", path)
        return false
    end

    -- Write the file
    file = io.open(path, "w")
    if not file then
        print("Error: Could not write file at", path)
        return false
    end

    file:write(new_content)
    file:close()
    print("Updated file at", path)
    return true
end


---@param path string
---@param placeholder string
---@param insert_code string
local function insert_at_placeholder(path, placeholder, insert_code)
	local absolute_path = editor.external_file_attributes(".").path .. path
    return replace_in_file(absolute_path, placeholder, placeholder .. "\n" .. insert_code)
end


---@return table
local function load_game_project_config()
    -- Load the game.project file to get the forge paths
    local project_path = editor.external_file_attributes(".").path
    local game_project_path = project_path .. editor.get("/game.project", "path")

    local config = {}
    local file = io.open(game_project_path, "r")
    if not file then
        print("Error: Could not open game.project file")
        return config
    end

    local in_decore_section = false
    for line in file:lines() do
        if line == "[decore]" then
            in_decore_section = true
        elseif line:match("^%[") then
            in_decore_section = false
        elseif in_decore_section then
            local key, value = line:match("([%w_]+)%s*=%s*(.*)")
            if key and value then
                config[key] = value
            end
        end
    end

    file:close()
    return config
end


---@param template string
---@param name string
---@return string
local function process_template(template, name)
    return template:gsub("{NAME_LOWER}", name:lower())
                  :gsub("{NAME}", name)
                  :gsub("{NAME_UPPER}", name:upper())
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

    -- Create entity file if needed
    if options.include_entity_lua then
        local entity_path = absolute_folder_path .. name:lower() .. ".lua"
        local entity_template = templates.get_entity_template(name, options)
        write_file(entity_path, entity_template)
    end

    -- Create test file if needed
    if options.include_test then
        -- Create test directory
        editor.create_directory(absolute_folder_path .. "test")
        local test_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".lua"
        local test_template = templates.get_test_template(name, options)
        write_file(test_path, test_template)
    end

    -- Register in the appropriate files
    local config = load_game_project_config()

    -- Register system
    local systems_path = config.forge_systems_path
    if systems_path then
        local registration_code = templates.get_system_registration_code(name)
        local placeholder = config.forge_systems_placeholder or "{NEW_SYSTEMS_HERE}"
        insert_at_placeholder(systems_path, placeholder, registration_code)
    end

    -- Register test
    if options.include_test and config.forge_tests_path then
        local test_registration = templates.get_test_registration_code(name)
        local test_placeholder = config.forge_tests_placeholder or "{NEW_TESTS_HERE}"
        insert_at_placeholder(config.forge_tests_path, test_placeholder, test_registration)
    end

    -- Register entity
    if options.include_entity_lua and config.forge_entities_path then
        local entity_registration = templates.get_entity_registration_code(name)
        local entity_placeholder = config.forge_entities_placeholder or "{NEW_ENTITIES_HERE}"
        insert_at_placeholder(config.forge_entities_path, entity_placeholder, entity_registration)
    end
end


---@param name string
---@param options table
---@param folder_path string
function M.create_entity_files(name, options, folder_path)
    -- Create entity file
    local absolute_folder_path = editor.external_file_attributes(".").path .. folder_path
    local entity_path = absolute_folder_path .. name:lower() .. ".lua"
    local entity_template = templates.get_entity_template(name, options)
    write_file(entity_path, entity_template)

    -- Create GUI files if needed
    if options.is_gui then
        -- Create GUI file
        local gui_path = absolute_folder_path .. name:lower() .. ".gui"
        local gui_template = templates.get_gui_template(name, options)
        write_file(gui_path, gui_template)

        -- Create GUI script
        local gui_script_path = absolute_folder_path .. name:lower() .. ".gui_script"
        local gui_script_template = templates.get_gui_script_template(name, options)
        write_file(gui_script_path, gui_script_template)
    end

    -- Create collection file if needed
    if options.is_collection then
        local collection_path = absolute_folder_path .. name:lower() .. ".collection"
        local collection_template = templates.get_collection_template(name, options)
        write_file(collection_path, collection_template)
    end

    -- Create system file if needed
    if options.add_system then
        local system_path = absolute_folder_path .. "system_" .. name:lower() .. ".lua"
        local system_template = templates.get_system_template(name, options)
        write_file(system_path, system_template)
    end

    -- Create test files if needed
    if options.include_test then
        -- Create test directory
        editor.create_directory(absolute_folder_path .. "test")

        if options.is_gui then
            -- Create test GUI script for GUI entities
            local test_gui_script_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".gui_script"
            local test_gui_script_template = templates.get_test_gui_script_template(name, options)
            write_file(test_gui_script_path, test_gui_script_template)

            -- Create test GUI file
            local test_gui_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".gui"
            local test_gui_template = templates.get_gui_template(name, options)
            write_file(test_gui_path, test_gui_template)
        else
            -- Regular test file
            local test_path = absolute_folder_path .. "test/test_" .. name:lower() .. ".lua"
            local test_template = templates.get_test_template(name, options)
            write_file(test_path, test_template)
        end
    end

    -- Register in the appropriate files
    local config = load_game_project_config()

    -- Register entity
    if config.forge_entities_path then
        local entity_registration = templates.get_entity_registration_code(name)
        local entity_placeholder = config.forge_entities_placeholder or "{NEW_ENTITIES_HERE}"
        insert_at_placeholder(config.forge_entities_path, entity_placeholder, entity_registration)
    end

    -- Register system
    if options.add_system and config.forge_systems_path then
        local registration_code = templates.get_system_registration_code(name)
        local placeholder = config.forge_systems_placeholder or "{NEW_SYSTEMS_HERE}"
        insert_at_placeholder(config.forge_systems_path, placeholder, registration_code)
    end

    -- Register test
    if options.include_test and config.forge_tests_path then
        local test_registration = templates.get_test_registration_code(name)
        local test_placeholder = config.forge_tests_placeholder or "{NEW_TESTS_HERE}"
        insert_at_placeholder(config.forge_tests_path, test_placeholder, test_registration)
    end

    -- If we have a spawner path for game objects/collections
    if (options.is_collection or not options.is_gui) and config.forge_spawner_path then
        -- TODO: Add more sophisticated integration with the spawner
        print("Note: You might need to manually register the entity in the spawner at " .. config.forge_spawner_path)
    end
end


return M
