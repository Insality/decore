---@diagnostic disable: undefined-field

return function()
	describe("System Decore", function()
		local decore ---@type decore
		local world ---@type world

		before(function()
			decore = require("decore.decore")
			world = decore.new_world()
		end)

		local function add_entity_and_refresh(entity)
			world:addEntity(entity)
			world:refresh()
			world:refresh()
		end

		local function remove_entity_and_refresh(entity)
			world:removeEntity(entity)
			world:refresh()
			world:refresh()
		end

		it("Should have decore system in world", function()
			local decore_system = nil
			for _, system in ipairs(world.systems) do
				if system.id == "decore" then
					decore_system = system
					break
				end
			end
			assert(decore_system ~= nil)
			assert(decore_system.decore ~= nil)
			assert(decore_system.id_to_entity ~= nil)
		end)

		it("Should track entities in id_to_entity map", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			local entity = decore.create({ transform = {} })
			add_entity_and_refresh(entity)

			local decore_system = nil
			for _, system in ipairs(world.systems) do
				if system.id == "decore" then
					decore_system = system
					break
				end
			end
			assert(decore_system ~= nil)
			assert(decore_system.id_to_entity[entity.id] ~= nil)
			assert(decore_system.id_to_entity[entity.id] == entity)
		end)

		it("Should remove entity from id_to_entity map on removal", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			local entity = decore.create({ transform = {} })
			add_entity_and_refresh(entity)

			local decore_system = nil
			for _, system in ipairs(world.systems) do
				if system.id == "decore" then
					decore_system = system
					break
				end
			end
			assert(decore_system ~= nil)
			assert(decore_system.id_to_entity[entity.id] ~= nil)

			remove_entity_and_refresh(entity)
			assert(decore_system.id_to_entity[entity.id] == nil)
		end)

		it("Should spawn child entities from child_instancies", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = { position_x = 10, position_y = 20 }
			})

			local parent = decore.create({
				transform = { position_x = 100, position_y = 200 },
				child_instancies = {
					{ prefab_id = "child_prefab" },
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			assert(parent.children_ids ~= nil)
			assert(#parent.children_ids == 2)

			local child1 = decore.get_entity_by_id(world, parent.children_ids[1])
			local child2 = decore.get_entity_by_id(world, parent.children_ids[2])
			assert(child1 ~= nil)
			assert(child2 ~= nil)
			assert(child1 ~= nil and child1.parent_id == parent.id)
			assert(child2 ~= nil and child2.parent_id == parent.id)
		end)

		it("Should apply parent transform to child transform", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = { position_x = 10, position_y = 20, scale_x = 2, scale_y = 2, rotation = 45 }
			})

			local parent = decore.create({
				transform = { position_x = 100, position_y = 200, scale_x = 0.5, scale_y = 0.5, rotation = 90 },
				child_instancies = {
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			local child = decore.get_entity_by_id(world, parent.children_ids[1])
			assert(child ~= nil)
			assert(child ~= nil and child.transform ~= nil)
			assert(child.transform.scale_x == 1.0)
			assert(child.transform.scale_y == 1.0)
			assert(child.transform.rotation == 135)
		end)

		it("Should remove children when parent is removed", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = {}
			})

			local parent = decore.create({
				transform = {},
				child_instancies = {
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			local child_id = parent.children_ids[1]
			local child = decore.get_entity_by_id(world, child_id)
			assert(child ~= nil)

			remove_entity_and_refresh(parent)

			local child_after = decore.get_entity_by_id(world, child_id)
			assert(child_after == nil)
		end)

		it("Should remove entity from parent children_ids on removal", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = {}
			})

			local parent = decore.create({
				transform = {},
				child_instancies = {
					{ prefab_id = "child_prefab" },
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			assert(#parent.children_ids == 2)
			local child_id = parent.children_ids[1]
			local child = decore.get_entity_by_id(world, child_id)
			assert(child ~= nil)

			remove_entity_and_refresh(child)

			assert(#parent.children_ids == 1)
			assert(parent.children_ids[1] ~= child_id)
		end)

		it("Should handle child with custom components", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_component("health", { value = 100 })
			decore.register_entity("child_prefab", {
				transform = {},
				health = { value = 50 }
			})

			local parent = decore.create({
				transform = {},
				child_instancies = {
					{
						prefab_id = "child_prefab",
						components = {
							health = { value = 75 }
						}
					}
				}
			})
			add_entity_and_refresh(parent)

			local child = decore.get_entity_by_id(world, parent.children_ids[1])
			assert(child ~= nil)
			assert(child.health ~= nil)
			assert(child.health.value == 75)
		end)

		it("Should handle tiled_id inheritance", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = {},
				tiled_id = "child"
			})

			local parent = decore.create({
				transform = {},
				tiled_id = "parent",
				child_instancies = {
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			local child = decore.get_entity_by_id(world, parent.children_ids[1])
			assert(child ~= nil)
			assert(child.tiled_id == "parent/child")
		end)

		it("Should handle entity without transform", function()
			decore.register_entity("child_prefab", {})

			local parent = decore.create({
				child_instancies = {
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			assert(parent.children_ids ~= nil)
			assert(#parent.children_ids == 1)
			local child = decore.get_entity_by_id(world, parent.children_ids[1])
			assert(child ~= nil)
		end)

		it("Should handle entity without child_instancies", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			local entity = decore.create({ transform = {} })
			add_entity_and_refresh(entity)

			assert(entity.children_ids == nil)
		end)

		it("Should apply parent transform with rotation", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = { position_x = 10, position_y = 0 }
			})

			local parent = decore.create({
				transform = { position_x = 0, position_y = 0, rotation = 90 },
				child_instancies = {
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			local child = decore.get_entity_by_id(world, parent.children_ids[1])
			assert(child ~= nil)
			assert(child.transform ~= nil)
			assert(math.abs(child.transform.position_x) < 0.01)
			assert(math.abs(child.transform.position_y - 10) < 0.01)
		end)

		it("Should apply parent transform with scale", function()
			decore.register_component("transform", {
				position_x = 0,
				position_y = 0,
				scale_x = 1,
				scale_y = 1,
				rotation = 0
			})
			decore.register_entity("child_prefab", {
				transform = { position_x = 10, position_y = 20 }
			})

			local parent = decore.create({
				transform = { position_x = 100, position_y = 200, scale_x = 2, scale_y = 2 },
				child_instancies = {
					{ prefab_id = "child_prefab" }
				}
			})
			add_entity_and_refresh(parent)

			local child = decore.get_entity_by_id(world, parent.children_ids[1])
			assert(child ~= nil)
			assert(child.transform ~= nil)
			assert(child.transform.position_x == 120)
			assert(child.transform.position_y == 240)
		end)
	end)
end
