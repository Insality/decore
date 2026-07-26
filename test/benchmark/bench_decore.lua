---Decore level benchmarks: prefab instancing, component resolution and the
---parent/child spawning done by the built in decore system.

local decore = require("decore.decore")
local benchmark = require("test.benchmark.benchmark")
local fixture = require("test.benchmark.bench_fixture")

---Values are written here so the JIT cannot drop the measured work as dead code
local sink = nil


benchmark.add({
	group = "entity creation",
	name = "decore.create_prefab.10k",
	ops = 10000,
	setup = function()
		fixture.register_data()
		local rng = fixture.new_rng(101)
		local prefab_ids = {}
		for index = 1, 10000 do
			prefab_ids[index] = fixture.prefab_id(rng(fixture.PREFAB_COUNT))
		end
		return { prefab_ids = prefab_ids }
	end,
	run = function(ctx)
		local prefab_ids = ctx.prefab_ids
		local last = nil
		for index = 1, #prefab_ids do
			last = decore.create_prefab(prefab_ids[index], fixture.PACK_ID)
		end
		ctx.last = last
		sink = last
	end,
	check = function(ctx)
		assert(ctx.last.id, "entity has no id")
		assert(ctx.last.transform, "prefab components were not applied")
	end,
})


---Prefabs at the bottom of a parent_prefab_id chain: instancing one has to walk
---and merge the whole inheritance chain.
benchmark.add({
	group = "entity creation",
	name = "decore.create_prefab.deep.10k",
	ops = 10000,
	setup = function()
		local deepest = fixture.get_deepest_prefab_ids()
		local prefab_ids = {}
		for index = 1, 10000 do
			prefab_ids[index] = deepest[(index % #deepest) + 1]
		end
		return { prefab_ids = prefab_ids }
	end,
	run = function(ctx)
		local prefab_ids = ctx.prefab_ids
		local last = nil
		for index = 1, #prefab_ids do
			last = decore.create_prefab(prefab_ids[index], fixture.PACK_ID)
		end
		ctx.last = last
		sink = last
	end,
	check = function(ctx)
		assert(ctx.last.parent_prefab_id, "the deepest prefabs should inherit")
		assert(ctx.last.transform, "prefab components were not applied")
	end,
})


---No prefab involved: components are merged straight onto a fresh entity.
benchmark.add({
	group = "entity creation",
	name = "decore.create.raw_components.10k",
	ops = 10000,
	setup = function()
		fixture.register_data()
		return {
			components = {
				transform = { position_x = 10, position_y = 20 },
				c01 = { value = 1 },
				c04 = { value = 4 },
				c07 = { value = 7 },
				c12 = { value = 12 },
				c20 = { value = 20 },
			},
		}
	end,
	run = function(ctx)
		local components = ctx.components
		local last = nil
		for _ = 1, 10000 do
			last = decore.create(components)
		end
		ctx.last = last
		sink = last
	end,
	check = function(ctx)
		assert(ctx.last.c20, "components were not applied")
		assert(ctx.last.transform.position_x == 10, "component data was not merged")
	end,
})


benchmark.add({
	group = "entity creation",
	name = "decore.create_component.40k",
	ops = 40000,
	setup = function()
		fixture.register_data()
		local component_ids = {}
		for index = 1, fixture.COMPONENT_COUNT do
			component_ids[index] = fixture.component_id(index)
		end
		return { component_ids = component_ids }
	end,
	run = function(ctx)
		local component_ids = ctx.component_ids
		local last = nil
		for _ = 1, 1000 do
			for index = 1, #component_ids do
				last = decore.create_component(component_ids[index])
			end
		end
		ctx.last = last
		sink = last
	end,
	check = function(ctx)
		assert(ctx.last.name, "component was created empty")
	end,
})


benchmark.add({
	group = "entity creation",
	name = "decore.apply_component.10k",
	ops = 10000,
	setup = function()
		return { entities = fixture.create_entities(10000, 202) }
	end,
	run = function(ctx)
		local entities = ctx.entities
		for index = 1, #entities do
			decore.apply_component(entities[index], fixture.TAG_COMPONENT_ID)
		end
	end,
	check = function(ctx)
		assert(ctx.entities[1][fixture.TAG_COMPONENT_ID], "component was not applied")
	end,
})


---Parents declare child_instancies, and the decore system instances them on add.
---Children are queued during the first refresh, so a second pass is needed.
benchmark.add({
	group = "entity creation",
	name = "decore.spawn_children.1k_parents",
	ops = 4000,
	setup = function()
		local world = fixture.create_world(60)
		local parents = {}
		for index = 1, 1000 do
			parents[index] = decore.create_prefab(fixture.PARENT_PREFAB_ID, fixture.PACK_ID)
		end
		return { world = world, parents = parents }
	end,
	run = function(ctx)
		local world = ctx.world
		local parents = ctx.parents
		for index = 1, #parents do
			world:addEntity(parents[index])
		end
		world:refresh()
		world:refresh()
	end,
	check = function(ctx)
		assert(ctx.world:getEntityCount() == 4000, "children were not spawned")
		assert(#ctx.parents[1].children_ids == 3, "parent is missing children ids")
		fixture.assert_membership(ctx.world)
	end,
	teardown = function(ctx)
		fixture.destroy_world(ctx.world)
	end,
})
