return function()
	describe("System transform", function()
		local decore ---@type decore
		local world ---@type world
		local system_transform ---@type system.transform

		before(function()
			decore = require("decore.decore")
			system_transform = require("core.system.transform.system_transform")

			world = decore.world()
			world:add(system_transform.create_system())
		end)

		it("Should init correctly", function()
			local entity = world:add({ transform = { position = vmath.vector3(10, 20, 0) }})
			world:refresh()

			assert(entity.transform.position.x == 10)
			assert(entity.transform.position.y == 20)

			-- Now it works only if we create an entity with decore
			-- How or should we update it?
			--assert(entity.transform.position_z == 0)
		end)

		it("Should trigger transform_event on position change", function()
			local entity = world:add({ transform = { position = vmath.vector3(10, 20, 0) }})
			world:refresh()

			world.command_transform:set_position(entity, 20, 30)
			assert(world.event_bus:get_stash("transform_event"))
			assert(#world.event_bus:get_stash("transform_event") == 1)
			local event = world.event_bus:get_stash("transform_event")[1]
			assert(event.entity == entity)
			assert(event.is_position_changed)
		end)

		it("Should trigger transform_event on scale change", function()
			local entity = world:add({ transform = { scale = vmath.vector3(1, 1, 1) }})
			world:refresh()

			world.command_transform:set_scale(entity, 2, 2)
			assert(world.event_bus:get_stash("transform_event"))
			assert(#world.event_bus:get_stash("transform_event") == 1)
			local event = world.event_bus:get_stash("transform_event")[1]
			assert(event.entity == entity)
			assert(event.is_scale_changed)
		end)

		it("Should trigger transform_event on size change", function()
			local entity = world:add({ transform = { size = vmath.vector3(1, 1, 0) }})
			world:refresh()

			world.command_transform:set_size(entity, 2, 2)
			assert(world.event_bus:get_stash("transform_event"))
			assert(#world.event_bus:get_stash("transform_event") == 1)
			local event = world.event_bus:get_stash("transform_event")[1]
			assert(event.entity == entity)
			assert(event.is_size_changed)
		end)

		it("Should trigger transform_event on rotation change", function()
			local entity = world:add({ transform = { rotation = 0 }})
			world:refresh()

			world.command_transform:set_rotation(entity, 90)
			assert(world.event_bus:get_stash("transform_event"))
			assert(#world.event_bus:get_stash("transform_event") == 1)
			local event = world.event_bus:get_stash("transform_event")[1]
			assert(event.entity == entity)
			assert(event.is_rotation_changed)
		end)
	end)
end
