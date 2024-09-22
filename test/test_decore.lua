return function()
	describe("Decore", function()
		---@type decore
		local decore = {}

		before(function()
			decore = require("decore.decore")
			decore.unload_all()
		end)

		it("Should init correclty", function()
			decore.register_components("/resources/components.json")
			decore.register_entities("/resources/entities.json")

			local component = decore.create_component("transform")
			assert(component.position_x == 0)
			assert(component.position_y == 0)
			assert(component.rotation == 0)

			local entity = decore.create_entity("player")
			assert(entity)
			assert(entity.transform.position_x == 0)
			assert(entity.transform.position_x == 0)
			assert(entity.game_object.factory_url == "/system/spawner#player")
		end)
	end)
end
