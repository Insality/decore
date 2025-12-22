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
			assert(world.event_bus ~= nil)
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
			local events = world.event_bus:get_events("on_message")
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
