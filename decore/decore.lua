local decore_data = require("decore.internal.decore_data")
local decore_internal = require("decore.internal.decore_internal")
local decore_commands = require("decore.internal.decore_commands")
local decore_debug_page = require("decore.internal.decore_debug_page")
local EMPTY_HASH = hash("")
local TYPE_TABLE = "table"
local NEXT_ENTITY_ID = 0

---@class world
---@field event_bus decore.event_bus

---@class decore
local M = {}
M.clamp = decore_internal.clamp
M.ecs = require("decore.ecs")

---Create a new world instance
---@param ... system[]|nil
---@return world
function M.new_world(...)
	local world = M.ecs.world(
		-- Always included systems
		require("decore.internal.system_decore").create_system(M),
		require("decore.internal.system_event_bus").create_system()
	)

	-- Add systems passed to world constructor
	world:add(...)

	decore_internal.logger:debug("World created", { systems = #world.systems })

	world:refresh()

	return world
end


---Add input event to the world queue
---@param world world
---@param action_id hash
---@param action action
---@return boolean
function M.on_input(world, action_id, action)
	return world.input:on_input(action_id, action)
end


---Add window event to the world event bus
---@param world world
---@param message_id hash
---@param message table|nil
---@param sender url|nil
function M.on_message(world, message_id, message, sender)
	world.event_bus:trigger("on_message", {
		message_id = message_id,
		message = message,
		sender = sender,
	})
end


---Clear all entities and systems from the world
---@param world world
function M.final(world)
	world:clearEntities()
	world:clearSystems()
end


---@generic T
---@param system_module T The module with system functions
---@param system_id string The system id
---@param require_all_filters string|string[]|nil The required components. Example: {"transform", "game_object"} or "transform"
---@return T
function M.system(system_module, system_id, require_all_filters)
	return decore_internal.create_system(M.ecs.system(), system_module, system_id, require_all_filters)
end


---@generic T
---@param system_module T The module with system functions
---@param system_id string The system id
---@param require_all_filters string|string[]|nil The required components. Example: {"transform", "game_object"} or "transform"
---@return T
function M.processing_system(system_module, system_id, require_all_filters)
	return decore_internal.create_system(M.ecs.processingSystem(), system_module, system_id, require_all_filters)
end


---@generic T
---@param system_module T The module with system functions
---@param system_id string The system id
---@param require_all_filters string|string[]|nil The required components. Example: {"transform", "game_object"} or "transform"
---@return T
function M.sorted_system(system_module, system_id, require_all_filters)
	return decore_internal.create_system(M.ecs.sortedSystem(), system_module, system_id, require_all_filters)
end


---@generic T
---@param system_module T The module with system functions
---@param system_id string The system id
---@param require_all_filters string|string[]|nil The required components. Example: {"transform", "game_object"} or "transform"
---@return T
function M.sorted_processing_system(system_module, system_id, require_all_filters)
	return decore_internal.create_system(M.ecs.sortedProcessingSystem(), system_module, system_id, require_all_filters)
end


---Register entity to create it with `create_prefab` function
---@param entity_id string
---@param entity_data table
---@param pack_id string|nil default "decore"
function M.register_entity(entity_id, entity_data, pack_id)
	decore_data.register_entity(entity_id, entity_data, pack_id)
end


---Add entities pack to decore entities
---If entities pack with same id already loaded, do nothing.
---If the same id is used in different packs, the last one will be used in `create_prefab` function
---@param pack_id string
---@param entities table<string, table>
function M.register_entities(pack_id, entities)
	for prefab_id, entity_data in pairs(entities) do
		decore_data.register_entity(prefab_id, entity_data, pack_id)
	end
end


---Unload entities pack from decore entities
---@param pack_id string
function M.unregister_entities(pack_id)
	if not decore_data.entities[pack_id] then
		decore_internal.logger:warn("No entities pack with id to unload", pack_id)
		return
	end

	decore_data.entities[pack_id] = nil
	decore_internal.remove_by_value(decore_data.entities_order, pack_id)
end


---Create new entity instance
---@param components table<string, any>
---@return entity
function M.create(components)
	return M.create_prefab(nil, nil, components)
end


---Create new entity instance from prefab
---@param prefab_id string|hash|nil
---@param pack_id string|nil
---@param components table<string, any>|nil additional components to merge with prefab
---@return entity
function M.create_prefab(prefab_id, pack_id, components)
	NEXT_ENTITY_ID = NEXT_ENTITY_ID + 1

	if prefab_id == EMPTY_HASH then
		prefab_id = nil
	end

	if not prefab_id and not components then
		decore_internal.logger:warn("The entity_id is empty", {
			prefab_id = prefab_id,
			pack_id = pack_id,
		})
		return { id = NEXT_ENTITY_ID }
	end

	local entity = nil
	local prefab = decore_data.get_entity(prefab_id, pack_id)
	if prefab and prefab.parent_prefab_id then
		entity = M.create_prefab(prefab.parent_prefab_id)
	end

	entity = entity or {}
	M.apply_components(entity, prefab)
	M.apply_components(entity, components)
	entity.id = NEXT_ENTITY_ID

	local transform = entity.transform
	local position_x = transform and transform.position_x or 0
	local position_y = transform and transform.position_y or 0
	local position_z = transform and transform.position_z or 0

	decore_internal.logger:trace("Entity created", {
		id = entity.id,
		prefab_id = prefab_id,
		parent_prefab_id = prefab and prefab.parent_prefab_id,
		x = position_x,
		y = position_y,
		z = position_z,
	})

	return entity
end


---Register component to decore components
---@param component_id string
---@param component_data any
---@param pack_id string|nil default "decore"
function M.register_component(component_id, component_data, pack_id)
	decore_data.register_component(component_id, component_data, pack_id)
end


---Register components pack to decore components
---@param components_data decore.components_pack_data
---@return boolean
function M.register_components(components_data)
	local pack_id = components_data.pack_id

	if decore_data.components[pack_id] then
		decore_internal.logger:info("The components pack with the same id already loaded", pack_id)
		return false
	end

	for component_id, component_data in pairs(components_data.components) do
		decore_data.register_component(component_id, component_data, pack_id)
	end

	return true
end


---Unload components pack from decore components
---@param pack_id string
function M.unregister_components(pack_id)
	if not decore_data.components[pack_id] then
		decore_internal.logger:warn("No components pack with id to unload", pack_id)
		return
	end

	decore_data.components[pack_id] = nil
	decore_internal.remove_by_value(decore_data.components_order, pack_id)
end


---Return new component instance from prefab
---@param component_id string
---@param component_pack_id string|nil if nil, use first found from latest loaded pack
---@return any|nil return nil if component not found. False can be returned as a component value (check on nil instead of not)
function M.create_component(component_id, component_pack_id)
	local component_instance = decore_data.get_component(component_id, component_pack_id)

	if component_instance == nil then
		decore_internal.logger:warn("No component_id in components data", {
			component_id = component_id,
			component_pack_id = component_pack_id
		})

		return {}
	end

	return component_instance
end


---Add component to entity.
---If component not exists, it will be created with default values
---If component already exists, it will be merged with the new data
---To refresh system filters, call world:addEntity(entity) after this function
---@param entity entity
---@param component_id string
---@param component_data any|nil if nil, create component with default values
---@return entity
function M.apply_component(entity, component_id, component_data)
	if entity[component_id] == nil then
		entity[component_id] = M.create_component(component_id)
	end

	if component_data then
		if type(component_data) == TYPE_TABLE then
			decore_internal.merge_tables(entity[component_id], component_data)
		else
			entity[component_id] = component_data
		end
	end

	return entity
end


---Add components to entity
---To refresh system filters, call world:addEntity(entity) after this function
---@param entity entity
---@param components table<string, any>|nil
---@return entity
function M.apply_components(entity, components)
	if not components then
		return entity
	end

	for component_id, component_data in pairs(components) do
		M.apply_component(entity, component_id, component_data)
	end

	return entity
end


---@param world world
---@param id number
---@return entity|nil
function M.get_entity_by_id(world, id)
	return M.find_entities(world, "id", id)[1]
end


---Return all entities with component_id equal to component_value or all entities with component_id if component_value is nil.
---It looks for component_id in entity and entityToChange tables
---@param world world
---@param component_id string
---@param component_value any|nil if nil, return all entities with component_id
---@return entity[]
function M.find_entities(world, component_id, component_value)
	local entities = {}

	for index = 1, #world.entities do
		local entity = world.entities[index]
		if entity[component_id] and (not component_value or entity[component_id] == component_value) then
			table.insert(entities, entity)
		end
	end

	return entities
end


---Log all loaded packs for entities, components and worlds
function M.print_loaded_packs_debug_info()
	decore_data.print_loaded_packs_debug_info(decore_internal.logger)
end


---Log all loaded systems
---@param world world
function M.print_loaded_systems_debug_info(world)
	decore_data.print_loaded_systems_debug_info(world, decore_internal.logger)
end


---Grab a command in text format to provide a way to call functions from the system
---@param command_string string Example: "system_name.function_name, arg1, arg2". Separators can be: " ", "," and "\n"
---@return any[]
function M.parse_command(command_string)
	return decore_commands.parse_command(command_string)
end


---Call command from params array. Example: {"system_name", "function_name", "arg1", "arg2", ...}
---@param world world
---@param command any[] Example: [ "command_debug", "toggle_profiler", true ],
function M.call_command(world, command)
	return decore_commands.call_command(world, command)
end


---@param logger_instance decore.logger|table|nil
function M.set_logger(logger_instance)
	decore_internal.logger = logger_instance or decore_internal.empty_logger
	M.logger = decore_internal.logger
end


---@param name string?
---@param level string|nil
---@return decore.logger
function M.get_logger(name, level)
	if not name then
		local current_script_path = debug.getinfo(3).short_src
		local basename = string.match(current_script_path, "([^/\\]+)$")
		basename = string.match(basename, "(.*)%..*$")
		name = basename
	end

	return setmetatable({ name = name, level = level }, { __index = decore_internal.logger })
end


---@param world world
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(world, druid, properties_panel)
	decore_debug_page.render_properties_panel(M, world, druid, properties_panel)
end


return M
