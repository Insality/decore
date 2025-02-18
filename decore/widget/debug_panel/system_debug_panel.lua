local decore = require("decore.decore")
local druid = require("druid.druid")

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
	local widget = druid.get_widget(entity.game_object.root) --[[@as decore.widget.debug_panel]]
	entity.widget = widget

	widget:set_world(self.world)
end


return M
