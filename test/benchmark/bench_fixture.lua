---Shared data set for the decore benchmarks.
---Everything is generated from a fixed seed LCG, so the components, prefabs and
---system filters are byte for byte identical on every branch and every run.

local events = require("event.events")
local decore = require("decore.decore")

local M = {}

M.PACK_ID = "bench"
M.COMPONENT_COUNT = 40
M.PREFAB_COUNT = 60
M.MAX_PREFAB_DEPTH = 3

M.PARENT_PREFAB_ID = "bench_parent"
M.CHILD_PREFAB_ID = "bench_child"

---Present on a few prefabs only, used by the sorted system filter
M.RARE_COMPONENT_ID = "bench_rare"

---Never referenced by any system filter, so adding it changes no membership
M.TAG_COMPONENT_ID = "bench_tag"

local is_registered = false

---@type string[] Prefabs at the deepest point of a parent_prefab_id chain
local deepest_prefab_ids = {}


---Park-Miller LCG. Stays inside double precision, unlike the classic
---1103515245 multiplier, so every platform produces the same sequence.
---@param seed number
---@return fun(max: number): number Integer in [1, max]
function M.new_rng(seed)
	local state = seed % 2147483647
	if state <= 0 then
		state = state + 2147483646
	end

	return function(max)
		state = (state * 16807) % 2147483647
		return (state % max) + 1
	end
end


---@param index number
---@return string
function M.component_id(index)
	return ("c%02d"):format(index)
end


---@param index number
---@return string
function M.prefab_id(index)
	return ("p%02d"):format(index)
end


---@return table<string, any>
local function build_components()
	local components = {
		transform = {
			position_x = 0,
			position_y = 0,
			scale_x = 1,
			scale_y = 1,
			rotation = 0,
		},
		[M.RARE_COMPONENT_ID] = { order = 0 },
		[M.TAG_COMPONENT_ID] = { value = 0 },
	}

	for index = 1, M.COMPONENT_COUNT do
		local component = {
			value = index,
			factor = index * 0.5,
			flag = (index % 2 == 0),
			name = "component_" .. index,
		}

		-- A quarter of the components are nested, so deepcopy has real work to do
		if index % 4 == 0 then
			component.nested = { x = 0, y = 0, list = { 1, 2, 3 } }
		end

		components[M.component_id(index)] = component
	end

	return components
end


