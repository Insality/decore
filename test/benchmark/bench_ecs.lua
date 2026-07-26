---ECS level benchmarks: system membership, the update loop and world lookups.
---These are the paths that scale with `entity count x system count`.

local decore = require("decore.decore")
local benchmark = require("test.benchmark.benchmark")
local fixture = require("test.benchmark.bench_fixture")

local DT = 1 / 60

---Values are written here so the JIT cannot drop the measured work as dead code
local sink = nil


---Filtering every entity against every system is the core cost of `addEntity`.
---Sweeping the system count shows how steeply that cost grows.
---@param system_count number
---@param entity_count number
local function add_entities_case(system_count, entity_count)
	benchmark.add({
		group = "membership",
		name = ("world.add_entities.%dsys.%dk"):format(system_count, entity_count / 1000),
		ops = entity_count,
		setup = function()
			return {
				world = fixture.create_world(system_count),
				entities = fixture.create_entities(entity_count),
			}
		end,
		run = function(ctx)
			local world = ctx.world
			local entities = ctx.entities
			for index = 1, #entities do
				world:addEntity(entities[index])
			end
			world:refresh()
		end,
		check = function(ctx)
			assert(ctx.world:getEntityCount() == entity_count, "entities were not added")
		end,
		teardown = function(ctx)
			fixture.destroy_world(ctx.world)
		end,
	})
end

add_entities_case(20, 10000)
add_entities_case(60, 10000)
add_entities_case(120, 10000)


