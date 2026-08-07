---@diagnostic disable: undefined-field

return function()
	describe("Decore", function()
		local decore ---@type decore
		local world ---@type world
		local decore_data

		before(function()
			decore = require("decore.decore")
			decore_data = require("decore.internal.decore_data")
			decore_data.clear()
			world = decore.new_world()
		end)

		after(function()
			decore_data.clear()
		end)

		it("Should create world with default systems", function()
			assert(world ~= nil)
			assert(world.event ~= nil)
			assert(world.event_bus == world.event) -- deprecated alias
			assert(#world.systems >= 2)
		end)

		it("Should register and create component", function()
			decore.register_component("health", { value = 100, max = 100 })
			local component = decore.create_component("health")
			assert(component ~= nil)
			assert(component.value == 100)
			assert(component.max == 100)
		end)

		it("Should register component with custom pack_id", function()
			decore.register_component("mana", { value = 50 }, "custom_pack")
			local component_1 = decore.create_component("mana")
			assert(component_1 ~= nil)
			assert(component_1.value == 50)

			local component_2 = decore.create_component("mana", "custom_pack")
			assert(component_2 ~= nil)
			assert(component_2.value == 50)

			decore.register_component("mana", { value = 100 }, "custom_pack2")
			local component_3 = decore.create_component("mana")
			assert(component_3 ~= nil)
			assert(component_3.value == 100)

			local component_4 = decore.create_component("mana", "custom_pack")
			assert(component_4 ~= nil)
			assert(component_4.value == 50)
		end)

		it("Should return nil for non-existent component", function()
			local component = decore.create_component("non_existent")
			assert(component ~= nil)
			assert(type(component) == "table")
		end)

		it("Should check if component is registered", function()
			assert(decore_data.is_component_registered("non_existent") == false)
			decore.register_component("test_component", { value = 100 })
			assert(decore_data.is_component_registered("test_component") == true)
			assert(decore_data.is_component_registered("test_component", "decore") == true)
			assert(decore_data.is_component_registered("test_component", "other_pack") == false)
		end)

		it("Should check if component is registered with custom pack", function()
			decore.register_component("custom_component", { value = 50 }, "custom_pack")
			assert(decore_data.is_component_registered("custom_component") == true)
			assert(decore_data.is_component_registered("custom_component", "custom_pack") == true)
			assert(decore_data.is_component_registered("custom_component", "other_pack") == false)
		end)

		it("Should register component with nil data as true", function()
			decore.register_component("flag_component", nil)
			assert(decore_data.is_component_registered("flag_component") == true)
			local component = decore.create_component("flag_component")
			assert(component == true)
		end)

		it("Should register component with nil data as true", function()
			decore.register_component("empty_component", nil)
			assert(decore_data.is_component_registered("empty_component") == true)
			local component = decore.create_component("empty_component")
			assert(component == true)
		end)

		it("Should register components pack", function()
			local components_data = {
				pack_id = "test_pack",
				components = {
					health = { value = 100 },
					mana = { value = 50 }
				}
			}
			local result = decore.register_components(components_data)
			assert(result == true)

			local health = decore.create_component("health", "test_pack")
			local mana = decore.create_component("mana", "test_pack")
			assert(health.value == 100)
			assert(mana.value == 50)
		end)

		it("Should not register duplicate components pack", function()
			local components_data = {
				pack_id = "duplicate_pack",
				components = {
					health = { value = 100 }
				}
			}
			local result1 = decore.register_components(components_data)
			local result2 = decore.register_components(components_data)
			assert(result1 == true)
			assert(result2 == false)
		end)

		it("Should unregister components pack", function()
			decore.register_component("temp", { value = 1 }, "temp_pack")
			local component = decore.create_component("temp", "temp_pack")
			assert(component.value == 1)

			decore.unregister_components("temp_pack")
			local component_after = decore.create_component("temp", "temp_pack")
			assert(component_after.value == nil)
		end)

		it("Should create entity with components", function()
			decore.register_component("health", { value = 100 })
			local entity = decore.create({
				health = { value = 50 }
			})
			assert(entity ~= nil)
			assert(entity.id ~= nil)
			assert(entity.health ~= nil)
			assert(entity.health.value == 50)
		end)

		it("Should create empty entity", function()
			local entity = decore.create({})
			assert(entity ~= nil)
			assert(entity.id ~= nil)
		end)

		it("Should register and create entity from prefab", function()
			decore.register_component("health", { value = 100 })
			decore.register_entity("player", {
				health = { value = 100 },
				name = "Player"
			})
			local entity = decore.create_prefab("player")
			assert(entity ~= nil)
			assert(entity.id ~= nil)
			assert(entity.health.value == 100)
			assert(entity.name == "Player")
			assert(entity.prefab_id == "player")
		end)

		it("Should share nested prefab tables by reference across instances", function()
			local nested = { x = 1, y = 2 }
			decore.register_component("transform", {})
			decore.register_entity("node", {
				transform = { position = nested }
			})

			local a = decore.create_prefab("node")
			local b = decore.create_prefab("node")

			assert(a.transform ~= b.transform)
			assert(a.transform.position == nested)
			assert(b.transform.position == nested)
			assert(a.transform.position == b.transform.position)
		end)

		it("Should deepcopy metatable components so nested plain tables are not shared", function()
			local MT = {}
			local function make_board()
				local on_cancel = { [0] = 0 }
				local cancellation = { is_cancelled = false, on_cancel = on_cancel }
				return setmetatable({
					state = "pending",
					cancellation = cancellation,
					on_cancel = on_cancel,
				}, MT)
			end

			decore.register_component("board", make_board())
			decore.register_entity("with_board", {
				board = make_board(),
			})

			local a = decore.create_prefab("with_board")
			local b = decore.create_prefab("with_board")

			assert(getmetatable(a.board) == MT)
			assert(getmetatable(b.board) == MT)
			assert(a.board ~= b.board)
			assert(a.board.cancellation ~= b.board.cancellation)
			-- Internal aliases must be preserved (promise.on_cancel == promise.cancellation.on_cancel)
			assert(a.board.on_cancel == a.board.cancellation.on_cancel)
			assert(b.board.on_cancel == b.board.cancellation.on_cancel)
			assert(a.board.cancellation.is_cancelled == false)
			assert(b.board.cancellation.is_cancelled == false)

			a.board.cancellation.is_cancelled = true
			assert(b.board.cancellation.is_cancelled == false)
		end)

		it("Should not leak nested override into prefab data or other instances", function()
			local registered_nested = { x = 1, y = 2 }
			decore.register_component("transform", {})
			decore.register_entity("node", {
				transform = { position = registered_nested }
			})

			local a = decore.create_prefab("node", nil, {
				transform = { position = { x = 5 } }
			})
			local b = decore.create_prefab("node")

			assert(a.transform.position.x == 5)
			assert(a.transform.position.y == 2) -- untouched field is kept
			assert(b.transform.position.x == 1) -- other instance is not affected
			assert(registered_nested.x == 1) -- registered prefab data is not mutated
			assert(a.transform.position ~= registered_nested) -- copy-on-write on the written path
		end)

		it("Should copy-on-write every level of an overridden nested path", function()
			decore.register_component("state", {})
			decore.register_entity("deep", {
				state = { a = { b = { c = 1, keep = true } } }
			})

			local a = decore.create_prefab("deep", nil, {
				state = { a = { b = { c = 9 } } }
			})
			local b = decore.create_prefab("deep")

			assert(a.state.a.b.c == 9)
			assert(a.state.a.b.keep == true)
			assert(b.state.a.b.c == 1)
		end)

		it("Should not leak child prefab override into parent prefab template", function()
			decore.register_component("transform", {})
			decore.register_entity("base", {
				transform = { position = { x = 1 } }
			})
			decore.register_entity("derived", {
				parent_prefab_id = "base",
				transform = { position = { x = 5 } }
			})

			local derived = decore.create_prefab("derived")
			local base = decore.create_prefab("base")

			assert(derived.transform.position.x == 5)
			assert(base.transform.position.x == 1)
		end)

		it("Should replace scalar component default with table data", function()
			decore.register_component("hp", 100)
			decore.register_component("flag", false)

			local entity = decore.create({
				hp = { value = 1 },
				flag = { enabled = true }
			})

			assert(entity.hp.value == 1)
			assert(entity.flag.enabled == true)
		end)

		it("Should copy each component object independently", function()
			local MT = {}
			local shared = setmetatable({ value = 1 }, MT)

			decore.register_component("first", {})
			decore.register_component("second", {})
			decore.register_entity("holder", {
				first = shared,
				second = shared
			})

			local a = decore.create_prefab("holder")
			local b = decore.create_prefab("holder")

			-- Identity is preserved inside one object, not between components
			assert(a.first ~= a.second)
			assert(a.first ~= b.first)
			assert(a.first ~= shared)
			assert(getmetatable(a.first) == MT)
			assert(a.first.value == 1 and a.second.value == 1)
		end)

		it("Should keep an object passed by the caller as is", function()
			local MT = {}
			local object = setmetatable({ value = 1 }, MT)

			decore.register_component("test", {})
			decore.register_entity("holder", {})

			-- The caller still holds the object and may have subscribed to it already
			local from_prefab = decore.create_prefab("holder", nil, { test = object })
			assert(from_prefab.test == object)

			local from_create = decore.create({ test = object })
			assert(from_create.test == object)

			local applied = decore.apply_component(decore.create({}), "test", object)
			assert(applied.test == object)

			-- Two entities given the same object share it: that is the caller's choice
			assert(from_prefab.test == from_create.test)
		end)

		it("Should copy a prefab object even when the caller overrides it", function()
			local MT = {}
			local prototype = setmetatable({ value = 1 }, MT)
			local passed = setmetatable({ value = 2 }, MT)

			decore.register_component("test", {})
			decore.register_entity("holder", { test = prototype })

			local default = decore.create_prefab("holder")
			assert(default.test ~= prototype) -- prototype is materialized, not shared
			assert(default.test.value == 1)

			local overridden = decore.create_prefab("holder", nil, { test = passed })
			assert(overridden.test == passed) -- caller value wins and is not copied
		end)

		it("Should keep aliases inside one object", function()
			local MT = {}
			local inner = { count = 0 }
			local object = setmetatable({ direct = inner, wrapper = { inner = inner } }, MT)

			decore.register_component("linked", {})
			decore.register_entity("linked_holder", { linked = object })

			local a = decore.create_prefab("linked_holder")
			local b = decore.create_prefab("linked_holder")

			assert(a.linked.direct == a.linked.wrapper.inner)
			assert(a.linked.direct ~= b.linked.direct)

			a.linked.direct.count = 5
			assert(a.linked.wrapper.inner.count == 5)
			assert(b.linked.direct.count == 0)
			assert(inner.count == 0)
		end)

		it("Should deepcopy object nested inside a plain component", function()
			local MT = {}
			decore.register_component("wrapper", {})
			decore.register_entity("wrapped", {
				wrapper = {
					object = setmetatable({ value = 1 }, MT),
					plain = { value = 1 }
				}
			})

			local a = decore.create_prefab("wrapped")
			local b = decore.create_prefab("wrapped")

			assert(a.wrapper.object ~= b.wrapper.object)
			assert(getmetatable(a.wrapper.object) == MT)
			assert(a.wrapper.plain == b.wrapper.plain) -- plain nested table stays shared
		end)

		it("Should create prefab with additional components", function()
			decore.register_component("health", { value = 100 })
			decore.register_entity("player", {
				health = { value = 100 }
			})
			local entity = decore.create_prefab("player", nil, {
				health = { value = 50 }
			})
			assert(entity.health.value == 50)
		end)

		it("Should register entities pack", function()
			decore.register_component("health", { value = 100 })
			decore.register_entities("game", {
				player = { health = { value = 100 } },
				enemy = { health = { value = 50 } }
			})
			local player = decore.create_prefab("player", "game")
			local enemy = decore.create_prefab("enemy", "game")
			assert(player.health.value == 100)
			assert(enemy.health.value == 50)
		end)

		it("Should unregister entities pack", function()
			decore.register_entity("temp_entity", {}, "temp_pack")
			local entity = decore.create_prefab("temp_entity", "temp_pack")
			assert(entity ~= nil)

			decore.unregister_entities("temp_pack")
			local entity_after = decore.create_prefab("temp_entity", "temp_pack")
			assert(entity_after.prefab_id == nil)
		end)

		it("Should apply component to entity", function()
			decore.register_component("health", { value = 100 })
			local entity = decore.create({})
			decore.apply_component(entity, "health", { value = 75 })
			assert(entity.health ~= nil)
			assert(entity.health.value == 75)
		end)

		it("Should merge component data when applying", function()
			decore.register_component("health", { value = 100, max = 100 })
			local entity = decore.create({})
			decore.apply_component(entity, "health", { value = 50 })
			assert(entity.health.value == 50)
			assert(entity.health.max == 100)
		end)

		it("Should apply multiple components", function()
			decore.register_component("health", { value = 100 })
			decore.register_component("mana", { value = 50 })
			local entity = decore.create({})
			decore.apply_components(entity, {
				health = { value = 75 },
				mana = { value = 25 }
			})
			assert(entity.health.value == 75)
			assert(entity.mana.value == 25)
		end)

		it("Should find entities by component", function()
			decore.register_component("health", { value = 100 })
			local entity1 = decore.create({ health = { value = 100 }, name = "Entity1" })
			local entity2 = decore.create({ health = { value = 50 }, name = "Entity2" })
			local entity3 = decore.create({ mana = { value = 50 } })

			world:addEntity(entity1)
			world:addEntity(entity2)
			world:addEntity(entity3)
			world:refresh()

			local entities_with_health = decore.find_entities(world, "health")
			assert(#entities_with_health == 2)

			local entities_with_name = decore.find_entities(world, "name", "Entity1")
			assert(#entities_with_name == 1)
			assert(entities_with_name[1].name == "Entity1")
		end)

		it("Should get entity by id", function()
			local entity = decore.create({ name = "Test" })
			world:addEntity(entity)
			world:refresh()

			local found = decore.get_entity_by_id(world, entity.id)
			assert(found ~= nil)
			assert(found.id == entity.id)
			assert(found.name == "Test")
			assert(world.id_to_entity[entity.id] == entity)
		end)

		it("Should remove component and clear shape token", function()
			decore.register_component("health", { value = 100 })
			local entity = decore.create({ health = { value = 10 } })
			assert(entity.health ~= nil)
			assert(entity.__shape ~= nil)

			decore.remove_component(entity, "health")
			assert(entity.health == nil)
			assert(entity.__shape == nil)
		end)

		it("Should reuse out table in find_entities", function()
			decore.register_component("health", { value = 100 })
			local entity = decore.create({ health = { value = 1 } })
			world:addEntity(entity)
			world:refresh()

			local out = { "stale" }
			local found = decore.find_entities(world, "health", nil, out)
			assert(found == out)
			assert(#found == 1)
			assert(found[1] == entity)
			assert(found[2] == nil)
		end)

		it("Should derive shape when apply_component adds a new key", function()
			decore.register_component("health", { value = 100 })
			decore.register_component("mana", { value = 50 })
			local entity = decore.create({ health = {} })
			local before = entity.__shape
			assert(before ~= nil)

			decore.apply_component(entity, "mana")
			assert(entity.__shape ~= nil)
			assert(entity.__shape ~= before)
		end)

		it("Should create system without filter", function()
			local system_module = {}
			local system = decore.system(system_module, "test_system", nil)
			assert(system ~= nil)
			assert(system.id == "test_system")
		end)

		it("Should create system with filter", function()
			local system_module = {}
			local system = decore.system(system_module, "test_system", "health")
			assert(system ~= nil)
			assert(system.id == "test_system")
			assert(system.filter ~= nil)
		end)

		it("Should create system with multiple filters", function()
			local system_module = {}
			local system = decore.system(system_module, "test_system", { "health", "mana" })
			assert(system ~= nil)
			assert(system.id == "test_system")
			assert(system.filter ~= nil)
		end)

		it("Should create processing system", function()
			local system_module = {}
			local system = decore.processing_system(system_module, "test_processing", "health")
			assert(system ~= nil)
			assert(system.id == "test_processing")
		end)

		it("Should create sorted system", function()
			local system_module = {}
			local system = decore.sorted_system(system_module, "test_sorted", "health")
			assert(system ~= nil)
			assert(system.id == "test_sorted")
		end)

		it("Should create sorted processing system", function()
			local system_module = {}
			local system = decore.sorted_processing_system(system_module, "test_sorted_processing", "health")
			assert(system ~= nil)
			assert(system.id == "test_sorted_processing")
		end)

		it("Should handle on_message", function()
			decore.on_message(world, hash("test_message"), { data = "test" })
			world:update(0)
			local events = world.event:get_events("on_message")
			assert(events ~= nil)
			assert(#events == 1)
			assert(events[1].message_id == hash("test_message"))
			assert(events[1].message.data == "test")
		end)

		it("Should use latest pack when component exists in multiple packs", function()
			decore.register_component("health", { value = 100 }, "pack1")
			decore.register_component("health", { value = 200 }, "pack2")
			local component = decore.create_component("health")
			assert(component.value == 200)
		end)

		it("Should handle prefab with parent_prefab_id", function()
			decore.register_component("health", { value = 100 })
			decore.register_entity("parent", {
				health = { value = 100 },
				name = "Parent"
			})
			decore.register_entity("child", {
				parent_prefab_id = "parent",
				mana = { value = 50 }
			})
			local entity = decore.create_prefab("child")
			assert(entity.health.value == 100)
			assert(entity.name == "Parent")
			assert(entity.mana.value == 50)
		end)

		it("Should clamp values correctly", function()
			assert(decore.clamp(5, 0, 10) == 5)
			assert(decore.clamp(-5, 0, 10) == 0)
			assert(decore.clamp(15, 0, 10) == 10)
			assert(decore.clamp(5, 10, 0) == 5)
		end)

		it("Should handle component with false value", function()
			decore.register_component("flag", false)
			local component = decore.create_component("flag")
			assert(component == false)
		end)

		it("Should handle non-table component data", function()
			decore.register_component("score", 100)
			local component = decore.create_component("score")
			assert(component == 100)
		end)
	end)
end