---@return table<string, table>
local function build_prefabs()
	local rng = M.new_rng(7)
	local prefabs = {}
	local depths = {}

	for index = 1, M.PREFAB_COUNT do
		local prefab = {
			transform = { position_x = rng(1000), position_y = rng(1000) },
		}

		for _ = 1, 3 + rng(6) do
			prefab[M.component_id(rng(M.COMPONENT_COUNT))] = { value = rng(100) }
		end

		local depth = 0
		if index % 5 == 0 and index > 5 then
			local parent_index = index - 5
			local parent_depth = depths[parent_index] or 0
			if parent_depth + 1 <= M.MAX_PREFAB_DEPTH then
				prefab.parent_prefab_id = M.prefab_id(parent_index)
				depth = parent_depth + 1
			end
		end

		if index % 12 == 0 then
			prefab[M.RARE_COMPONENT_ID] = { order = index }
		end

		depths[index] = depth
		prefabs[M.prefab_id(index)] = prefab
	end

	deepest_prefab_ids = {}
	for index = 1, M.PREFAB_COUNT do
		if depths[index] == M.MAX_PREFAB_DEPTH then
			deepest_prefab_ids[#deepest_prefab_ids + 1] = M.prefab_id(index)
		end
	end

	prefabs[M.CHILD_PREFAB_ID] = {
		transform = { position_x = 10, position_y = 20 },
		c01 = { value = 1 },
		c02 = { value = 2 },
	}

	prefabs[M.PARENT_PREFAB_ID] = {
		transform = { position_x = 100, position_y = 200 },
		c03 = { value = 3 },
		child_instancies = {
			{ prefab_id = M.CHILD_PREFAB_ID, pack_id = M.PACK_ID },
			{ prefab_id = M.CHILD_PREFAB_ID, pack_id = M.PACK_ID },
			{ prefab_id = M.CHILD_PREFAB_ID, pack_id = M.PACK_ID },
		},
	}

	return prefabs
end


---Register the component and prefab packs once. Silences the logger, otherwise
---the default logger prints a trace line per created entity.
function M.register_data()
	if is_registered then
		return
	end
	is_registered = true

	decore.set_logger(nil)
	decore.register_components({
		pack_id = M.PACK_ID,
		components = build_components(),
	})
	decore.register_entities(M.PACK_ID, build_prefabs())
end


---@param rng fun(max: number): number
---@param count number
---@param with_transform boolean
---@return string[]
local function pick_filters(rng, count, with_transform)
	local filters = {}
	local taken = {}

	if with_transform then
		filters[1] = "transform"
		taken["transform"] = true
	end

	while #filters < count do
		local component_id = M.component_id(rng(M.COMPONENT_COUNT))
		if not taken[component_id] then
			taken[component_id] = true
			filters[#filters + 1] = component_id
		end
	end

	return filters
end


---Build a fresh set of systems. A system instance belongs to a single world, so
---this has to be called per world.
---
---The mix mirrors a real project: mostly processing systems, some plain update
---systems, some purely reactive ones with no update callback at all, a couple of
---wrap systems and one sorted system.
---@param count number
---@param seed number|nil
---@return system[]
function M.create_systems(count, seed)
	local rng = M.new_rng(seed or 23)
	local systems = {}

	for index = 1, count do
		local kind = index % 10
		local filters = pick_filters(rng, 1 + rng(2), index % 3 == 0)
		local suffix = ("%d_%d"):format(index, seed or 23)

		if kind >= 1 and kind <= 5 then
			systems[index] = decore.processing_system({
				process = function(self, entity, dt)
					local transform = entity.transform
					if transform then
						transform.position_x = transform.position_x + dt
					end
					self.processed = (self.processed or 0) + 1
				end,
			}, "bench_process_" .. suffix, filters)
		elseif kind == 6 or kind == 7 then
			systems[index] = decore.system({
				update = function(self, dt)
					local entities = self.entities
					local sum = 0
					for entity_index = 1, #entities do
						sum = sum + entities[entity_index].id
					end
					self.sum = sum
				end,
			}, "bench_update_" .. suffix, filters)
		elseif kind == 8 then
			-- No update callback: only reachable cost is add/remove bookkeeping
			systems[index] = decore.system({
				onAdd = function(self, entity)
					self.added = (self.added or 0) + 1
				end,
				onRemove = function(self, entity)
					self.removed = (self.removed or 0) + 1
				end,
			}, "bench_reactive_" .. suffix, filters)
		elseif kind == 9 then
			systems[index] = decore.system({
				preWrap = function(self, dt)
					self.pre = (self.pre or 0) + 1
				end,
				postWrap = function(self, dt)
					self.post = (self.post or 0) + 1
				end,
			}, "bench_wrap_" .. suffix, filters)
		else
			systems[index] = decore.system({
				fixed_update = function(self, dt)
					self.fixed = (self.fixed or 0) + 1
				end,
				late_update = function(self, dt)
					self.late = (self.late or 0) + 1
				end,
			}, "bench_late_" .. suffix, filters)
		end
	end

	if count >= 10 then
		-- Sorted systems resort on every membership change, so keep the filter
		-- rare enough that it does not dominate every other measurement
		systems[#systems + 1] = decore.sorted_processing_system({
			compare = function(self, entity_a, entity_b)
				return entity_a.id < entity_b.id
			end,
			process = function(self, entity, dt)
				self.processed = (self.processed or 0) + 1
			end,
		}, "bench_sorted_" .. (seed or 23), { M.RARE_COMPONENT_ID, "transform" })
	end

	return systems
end


---Every system's entity list has to hold exactly the entities its filter accepts.
---Optimizations that cache system membership can silently under-populate those
---lists, which would make the membership benchmarks look fast for the wrong
---reason, so verify them against a brute force pass.
---@param world world
function M.assert_membership(world)
	local systems = world.systems
	local entities = world.entities

	for index = 1, #systems do
		local system = systems[index]
		local filter = system.filter
		local expected = 0

		if filter then
			for entity_index = 1, #entities do
				if filter(system, entities[entity_index]) then
					expected = expected + 1
				end
			end
		end

		local actual = system.entities and #system.entities or 0
		assert(actual == expected, ("system %s holds %d entities, its filter accepts %d"):format(
			tostring(system.id), actual, expected))
	end
end


---Sum of a counter field across all generated systems of a world. Used by the
---benchmark checks to prove the measured loop actually did something.
---@param world world
---@param field string
---@return number
function M.sum_system_counter(world, field)
	local total = 0
	local systems = world.systems
	for index = 1, #systems do
		total = total + (systems[index][field] or 0)
	end

	return total
end


---@param system_count number
---@param seed number|nil
---@return world
function M.create_world(system_count, seed)
	M.register_data()
	return decore.new_world(unpack(M.create_systems(system_count, seed)))
end


---Prefab ids sitting at the bottom of the deepest parent_prefab_id chains.
---@return string[]
function M.get_deepest_prefab_ids()
	M.register_data()
	return deepest_prefab_ids
end


---The decore system subscribes the world to a global event on world creation, and
---only unsubscribes when its systems are removed. Benchmarks build a lot of
---throwaway worlds, so they have to drop that reference explicitly or every world
---and all of its entities stay alive until the process exits.
---@param world world
function M.destroy_world(world)
	local is_unsubscribed = events.unsubscribe("decore.create_entity", world.addEntity, world)
	assert(is_unsubscribed, "world stayed attached to the global event, later cases would measure a leaking heap")
end


---@param count number
---@param seed number|nil
---@return entity[]
function M.create_entities(count, seed)
	M.register_data()

	local rng = M.new_rng(seed or 101)
	local entities = {}
	for index = 1, count do
		entities[index] = decore.create_prefab(M.prefab_id(rng(M.PREFAB_COUNT)), M.PACK_ID)
	end

	return entities
end


---@param world world
---@param entities entity[]
function M.add_entities(world, entities)
	for index = 1, #entities do
		world:addEntity(entities[index])
	end
	world:refresh()
end


---World with `system_count` systems and `entity_count` entities already resident.
---@param system_count number
---@param entity_count number
---@param seed number|nil
---@return world
---@return entity[]
function M.create_populated_world(system_count, entity_count, seed)
	local world = M.create_world(system_count)
	local entities = M.create_entities(entity_count, seed)
	M.add_entities(world, entities)
	return world, entities
end


return M
