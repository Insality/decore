local M = {}

local TYPE_TABLE = "table"

function M.clear()
	---@type table<string, table<string, entity>> @Key: pack_id, Value: <prefab_id, entity>
	M.entities = {}
	M.entities_order = {}

	---@type table<string, table<string, any>> @Key: pack_id, Value: <component_id, component>
	M.components = {}
	M.components_order = {}
end
M.clear()


---Register component to decore components
---@param component_id string
---@param component_data any
---@param pack_id string|nil default "decore"
function M.register_component(component_id, component_data, pack_id)
	pack_id = pack_id or "decore"

	if not M.components[pack_id] then
		M.components[pack_id] = {}
		table.insert(M.components_order, pack_id)
	end

	M.components[pack_id][component_id] = component_data or {}
end


---@param component_id string
---@param component_pack_id string|nil
---@return any|nil
function M.get_component(component_id, component_pack_id)
	for index = #M.components_order, 1, -1 do
		local pack_id = M.components_order[index]
		local components_pack = M.components[pack_id]
		local prefab = components_pack[component_id]

		if prefab ~= nil and (not component_pack_id or component_pack_id == pack_id) then
			if type(prefab) == TYPE_TABLE then
				return sys.deserialize(sys.serialize(prefab))
			else
				return prefab
			end
		end
	end

	return nil
end


---Checks if component is registered
---@param component_id string
---@param component_pack_id string|nil
---@return boolean
function M.is_component_registered(component_id, component_pack_id)
	for index = #M.components_order, 1, -1 do
		local pack_id = M.components_order[index]
		local components_pack = M.components[pack_id]
		local prefab = components_pack[component_id]

		if prefab ~= nil and (not component_pack_id or component_pack_id == pack_id) then
			return true
		end
	end

	return false
end


---Register entity to decore entities
---@param entity_id string
---@param entity_data table
---@param pack_id string|nil default "decore"
function M.register_entity(entity_id, entity_data, pack_id)
	pack_id = pack_id or "decore"

	if not M.entities[pack_id] then
		M.entities[pack_id] = {}
		table.insert(M.entities_order, pack_id)
	end

	M.entities[pack_id][entity_id] = entity_data or {}
	M.entities[pack_id][hash(entity_id)] = M.entities[pack_id][entity_id]

	-- The prefab_id in components often used to see from which entity it is instanced
	entity_data.prefab_id = entity_id
	entity_data.pack_id = pack_id
end


---@param prefab_id string|hash|nil
---@param pack_id string|nil
---@return entity|nil
function M.get_entity(prefab_id, pack_id)
	if not prefab_id then
		return nil
	end

	for index = #M.entities_order, 1, -1 do
		local check_pack_id = M.entities_order[index]
		local entities_pack = M.entities[check_pack_id]

		local entity = entities_pack[prefab_id]
		if entity and (not pack_id or pack_id == check_pack_id) then
			return entity
		end
	end

	return nil
end


---Log all loaded packs for entities, components and worlds
---@param logger decore.logger
function M.print_loaded_packs_debug_info(logger)
	logger:debug("Entities packs:")
	for _, pack_id in ipairs(M.entities_order) do
		logger:debug(" - " .. pack_id)
		for prefab_id, _ in pairs(M.entities[pack_id]) do
			if type(prefab_id) == "string" then
				logger:debug("   - " .. prefab_id)
			end
		end
	end

	logger:debug("Components packs:")
	for _, pack_id in ipairs(M.components_order) do
		logger:debug(" - " .. pack_id)
		for component_id, _ in pairs(M.components[pack_id]) do
			logger:debug("   - " .. component_id)
		end
	end
end


---Log all loaded systems
---@param world world
---@param logger decore.logger
function M.print_loaded_systems_debug_info(world, logger)
	logger:debug("Systems:")
	for _, system in ipairs(world.systems) do
		logger:debug(" - " .. system.id)
	end
end


return M
