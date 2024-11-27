return function()
	describe("System Quadtree", function()
		local decore --- @type decore
		local world ---@type world
		local system_quadtree ---@type system.quadtree
		local quadtree ---@type quadtree

		before(function()
			decore = require("decore.decore")
			system_quadtree = require("core.system.quadtree.system_quadtree")
			quadtree = require("core.system.quadtree.quadtree")

			world = decore.world()
			world:add(system_quadtree.create_system())
		end)

		it("Quadtree can be created and requested", function()
			local q = quadtree.create(3, 3)
			assert(q)

			local entity = {
				transform = {
					position_x = 10,
					position_y = 20,
					size_x = 10,
					size_y = 10,
				}
			}
			q:insert(entity)

			local entities = q:get_in_rect(0, 0, 0, 0)
			assert(#entities == 0)

			local entities = q:get_in_rect(0, 0, 10, 10)
			assert(#entities == 0)

			local entities = q:get_in_rect(0, 0, 20, 20)
			assert(#entities == 1)

			local entities = q:get_in_rect(0, 0, 30, 30)
			assert(#entities == 1)
		end)
	end)
end
