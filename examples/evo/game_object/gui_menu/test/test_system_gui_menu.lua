return function()
	describe("System gui_menu", function()
		local decore ---@type decore
		local world ---@type world

		before(function()
			decore = require("decore.decore")

			world = decore.world()
			world:add(require("system.transform.system_transform").create_system())
			world:add(require("system.game_object.system_game_object").create_system())
			world:add(require("entity.gui_menu.system_gui_menu").create_system())
		end)

		it("Should init entities", function()
			local entity = world:addEntity(decore.create_entity(nil, nil, {
				transform = {},
				game_object = {
					factory_url = "/go#entity_gui_menu",
					is_factory = true
				},
				gui_menu = {}
			}))
			world:refresh()

			-- Add assertions for your system here
			assert(entity.gui_menu ~= nil)
			assert(entity.gui_menu.on_play ~= nil)

			-- On Button click should trigger event
			local node_button_play = entity.gui_menu.widget:get_node("button_play")
			assert(node_button_play ~= nil)

			-- Seems widget tests should be in gui file designed for this test with templates
			--local widget = entity.gui_menu.widget
			--widget.druid:on_input(hash("touch"), {
			--	pressed = true,
			--	x = x,
			--	y = y,
			--})
		end)
	end)
end
