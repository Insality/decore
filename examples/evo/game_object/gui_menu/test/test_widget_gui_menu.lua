return function()
	describe("Widget gui_menu", function()
		local helper ---@type druid.helper
		local widget ---@type widget.gui_menu
		local druid ---@type druid.instance

		before(function()
			druid = require("druid.druid").new(vmath.vector3())
			widget = druid:new_widget(require("entity.gui_menu.gui_menu"), "gui_menu")
			helper = require("druid.helper")
		end)

		after(function()
			druid:final()
		end)

		it("Should trigger event on_play", function()
			local event_triggered = false
			widget.on_play:subscribe(function()
				event_triggered = true
			end)

			local button_play = widget:get_node("button_play")
			local position = helper.get_full_position(button_play)

			druid:on_input(hash("touch"), {
				pressed = true,
				x = position.x,
				y = position.y,
			})

			druid:on_input(hash("touch"), {
				released = true,
				x = position.x,
				y = position.y,
			})

			assert(event_triggered)
		end)
	end)
end
