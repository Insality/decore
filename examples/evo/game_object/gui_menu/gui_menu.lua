local event = require("event.event")
local panthera = require("panthera.panthera")
local animation = require("examples.evo.game_object.gui_menu.gui_menu_panthera")

---@class widget.gui_menu: druid.widget
local M = {}


function M:init()
	self.on_play = event.create()
	self.on_settings = event.create()

	self.button = self.druid:new_button("root", self.on_play)

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())

	panthera.play(self.animation, "appear", panthera.OPTIONS_LOOP)
end


function M:_on_play()
	panthera.play(self.animation, "disappear", {
		callback = function(event_id)
			self.on_play:trigger()
		end
	})
end


function M:play_anim(anim_id)
	panthera.play(self.animation, anim_id, {
		is_skip_init = true,
	})
end


return M
