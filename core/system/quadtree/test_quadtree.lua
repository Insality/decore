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
			local t = entity.transform
			q:insert(entity, t.position_x, t.position_y, t.size_x, t.size_y)

			local counter = 0
			q:get_in_rect(0, 0, 0, 0, function() counter = counter + 1 end)
			print("COUNTER", counter)
			assert(counter == 0)

			counter = 0
			q:get_in_rect(0, 0, 10, 10, function() counter = counter + 1 end)
			assert(counter == 0)

			counter = 0
			q:get_in_rect(0, 0, 20, 20, function() counter = counter + 1 end)
			assert(counter == 1)

			counter = 0
			q:get_in_rect(0, 0, 30, 30, function() counter = counter + 1 end)
			assert(counter == 1)
		end)
	end)
end
