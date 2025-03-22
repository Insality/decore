local decore = require("decore.decore")
local druid = require("druid.druid")

local debug_panel = require("decore.widget.debug_panel.ui_debug_panel")

---@class entity
---@field debug_panel component.debug_panel|nil

---@class entity.debug_panel: entity
---@field debug_panel component.debug_panel

---@class component.debug_panel
---@field widget decore.widget.debug_panel
decore.register_component("debug_panel", {})

---@class system.debug_panel: system
---@field entities entity.debug_panel[]
local M = {}


---@return system.debug_panel
function M.create_system()
	return decore.system(M, "debug_panel", { "debug_panel", "game_object" })
end


function M:onAdd(entity)
	local object = entity.game_object.root
	local widget_url = msg.url(nil, object, "debug_panel")
	entity.widget = druid.get_widget(debug_panel, widget_url)
	entity.widget:set_world(self.world)
end


return M
