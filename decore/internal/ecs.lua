--[[
Copyright (c) 2016 Calvin Rose

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- @module tiny-ecs
-- @author Calvin Rose
-- @license MIT
-- @copyright 2016

---@class entity
---@field __shape any|nil Shape token for system-membership cache (set by decore)

---@class system
---@field indices table<entity, number> Entity index in entities table
---@field id string
---@field filter fun(self: system, entity: entity)|nil
---@field active boolean
---@field world world
---@field entities entity[]
---@field index number
---@field modified boolean
---@field hasOnModify boolean|nil True when system has onModify; set by world
---@field interval number|nil
---@field bufferedTime number|nil
---@field onAdd fun(self: system, entity:entity)|nil
---@field onRemove fun(self: system, entity:entity)|nil
---@field onModify fun(self: system, dt:number)|nil
---@field onAddToWorld fun(self: system, world:world)|nil
---@field onRemoveFromWorld fun(self: system, world:world)|nil
---@field preWrap fun(system: system, dt:number)|nil
---@field postWrap fun(system: system, dt:number)|nil
---@field update fun(system: system, dt:number)|nil
---@field fixed_update fun(system: system, dt:number)|nil
---@field late_update fun(system: system, dt:number)|nil
---@field preProcess fun(system: system, dt:number)|nil
---@field process fun(system: system, entity:entity, dt:number)|nil
---@field postProcess fun(system: system, dt:number)|nil
---@field compare fun(e1:entity, e2:entity)|nil

---@class world
---@field entities entity[]
---@field systems system[]
---@field systemsUpdate system[]
---@field systemsPreWrap system[]
---@field systemsPostWrap system[]
---@field systemsLateUpdate system[]
---@field systemsFixedUpdate system[]
---@field systemsOnModify system[]
---@field shapeSystems table<any, system[]> Shape token -> matched systems
---@field shapeGeneration number|nil Generation of shapeSystems (vs ecs shape cache bump)
---@field speed number|nil Koef for delta time
---@field id_to_entity table<number, entity>|nil Entity id -> entity (set by decore system)
---@field add fun(self: world, ...): ...
---@field addEntity fun(self: world, entity: entity): entity
---@field addSystem fun(self: world, system: system): system
---@field remove fun(self: world, ...)
---@field removeEntity fun(self: world, entity: entity): entity
---@field removeSystem fun(self: world, system: system): system
---@field refresh fun(self: world)
---@field update fun(self: world, dt:number, filter:fun()|nil)
---@field fixed_update fun(self: world, dt:number, filter:fun()|nil)
---@field late_update fun(self: world, dt:number, filter:fun()|nil)
---@field clearEntities fun(self: world)
---@field clearSystems fun(self: world)
---@field getEntityCount fun(self: world)
---@field getSystemCount fun(self: world)
---@field setSystemIndex fun(self: world)
---@field entitiesToChange entity[]
---@field entitiesToRemove entity[]
---@field systemsToChange system[]
---@field systemsToAdd system[]
---@field systemsToRemove system[]
---@field findEntities fun(world: world, component_id: string, component_value: any|nil, out: entity[]|nil): entity[]
---@field findEntity fun(world: world, component_id: string, component_value: any|nil): entity|nil

---@class tiny_ecs Tiny ECS module
---@field requireAll fun(...): ... Returns a filter function that requires all of the specified components
---@field requireAny fun(...): ... Returns a filter function that requires any of the specified components
---@field rejectAll fun(...): ... Returns a filter function that rejects all of the specified components
---@field rejectAny fun(...): ... Returns a filter function that rejects any of the specified components
---@field filter fun(pattern: string): any, any Returns a filter function that matches the specified pattern
---@field system fun(table: system|nil): system Creates a new system
---@field processingSystem fun(table: system|nil): system Creates a new processing system
---@field sortedSystem fun(table: system|nil): system Creates a new sorted system
---@field sortedProcessingSystem fun(table: system|nil): system Creates a new sorted processing system
---@field world fun(...): world, ... Creates a new world
---@field addEntity fun(world: world, entity: entity): entity Adds an entity to the world
---@field addSystem fun(world: world, system: system): system Adds a system to the world
---@field add fun(world: world, ...): ... Adds entities to the world
---@field removeEntity fun(world: world, entity: entity): entity Removes an entity from the world
---@field removeSystem fun(world: world, system: system): system Removes a system from the world
---@field remove fun(world: world, ...): ... Removes entities from the world
---@field refresh fun(world: world) Refreshes the world
---@field update fun(world: world, dt: number, filter: fun(...)|nil): ... Updates the world
---@field clearEntities fun(world: world) Clears all entities from the world
---@field clearSystems fun(world: world) Clears all systems from the world
---@field getEntityCount fun(world: world): number Returns the number of entities in the world
---@field getSystemCount fun(world: world): number Returns the number of systems in the world
---@field setSystemIndex fun(world: world, system: system, index: number): number Sets the index of a system in the world
---@field setShapeValidation fun(enabled: boolean) Enable/disable shape-cache validation (debug)
---@field bumpShapeCache fun() Invalidate world shapeSystems (call when packs change)
local tiny = {}

-- Local versions of standard lua functions
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local setmetatable = setmetatable
local type = type
local select = select

-- Local versions of the library functions
local tiny_manageEntities
local tiny_manageSystems
local tiny_addEntity
local tiny_addSystem
local tiny_add
local tiny_removeEntity
local tiny_removeSystem

-- Shape-cache validation (off by default). When on, fast path also runs full
-- scan and prints mismatches — use to catch presence-filter violations.
local shape_validation = false

-- Bumped when prefab/component packs change so worlds drop stale shapeSystems.
local shape_cache_generation = 0


--- Filter functions.
-- A Filter is a function that selects which Entities apply to a System.
-- Filters take two parameters, the System and the Entity, and return a boolean
-- value indicating if the Entity should be processed by the System. A truthy
-- value includes the entity, while a falsey (nil or false) value excludes the
-- entity.
--
-- Filters must be added to Systems by setting the `filter` field of the System.
-- Filter's returned by tiny-ecs's Filter functions are immutable and can be
-- used by multiple Systems.
--
--    local f1 = tiny.requireAll("position", "velocity", "size")
--    local f2 = tiny.requireAny("position", "velocity", "size")
--
--    local e1 = {
--        position = {2, 3},
--        velocity = {3, 3},
--        size = {4, 4}
--    }
--
--    local entity2 = {
--        position = {4, 5},
--        size = {4, 4}
--    }
--
--    local e3 = {
--        position = {2, 3},
--        velocity = {3, 3}
--    }
--
-- Filters can also be passed as arguments to other Filter constructors. This is
-- a powerful way to create complex, custom Filters that select a very specific
-- set of Entities.
--
--    -- Selects Entities with an "image" Component, but not Entities with a
--    -- "Player" or "Enemy" Component.
--    filter = tiny.requireAll("image", tiny.rejectAny("Player", "Enemy"))
--
-- IMPORTANT: Filters must be presence-only (component key exists or not).
-- Value-based filters break the shape-membership cache.
--
-- @section Filter

-- A helper function to compile filters.
local filterJoin

-- A helper function to filters from string
local filterBuildString
do
	local loadstring = loadstring or load
	local function getchr(c)
		return "\\" .. c:byte()
	end
	local function make_safe(text)
		return ("%q"):format(text):gsub('\n', 'n'):gsub("[\128-\255]", getchr)
	end

	local function filterJoinRaw(prefix, seperator, ...)
		local accum = {}
		local build = {}
		for i = 1, select('#', ...) do
			local item = select(i, ...)
			if type(item) == 'string' then
				accum[#accum + 1] = ("(e[%s] ~= nil)"):format(make_safe(item))
			elseif type(item) == 'function' then
				build[#build + 1] = ('local subfilter_%d_ = select(%d, ...)')
					:format(i, i)
				accum[#accum + 1] = ('(subfilter_%d_(system, e))'):format(i)
			else
				error 'Filter token must be a string or a filter function.'
			end
		end
		local source = ('%s\nreturn function(system, e) return %s(%s) end')
			:format(
				table.concat(build, '\n'),
				prefix,
				table.concat(accum, seperator))
		local loader, err = loadstring(source)
		if not loader then error(err) end
		return loader(...)
	end

	---@param ... any
	function filterJoin(...)
		local state, value = pcall(filterJoinRaw, ...)
		if state then return value else return nil, value end
	end

	local function buildPart(str)
		local accum = {}
		local subParts = {}
		str = str:gsub('%b()', function(p)
			subParts[#subParts + 1] = buildPart(p:sub(2, -2))
			return ('\255%d'):format(#subParts)
		end)
		for invert, part, sep in str:gmatch('(%!?)([^%|%&%!]+)([%|%&]?)') do
			if part:match('^\255%d+$') then
				local partIndex = tonumber(part:match(part:sub(2)))
				accum[#accum + 1] = ('%s(%s)')
					:format(invert == '' and '' or 'not', subParts[partIndex])
			else
				accum[#accum + 1] = ("(e[%s] %s nil)")
					:format(make_safe(part), invert == '' and '~=' or '==')
			end
			if sep ~= '' then
				accum[#accum + 1] = (sep == '|' and ' or ' or ' and ')
			end
		end
		return table.concat(accum)
	end

	function filterBuildString(str)
		local source = ("return function(_, e) return %s end")
			:format(buildPart(str))
		local loader, err = loadstring(source)
		if not loader then
			error(err)
		end
		return loader()
	end

end

---Makes a Filter that selects Entities with all specified Components and filters.
function tiny.requireAll(...)
	return filterJoin('', ' and ', ...)
end

--- Makes a Filter that selects Entities with at least one of the specified
-- Components and Filters.
function tiny.requireAny(...)
	return filterJoin('', ' or ', ...)
end

--- Makes a Filter that rejects Entities with all specified Components and
-- Filters, and selects all other Entities.
function tiny.rejectAll(...)
	return filterJoin('not', ' and ', ...)
end

--- Makes a Filter that rejects Entities with at least one of the specified
-- Components and Filters.
function tiny.rejectAny(...)
	return filterJoin('not', ' or ', ...)
end

--- Makes a Filter from a string. Syntax of `pattern` is as follows.
--
--   * Tokens are alphanumeric strings including underscores.
--   * Tokens can be separated by |, &, or surrounded by parentheses.
--   * Tokens can be prefixed with !, and are then inverted.
--
-- Examples are best:
--    'a|b|c' - Matches entities with an 'a' OR 'b' OR 'c'.
--    'a&!b&c' - Matches entities with an 'a' AND NOT 'b' AND 'c'.
--    'a|(b&c&d)|e - Matches 'a' OR ('b' AND 'c' AND 'd') OR 'e'
-- @param pattern
function tiny.filter(pattern)
	local state, value = pcall(filterBuildString, pattern)
	if state then return value else return nil, value end
end

--- System functions.
-- A System is a wrapper around function callbacks for manipulating Entities.
-- Systems are implemented as tables that contain at least one method;
-- an update function that takes parameters like so:
--
--   * `function system:update(dt)`.
--
-- There are also a few other optional callbacks:
--
--   * `function system:filter(entity)` - Returns true if this System should
-- include this Entity, otherwise should return false. If this isn't specified,
-- no Entities are included in the System.
--   * `function system:onAdd(entity)` - Called when an Entity is added to the
-- System.
--   * `function system:onRemove(entity)` - Called when an Entity is removed
-- from the System.
--   * `function system:onModify(dt)` - Called when the System is modified by
-- adding or removing Entities from the System.
--   * `function system:onAddToWorld(world)` - Called when the System is added
-- to the World, before any entities are added to the system.
--   * `function system:onRemoveFromWorld(world)` - Called when the System is
-- removed from the world, after all Entities are removed from the System.
--   * `function system:preWrap(dt)` - Called on each system before update is
-- called on any system.
--   * `function system:postWrap(dt)` - Called on each system in reverse order
-- after update is called on each system. The idea behind `preWrap` and
-- `postWrap` is to allow for systems that modify the behavior of other systems.
-- Say there is a DrawingSystem, which draws sprites to the screen, and a
-- PostProcessingSystem, that adds some blur and bloom effects. In the preWrap
-- method of the PostProcessingSystem, the System could set the drawing target
-- for the DrawingSystem to a special buffer instead the screen. In the postWrap
-- method, the PostProcessingSystem could then modify the buffer and render it
-- to the screen. In this setup, the PostProcessingSystem would be added to the
-- World after the drawingSystem (A similar but less flexible behavior could
-- be accomplished with a single custom update function in the DrawingSystem).
--
-- For Filters, it is convenient to use `tiny.requireAll` or `tiny.requireAny`,
-- but one can write their own filters as well. Set the Filter of a System like
-- so:
--    system.filter = tiny.requireAll("a", "b", "c")
-- or
--    function system:filter(entity)
--        return entity.myRequiredComponentName ~= nil
--    end
--
-- All Systems also have a few important fields that are initialized when the
-- system is added to the World. A few are important, and few should be less
-- commonly used.
--
--   * The `world` field points to the World that the System belongs to. Useful
-- for adding and removing Entities from the world dynamically via the System.
--   * The `active` flag is whether or not the System is updated automatically.
-- Inactive Systems should be updated manually or not at all via
-- `system:update(dt)`. Defaults to true.
--   * The `entities` field is an ordered list of Entities in the System. This
-- list can be used to quickly iterate through all Entities in a System.
--   * The `interval` field is an optional field that makes Systems update at
-- certain intervals using buffered time, regardless of World update frequency.
-- For example, to make a System update once a second, set the System's interval
-- to 1.
--   * The `index` field is the System's index in the World. Lower indexed
-- Systems are processed before higher indices. The `index` is a read only
-- field; to set the `index`, use `tiny.setSystemIndex(world, system)`.
--   * The `indices` field is a table of Entity keys to their indices in the
-- `entities` list. Most Systems can ignore this.
--   * The `modified` flag is an indicator if the System has been modified in
-- the last update. If so, the `onModify` callback will be called on the System
-- in the next update, if it has one. This is usually managed by tiny-ecs, so
-- users should mostly ignore this, too.
--
-- @section System

-- Use an empty table as a key for identifying Systems. Any table that contains
-- this key is considered a System rather than an Entity.
local systemTableKey = { "SYSTEM_TABLE_KEY" }

-- Checks if a table is a System.
local function isSystem(table)
	return table[systemTableKey]
end


---@param system system
---@param entity entity
local function addToSystem(system, entity)
	local indices = system.indices
	if indices[entity] then
		return
	end

	local entities = system.entities
	local index = #entities + 1
	entities[index] = entity
	indices[entity] = index

	if system.hasOnModify then
		system.modified = true
	end

	local onAdd = system.onAdd
	if onAdd then
		onAdd(system, entity)
	end
end


---@param system system
---@param entity entity
local function removeFromSystem(system, entity)
	local indices = system.indices
	local index = indices[entity]
	if not index then
		return
	end

	local entities = system.entities
	local tmpEntity = entities[#entities]
	entities[index] = tmpEntity
	indices[tmpEntity] = index
	indices[entity] = nil
	entities[#entities] = nil

	if system.hasOnModify then
		system.modified = true
	end

	local onRemove = system.onRemove
	if onRemove then
		onRemove(system, entity)
	end
end


---@param world world
---@param entity entity
---@return system[]
local function resolveShape(world, entity)
	local matched = {}
	local systems = world.systems
	for i = 1, #systems do
		local system = systems[i]
		local filter = system.filter
		if filter and filter(system, entity) then
			matched[#matched + 1] = system
		end
	end
	return matched
end


---@param world world
local function rebuildDispatchLists(world)
	local systems = world.systems
	local systemsUpdate = {}
	local systemsPreWrap = {}
	local systemsPostWrap = {}
	local systemsLateUpdate = {}
	local systemsFixedUpdate = {}
	local systemsOnModify = {}

	for i = 1, #systems do
		local system = systems[i]
		if system.update then
			systemsUpdate[#systemsUpdate + 1] = system
		end
		if system.preWrap then
			systemsPreWrap[#systemsPreWrap + 1] = system
		end
		if system.postWrap then
			systemsPostWrap[#systemsPostWrap + 1] = system
		end
		if system.late_update then
			systemsLateUpdate[#systemsLateUpdate + 1] = system
		end
		if system.fixed_update then
			systemsFixedUpdate[#systemsFixedUpdate + 1] = system
		end
		if system.onModify then
			system.hasOnModify = true
			systemsOnModify[#systemsOnModify + 1] = system
		else
			system.hasOnModify = false
		end
	end

	world.systemsUpdate = systemsUpdate
	world.systemsPreWrap = systemsPreWrap
	world.systemsPostWrap = systemsPostWrap
	world.systemsLateUpdate = systemsLateUpdate
	world.systemsFixedUpdate = systemsFixedUpdate
	world.systemsOnModify = systemsOnModify
end


---@param world world
---@param entity entity
---@param matched system[]
local function validateShapeMatch(world, entity, matched)
	local expected = {}
	for i = 1, #matched do
		expected[matched[i]] = true
	end

	local systems = world.systems
	for i = 1, #systems do
		local system = systems[i]
		local filter = system.filter
		local should_match = filter and filter(system, entity)
		local does_match = expected[system]
		if should_match and not does_match then
			print(("SHAPE CACHE MISS: entity id=%s prefab=%s missing system %s"):format(
				tostring(entity.id), tostring(entity.prefab_id), tostring(system.id)))
		elseif does_match and not should_match then
			print(("SHAPE CACHE EXTRA: entity id=%s prefab=%s unexpected system %s"):format(
				tostring(entity.id), tostring(entity.prefab_id), tostring(system.id)))
		end
	end
end


-- Update function for all Processing Systems.
local function processingSystemUpdate(system, dt)
	local preProcess = system.preProcess
	local process = system.process
	local postProcess = system.postProcess

	if preProcess then
		preProcess(system, dt)
	end

	if process then
		local entities = system.entities
		for i = 1, #entities do
			process(system, entities[i], dt)
		end
	end

	if postProcess then
		postProcess(system, dt)
	end
end

-- Sorts Systems by a function system.sortDelegate(entity1, entity2) on modify.
local function sortedSystemOnModify(system)
	local entities = system.entities
	local indices = system.indices
	local sortDelegate = system.sortDelegate
	if not sortDelegate then
		local compare = system.compare
		sortDelegate = function(e1, e2)
			return compare(system, e1, e2)
		end
		system.sortDelegate = sortDelegate
	end
	tsort(entities, sortDelegate)
	for i = 1, #entities do
		indices[entities[i]] = i
	end
end

--- Creates a new System or System class from the supplied table. If `table` is
-- nil, creates a new table.
function tiny.system(table)
	table = table or {}
	table[systemTableKey] = true
	return table
end

--- Creates a new Processing System or Processing System class. Processing
-- Systems process each entity individual, and are usually what is needed.
-- Processing Systems have three extra callbacks besides those inheritted from
-- vanilla Systems.
--
--     function system:preProcess(dt) -- Called before iteration.
--     function system:process(entity, dt) -- Process each entity.
--     function system:postProcess(dt) -- Called after iteration.
--
-- Processing Systems have their own `update` method, so don't implement a
-- a custom `update` callback for Processing Systems.
-- @see system
function tiny.processingSystem(table)
	table = table or {}
	table[systemTableKey] = true
	table.update = processingSystemUpdate
	return table
end

--- Creates a new Sorted System or Sorted System class. Sorted Systems sort
-- their Entities according to a user-defined method, `system:compare(e1, e2)`,
-- which should return true if `e1` should come before `e2` and false otherwise.
-- Sorted Systems also override the default System's `onModify` callback, so be
-- careful if defining a custom callback. However, for processing the sorted
-- entities, consider `tiny.sortedProcessingSystem(table)`.
-- @see system
function tiny.sortedSystem(table)
	table = table or {}
	table[systemTableKey] = true
	table.onModify = sortedSystemOnModify
	return table
end

--- Creates a new Sorted Processing System or Sorted Processing System class.
-- Sorted Processing Systems have both the aspects of Processing Systems and
-- Sorted Systems.
-- @see system
-- @see processingSystem
-- @see sortedSystem
function tiny.sortedProcessingSystem(table)
	table = table or {}
	table[systemTableKey] = true
	table.update = processingSystemUpdate
	table.onModify = sortedSystemOnModify
	return table
end

--- World functions.
-- A World is a container that manages Entities and Systems. Typically, a
-- program uses one World at a time.
--
-- For all World functions except `tiny.world(...)`, object-oriented syntax can
-- be used instead of the documented syntax. For example,
-- `tiny.add(world, e1, e2, e3)` is the same as `world:add(e1, e2, e3)`.
-- @section World

-- Forward declaration
local worldMetaTable

--- Creates a new World.
-- Can optionally add default Systems and Entities. Returns the new World along
-- with default Entities and Systems.
---@return world, ...
function tiny.world(...)
	local ret = setmetatable({

		-- List of Entities to remove
		entitiesToRemove = {},

		-- List of Entities to change
		entitiesToChange = {},

		-- List of Systems to add
		systemsToAdd = {},

		-- List of Systems to remove
		systemsToRemove = {},

		-- Set of Entities
		entities = {},

		-- List of Systems
		systems = {},

		-- Precomputed dispatch lists (rebuilt when systems change)
		systemsUpdate = {},
		systemsPreWrap = {},
		systemsPostWrap = {},
		systemsLateUpdate = {},
		systemsFixedUpdate = {},
		systemsOnModify = {},

		-- Shape token -> matched systems list
		shapeSystems = {},
		shapeGeneration = shape_cache_generation,

	}, worldMetaTable)

	tiny_add(ret, ...)
	tiny_manageSystems(ret)
	tiny_manageEntities(ret)

	return ret, ...
end

--- Adds an Entity to the world.
-- Also call this on Entities that have changed Components such that they
-- match different Filters. Returns the Entity.
---@param world world
---@param entity entity
---@return entity
function tiny.addEntity(world, entity)
	local e2c = world.entitiesToChange
	e2c[#e2c + 1] = entity
	return entity
end
tiny_addEntity = tiny.addEntity

--- Adds a System to the world. Returns the System.
function tiny.addSystem(world, system)
	assert(system.world == nil, "System already belongs to a World.")
	local s2a = world.systemsToAdd
	s2a[#s2a + 1] = system
	system.world = world
	return system
end
tiny_addSystem = tiny.addSystem

--- Shortcut for adding multiple Entities and Systems to the World. Returns all
-- added Entities and Systems.
function tiny.add(world, ...)
	for i = 1, select("#", ...) do
		local obj = select(i, ...)
		if obj then
			if isSystem(obj) then
				tiny_addSystem(world, obj)
			else -- Assume obj is an Entity
				tiny_addEntity(world, obj)
			end
		end
	end
	return ...
end
tiny_add = tiny.add

--- Removes an Entity from the World. Returns the Entity.
function tiny.removeEntity(world, entity)
	local e2r = world.entitiesToRemove
	e2r[#e2r + 1] = entity
	return entity
end
tiny_removeEntity = tiny.removeEntity

--- Removes a System from the world. Returns the System.
function tiny.removeSystem(world, system)
	assert(system.world == world, "System does not belong to this World.")
	local s2r = world.systemsToRemove
	s2r[#s2r + 1] = system
	return system
end
tiny_removeSystem = tiny.removeSystem

--- Shortcut for removing multiple Entities and Systems from the World. Returns
-- all removed Systems and Entities
function tiny.remove(world, ...)
	for i = 1, select("#", ...) do
		local obj = select(i, ...)
		if obj then
			if isSystem(obj) then
				tiny_removeSystem(world, obj)
			else -- Assume obj is an Entity
				tiny_removeEntity(world, obj)
			end
		end
	end
	return ...
end

-- Adds and removes Systems that have been marked from the World.
---@param world world
function tiny_manageSystems(world)
	local s2a, s2r = world.systemsToAdd, world.systemsToRemove

	-- Early exit
	if #s2a == 0 and #s2r == 0 then
		return
	end

	world.systemsToAdd = {}
	world.systemsToRemove = {}
	-- System set changed — drop shape cache (rebuilds lazily)
	world.shapeSystems = {}
	world.shapeGeneration = shape_cache_generation

	local worldEntityList = world.entities
	local systems = world.systems

	-- Remove Systems
	for i = 1, #s2r do
		local system = s2r[i]
		local index = system.index
		local onRemove = system.onRemove
		if onRemove then
			local entityList = system.entities
			for j = 1, #entityList do
				onRemove(system, entityList[j])
			end
		end
		tremove(systems, index)
		for j = index, #systems do
			systems[j].index = j
		end
		local onRemoveFromWorld = system.onRemoveFromWorld
		if onRemoveFromWorld then
			onRemoveFromWorld(system, world)
		end
		s2r[i] = nil

		-- Clean up System
		system.world = nil
		system.entities = nil
		system.indices = nil
		system.index = nil
		system.hasOnModify = nil
	end

	-- Add Systems
	for i = 1, #s2a do
		local system = s2a[i]
		if systems[system.index or 0] ~= system then
			system.entities = {}
			system.indices = {}
			if system.active == nil then
				system.active = true
			end
			system.modified = true
			system.world = world
			local index = #systems + 1
			system.index = index
			systems[index] = system
			local onAddToWorld = system.onAddToWorld
			if onAddToWorld then
				onAddToWorld(system, world)
			end

			-- Try to add Entities
			local filter = system.filter
			if filter then
				for j = 1, #worldEntityList do
					local entity = worldEntityList[j]
					if filter(system, entity) then
						addToSystem(system, entity)
					end
				end
			end
		end
		s2a[i] = nil
	end

	rebuildDispatchLists(world)
end

-- Adds, removes, and changes Entities that have been marked.
function tiny_manageEntities(world)
	local e2r = world.entitiesToRemove
	local e2c = world.entitiesToChange

	-- Early exit
	if #e2r == 0 and #e2c == 0 then
		return
	end

	world.entitiesToChange = {}
	world.entitiesToRemove = {}

	local entities = world.entities
	local systems = world.systems

	-- Prefab/component packs may have changed since this world last cached
	if world.shapeGeneration ~= shape_cache_generation then
		world.shapeSystems = {}
		world.shapeGeneration = shape_cache_generation
	end
	local shapeSystems = world.shapeSystems

	-- Change Entities
	for i = 1, #e2c do
		local entity = e2c[i]
		local isNew = entities[entity] == nil

		-- Add if needed
		if isNew then
			local index = #entities + 1
			entities[entity] = index
			entities[index] = entity
		else
			-- Re-filter existing entity: drop shape cache for this instance
			entity.__shape = nil
		end

		local shape = entity.__shape
		local matched = shape and shapeSystems[shape]

		if isNew and shape then
			if not matched then
				matched = resolveShape(world, entity)
				shapeSystems[shape] = matched
			end

			if shape_validation then
				validateShapeMatch(world, entity, matched)
			end

			for j = 1, #matched do
				addToSystem(matched[j], entity)
			end
		else
			-- Full scan (no shape, or re-adding existing entity)
			for j = 1, #systems do
				local system = systems[j]
				local index = system.indices[entity]
				local filter = system.filter
				if filter and filter(system, entity) then
					if not index then
						addToSystem(system, entity)
					end
				elseif index then
					removeFromSystem(system, entity)
				end
			end
		end
		e2c[i] = nil
	end

	-- Remove Entities
	for i = 1, #e2r do
		local entity = e2r[i]
		e2r[i] = nil
		local listIndex = entities[entity]
		if listIndex then
			-- Remove Entity from world state
			local lastEntity = entities[#entities]
			entities[lastEntity] = listIndex
			entities[entity] = nil
			entities[listIndex] = lastEntity
			entities[#entities] = nil

			local shape = entity.__shape
			local matched = shape and shapeSystems[shape]
			if matched then
				for j = 1, #matched do
					removeFromSystem(matched[j], entity)
				end
			else
				for j = 1, #systems do
					removeFromSystem(systems[j], entity)
				end
			end
		end
	end
end

--- Manages Entities and Systems marked for deletion or addition. Call this
-- before modifying Systems and Entities outside of a call to `tiny.update`.
-- Do not call this within a call to `tiny.update`.
function tiny.refresh(world)
	tiny_manageSystems(world)
	tiny_manageEntities(world)
	local systemsOnModify = world.systemsOnModify
	for i = #systemsOnModify, 1, -1 do
		local system = systemsOnModify[i]
		if system.active and system.modified then
			system.onModify(system, 0)
			system.modified = false
		end
	end
end

--- Updates the World by dt (delta time). Takes an optional parameter, `filter`,
-- which is a Filter that selects Systems from the World, and updates only those
-- Systems. If `filter` is not supplied, all Systems are updated. Put this
-- function in your main loop.
function tiny.update(world, dt, filter)
	tiny_manageSystems(world)
	tiny_manageEntities(world)

	local speed = world.speed or 1
	if speed <= 0 then
		return
	end
	dt = dt * speed

	-- Call onModify on systems that were modified (reverse order)
	local systemsOnModify = world.systemsOnModify
	for i = #systemsOnModify, 1, -1 do
		local system = systemsOnModify[i]
		if system.active and system.modified then
			system.onModify(system, dt)
		end
	end

	-- preWrap in reverse order
	local systemsPreWrap = world.systemsPreWrap
	for i = #systemsPreWrap, 1, -1 do
		local system = systemsPreWrap[i]
		if system.active and ((not filter) or filter(world, system)) then
			system.preWrap(system, dt)
		end
	end

	-- Update in order
	local systemsUpdate = world.systemsUpdate
	for i = 1, #systemsUpdate do
		local system = systemsUpdate[i]
		if system.active and ((not filter) or filter(world, system)) then
			local update = system.update
			if update then
				local interval = system.interval
				if interval then
					local bufferedTime = (system.bufferedTime or 0) + dt
					while bufferedTime >= interval do
						bufferedTime = bufferedTime - interval
						update(system, interval)
					end
					system.bufferedTime = bufferedTime
				else
					update(system, dt)
				end
			end
			system.modified = false
		end
	end

	-- Also clear modified on onModify-only systems that have no update
	for i = 1, #systemsOnModify do
		systemsOnModify[i].modified = false
	end

	-- postWrap in order
	local systemsPostWrap = world.systemsPostWrap
	for i = 1, #systemsPostWrap do
		local system = systemsPostWrap[i]
		if system.active and ((not filter) or filter(world, system)) then
			system.postWrap(system, dt)
		end
	end
end


--- Updates the World by dt (delta time). Takes an optional parameter, `filter`,
-- which is a Filter that selects Systems from the World, and updates only those
-- Systems. If `filter` is not supplied, all Systems are updated. Put this
-- function in your main loop.
function tiny.fixed_update(world, dt, filter)
	local systemsFixedUpdate = world.systemsFixedUpdate

	for i = 1, #systemsFixedUpdate do
		local system = systemsFixedUpdate[i]
		if system.active and ((not filter) or filter(world, system)) then
			system.fixed_update(system, dt)
			system.modified = false
		end
	end
end


--- Runs `late_update` on Systems after `tiny.update`, in system order. Takes an
-- optional `filter` like `tiny.update`. Applies `world.speed` the same way as
-- `tiny.update` when you pass the same raw `dt`.
function tiny.late_update(world, dt, filter)
	local speed = world.speed or 1
	if speed <= 0 then
		return
	end
	dt = dt * speed

	local systemsLateUpdate = world.systemsLateUpdate

	for i = 1, #systemsLateUpdate do
		local system = systemsLateUpdate[i]
		if system.active and ((not filter) or filter(world, system)) then
			system.late_update(system, dt)
		end
	end
end


--- Removes all Entities and Systems from the World.
function tiny.clear(world)
	tiny.clearEntities(world)
	tiny.clearSystems(world)
end


--- Removes all Entities from the World.
function tiny.clearEntities(world)
	local el = world.entities
	for i = 1, #el do
		tiny_removeEntity(world, el[i])
	end
end

--- Removes all Systems from the World.
function tiny.clearSystems(world)
	local systems = world.systems
	for i = #systems, 1, -1 do
		tiny_removeSystem(world, systems[i])
	end
end

--- Gets number of Entities in the World.
function tiny.getEntityCount(world)
	return #world.entities
end

--- Gets number of Systems in World.
function tiny.getSystemCount(world)
	return #world.systems
end

--- Sets the index of a System in the World, and returns the old index. Changes
-- the order in which they Systems processed, because lower indexed Systems are
-- processed first. Returns the old system.index.
function tiny.setSystemIndex(world, system, index)
	tiny_manageSystems(world)
	local oldIndex = system.index
	local systems = world.systems

	if index < 0 then
		index = tiny.getSystemCount(world) + 1 + index
	end

	tremove(systems, oldIndex)
	tinsert(systems, index, system)

	for i = oldIndex, index, index >= oldIndex and 1 or -1 do
		systems[i].index = i
	end

	rebuildDispatchLists(world)
	world.shapeSystems = {}
	world.shapeGeneration = shape_cache_generation

	return oldIndex
end


---@param enabled boolean
function tiny.setShapeValidation(enabled)
	shape_validation = enabled
end


---Bump the global shape-membership generation. Live worlds drop shapeSystems
---lazily on the next entity manage pass.
function tiny.bumpShapeCache()
	shape_cache_generation = shape_cache_generation + 1
end


---@param world world
---@param component_id string
---@param component_value any|nil
---@param out entity[]|nil Optional out table to avoid allocation
---@return entity[]
function tiny.findEntities(world, component_id, component_value, out)
	local entities = out or {}
	if out then
		for i = #out, 1, -1 do
			out[i] = nil
		end
	end

	local world_entities = world.entities
	for i = 1, #world_entities do
		local entity = world_entities[i]
		if entity[component_id] and (not component_value or entity[component_id] == component_value) then
			entities[#entities + 1] = entity
		end
	end
	return entities
end


---@param world world
---@param component_id string
---@param component_value any|nil
---@return entity|nil
function tiny.findEntity(world, component_id, component_value)
	local world_entities = world.entities
	for i = 1, #world_entities do
		local entity = world_entities[i]
		if entity[component_id] and (not component_value or entity[component_id] == component_value) then
			return entity
		end
	end
	return nil
end


-- Construct world metatable.
worldMetaTable = {
	__index = {
		add = tiny.add,
		addEntity = tiny.addEntity,
		addSystem = tiny.addSystem,
		remove = tiny.remove,
		removeEntity = tiny.removeEntity,
		removeSystem = tiny.removeSystem,
		refresh = tiny.refresh,
		update = tiny.update,
		fixed_update = tiny.fixed_update,
		late_update = tiny.late_update,
		clear = tiny.clear,
		clearEntities = tiny.clearEntities,
		clearSystems = tiny.clearSystems,
		getEntityCount = tiny.getEntityCount,
		getSystemCount = tiny.getSystemCount,
		setSystemIndex = tiny.setSystemIndex,
		findEntities = tiny.findEntities,
		findEntity = tiny.findEntity
	},
	__tostring = function()
		return "<tiny-ecs_World>"
	end
}

return tiny
