return function()
	describe("System FSM", function()
		local decore ---@type decore
		local system_fsm ---@type system.fsm
		local world ---@type world

		before(function()
			decore = require("decore.decore")
			system_fsm = require("core.system.fsm.system_fsm")
			world = decore.world()
			world:add(system_fsm.create_system())
		end)

		local get_entity = function()
			return { fsm = {
				state = "idle",
				events = {
					["walk"] = {
						["idle"] = "walk",
					},
					["die"] = {
						["*"] = "dead",
					},
					["idle"] = {
						["walk"] = "idle",
					}
				}
			}}
		end

		it("Should init system", function()
			local entity = world:add(get_entity())
			world:refresh()

			assert(entity.fsm.state == "idle")
		end)

		it("Should transit over states", function()
			local entity = world:add(get_entity())
			world:refresh()

			world.command_fsm:trigger(entity, "walk")
			assert(entity.fsm.state == "walk")
		end)

		it("Should not transit over non existing states", function()
			local entity = world:add(get_entity())
			world:refresh()

			world.command_fsm:trigger(entity, "non_exists")
			assert(entity.fsm.state == "idle")
		end)

		it("Should trigger fsm event on state change", function()
			local entity = world:add(get_entity())
			world:refresh()

			world.command_fsm:trigger(entity, "walk")
			assert(world.event_bus:get_stash("fsm_event"))
			assert(#world.event_bus:get_stash("fsm_event") == 1)
			local event = world.event_bus:get_stash("fsm_event")[1]
			assert(event.entity == entity)
			assert(event.event == "walk")
		end)

		it("Should able to use wildcards in transitions", function()
			local entity = world:add(get_entity())
			world:refresh()

			world.command_fsm:trigger(entity, "die")
			assert(entity.fsm.state == "dead")
		end)
	end)
end