benchmark.add({
	group = "membership",
	name = "world.remove_entities.60sys.10k",
	ops = 10000,
	setup = function()
		local world, entities = fixture.create_populated_world(60, 10000)
		return { world = world, entities = entities }
	end,
	run = function(ctx)
		local world = ctx.world
		local entities = ctx.entities
		for index = 1, #entities do
			world:removeEntity(entities[index])
		end
		world:refresh()
	end,
	check = function(ctx)
		assert(ctx.world:getEntityCount() == 0, "entities were not removed")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


---Re-adding an entity that is already in the world forces a full re-filter,
---because its component set may have changed. The added component is not part of
---any system filter, so this measures the scan alone with no membership churn.
benchmark.add({
	group = "membership",
	name = "world.refilter.60sys.5k",
	ops = 5000,
	setup = function()
		local world, entities = fixture.create_populated_world(60, 5000)
		return { world = world, entities = entities }
	end,
	run = function(ctx)
		local world = ctx.world
		local entities = ctx.entities
		for index = 1, #entities do
			local entity = entities[index]
			decore.apply_component(entity, fixture.TAG_COMPONENT_ID)
			world:addEntity(entity)
		end
		world:refresh()
	end,
	check = function(ctx)
		assert(ctx.world:getEntityCount() == 5000, "entity count changed during re-filter")
		assert(ctx.entities[1][fixture.TAG_COMPONENT_ID] ~= nil, "component was not applied")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


---Steady state gameplay: a fixed pool of entities spawns and despawns every frame
---while the world keeps updating.
benchmark.add({
	group = "membership",
	name = "world.churn.60sys.100f_50in_50out",
	ops = 100 * 50,
	runs = 3,
	setup = function()
		local world, resident = fixture.create_populated_world(60, 2000)
		local pool = fixture.create_entities(100 * 50, 555)

		-- Removal order: oldest first, residents before freshly spawned ones
		local queue = {}
		for index = 1, #resident do
			queue[#queue + 1] = resident[index]
		end
		for index = 1, #pool do
			queue[#queue + 1] = pool[index]
		end

		return { world = world, pool = pool, queue = queue }
	end,
	run = function(ctx)
		local world = ctx.world
		local pool = ctx.pool
		local queue = ctx.queue
		local spawn_index = 0
		local remove_index = 0

		for _ = 1, 100 do
			for _ = 1, 50 do
				spawn_index = spawn_index + 1
				world:addEntity(pool[spawn_index])
			end
			for _ = 1, 50 do
				remove_index = remove_index + 1
				world:removeEntity(queue[remove_index])
			end
			world:update(DT)
		end
	end,
	check = function(ctx)
		assert(ctx.world:getEntityCount() == 2000, "spawn and despawn counts drifted apart")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


---Adding systems to a world that already holds entities rescans every entity.
benchmark.add({
	group = "membership",
	name = "world.add_systems.20sys.10k_resident",
	ops = 20,
	setup = function()
		local world = fixture.create_world(20)
		fixture.add_entities(world, fixture.create_entities(10000))
		return { world = world, systems = fixture.create_systems(20, 991) }
	end,
	run = function(ctx)
		local world = ctx.world
		local systems = ctx.systems
		for index = 1, #systems do
			world:addSystem(systems[index])
		end
		world:refresh()
	end,
	check = function(ctx)
		local total = 0
		for index = 1, #ctx.systems do
			total = total + #ctx.systems[index].entities
		end
		assert(total > 0, "new systems matched no entities")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


---Normal frame cost: every system that has an update callback runs over its own
---entity list.
benchmark.add({
	group = "update loop",
	name = "world.update.60sys.2k.300f",
	ops = 300,
	setup = function()
		local world = fixture.create_populated_world(60, 2000)
		return { world = world }
	end,
	run = function(ctx)
		local world = ctx.world
		for _ = 1, 300 do
			world:update(DT)
		end
	end,
	check = function(ctx)
		assert(fixture.sum_system_counter(ctx.world, "processed") > 0, "no entity was processed")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


---Almost no entities, so this isolates the per-system dispatch overhead of the
---update loop: how much it costs just to walk the system list every frame.
benchmark.add({
	group = "update loop",
	name = "world.update_dispatch.120sys.8ent.1000f",
	ops = 1000,
	setup = function()
		local world = fixture.create_populated_world(120, 8)
		return { world = world }
	end,
	run = function(ctx)
		local world = ctx.world
		for _ = 1, 1000 do
			world:update(DT)
		end
	end,
	check = function(ctx)
		assert(fixture.sum_system_counter(ctx.world, "pre") == 1000 * 12, "preWrap did not run")
		assert(fixture.sum_system_counter(ctx.world, "post") == 1000 * 12, "postWrap did not run")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


---Only one system in ten implements fixed_update/late_update, so these two loops
---spend most of their time skipping systems.
benchmark.add({
	group = "update loop",
	name = "world.fixed_late_update.120sys.2k.1000f",
	ops = 1000,
	setup = function()
		local world = fixture.create_populated_world(120, 2000)
		return { world = world }
	end,
	run = function(ctx)
		local world = ctx.world
		for _ = 1, 1000 do
			world:fixed_update(DT)
			world:late_update(DT)
		end
	end,
	check = function(ctx)
		assert(fixture.sum_system_counter(ctx.world, "fixed") == 1000 * 12, "fixed_update did not run")
		assert(fixture.sum_system_counter(ctx.world, "late") == 1000 * 12, "late_update did not run")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


benchmark.add({
	group = "lookups",
	name = "lookup.get_entity_by_id.10k.2k_calls",
	ops = 2000,
	setup = function()
		local world, entities = fixture.create_populated_world(20, 10000)
		local rng = fixture.new_rng(31)
		local ids = {}
		for index = 1, 2000 do
			ids[index] = entities[rng(#entities)].id
		end
		return { world = world, ids = ids }
	end,
	run = function(ctx)
		local world = ctx.world
		local ids = ctx.ids
		local found = 0
		for index = 1, #ids do
			if decore.get_entity_by_id(world, ids[index]) then
				found = found + 1
			end
		end
		sink = found
	end,
	check = function(ctx)
		assert(decore.get_entity_by_id(ctx.world, ctx.ids[1]) ~= nil, "entity was not found by id")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})


benchmark.add({
	group = "lookups",
	name = "lookup.find_entities.10k.100_calls",
	ops = 100,
	setup = function()
		local world = fixture.create_populated_world(20, 10000)
		return { world = world }
	end,
	run = function(ctx)
		local world = ctx.world
		local total = 0
		for _ = 1, 100 do
			total = total + #decore.find_entities(world, "transform")
		end
		sink = total
	end,
	check = function(ctx)
		assert(#decore.find_entities(ctx.world, "transform") == 10000, "unexpected entity count")
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})
