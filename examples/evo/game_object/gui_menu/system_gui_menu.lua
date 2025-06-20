local evolved = require("decore.evolved")
local druid = require("druid.druid")
local components = require("examples.evo.components")

local gui_menu_widget = require("examples.evo.game_object.gui_menu.gui_menu")

---@class components
---@field gui_menu evolved.id
---@field gui_menu_widget evolved.id

components.gui_menu = evolved.builder():name("gui_menu"):tag():spawn()
components.gui_menu_widget = evolved.builder():name("gui_menu_widget"):tag():spawn()

return evolved.builder()
	:name("system.gui_menu")
	:include(components.gui_menu, components.root_url)
	:exclude(components.gui_menu_widget)
	:execute(function(chunk, entity_list, entity_count)
		local root_url = chunk:components(components.root_url)

		for index = 1, entity_count do
			local gui_url = msg.url(nil, root_url[index], "gui_menu")
			local widget = druid.get_widget(gui_menu_widget, gui_url)
			widget.on_play:subscribe(function()
				print("play!")
			end)
			evolved.set(entity_list[index], components.gui_menu_widget, widget)
		end
	end)
	:spawn()
