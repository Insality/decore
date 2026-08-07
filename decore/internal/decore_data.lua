local logger = require("decore.internal.decore_logger")
local decore_internal = require("decore.internal.decore_utils")
local decore_shape = require("decore.internal.decore_shape")
local ecs = require("decore.internal.ecs")

local M = {}
M.entities = nil
M.entities_order = nil
M.components = nil
M.components_order = nil

---@type table<string, table<string, any>> pack_id|"*" -> component_id -> source value (not deepcopied)
local resolved_components = {}

---@type table<table, table> prefab table -> fully resolved instance template
local prefab_templates = {}


---Drop resolved/template/shape caches and bump the ECS shape-membership generation
---so live worlds discard stale shapeSystems on next refresh.
function M.invalidate_caches()
	resolved_components = {}
	prefab_templates = {}
	decore_shape.clear()
	ecs.bumpShapeCache()
end


function M.clear()
	---@type table<string, table<string, entity>> Key: pack_id, Value: <prefab_id, entity>
	M.entities = {}
	M.entities_order = {}

	---@type table<string, table<string, any>> Key: pack_id, Value: <component_id, component>
	M.components = {}
	M.components_order = {}

	M.invalidate_caches()
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

	if component_data == nil then
		M.components[pack_id][component_id] = true
	else
		M.components[pack_id][component_id] = component_data
	end
end


---@param component_id string
---@param component_pack_id string|nil
---@return any|nil source value (not deepcopied); caller must deepcopy tables
local function resolve_component_source(component_id, component_pack_id)
	local pack_key = component_pack_id or "*"
	local pack_cache = resolved_components[pack_key]
	if pack_cache and pack_cache[component_id] ~= nil then
		return pack_cache[component_id]
	end

	for index = #M.components_order, 1, -1 do
		local pack_id = M.components_order[index]
		local components_pack = M.components[pack_id]
		local prefab = components_pack[component_id]

		if prefab ~= nil and (not component_pack_id or component_pack_id == pack_id) then
			pack_cache = pack_cache or {}
			resolved_components[pack_key] = pack_cache
			pack_cache[component_id] = prefab
			return prefab
		end
	end

	return nil
end


---@param component_id string
---@param component_pack_id string|nil
---@return any|nil
function M.get_component(component_id, component_pack_id)
	local prefab = resolve_component_source(component_id, component_pack_id)
	if prefab == nil then
		return nil
	end

	if type(prefab) == "table" then
		return decore_internal.deepcopy(prefab)
	end

	return prefab
end


---Checks if component is registered
---@param component_id string
---@param component_pack_id string|nil
---@return boolean
function M.is_component_registered(component_id, component_pack_id)
	return resolve_component_source(component_id, component_pack_id) ~= nil
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

	logger:warn("Entity is not registered in Decore to spawn", {
		prefab_id = prefab_id,
		pack_id = pack_id,
	})

	return nil
end


---Apply one component onto a template the same way decore.apply_component does.
---Nested tables from prefab/component data stay by reference (not copied).
---@param template table
---@param component_id string
---@param component_data any|nil
local function template_apply_component(template, component_id, component_data)
	-- An object replaces the component as a whole, so the default is never read
	if template[component_id] == nil and not decore_internal.is_object(component_data) then
		local default = resolve_component_source(component_id)
		if default == nil then
			template[component_id] = {}
		elseif type(default) == "table" then
			template[component_id] = decore_internal.deepcopy(default)
		else
			template[component_id] = default
		end
	end

	if component_data ~= nil then
		decore_internal.assign_component_prototype(template, component_id, component_data)
	end
end


---Build fully resolved instance template for a prefab (defaults + parent chain + prefab data).
---@param prefab entity
---@return table
local function build_prefab_template(prefab)
	local template

	if prefab.parent_prefab_id then
		local parent = M.get_entity(prefab.parent_prefab_id)
		if parent then
			template = decore_internal.instantiate_template(M.get_prefab_template(parent))
		end
	end

	template = template or {}

	for component_id, component_data in pairs(prefab) do
		template_apply_component(template, component_id, component_data)
	end

	return template
end


---Return cached fully-resolved prefab template.
---Caller must instantiate via instantiate_template (not deepcopy) to keep nested tables by ref.
---@param prefab entity
---@return table
function M.get_prefab_template(prefab)
	local template = prefab_templates[prefab]
	if template then
		return template
	end

	template = build_prefab_template(prefab)
	prefab_templates[prefab] = template
	return template
end


---Log all loaded packs for entities, components and worlds
function M.print_loaded_packs_debug_info()
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
function M.print_loaded_systems_debug_info(world)
	logger:debug("Systems:")
	for _, system in ipairs(world.systems) do
		logger:debug(" - " .. system.id)
	end
end


return M
