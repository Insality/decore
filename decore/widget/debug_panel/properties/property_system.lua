---@class widget.property_system: druid.widget
---@field root node
---@field text_name druid.text
local M = {}


function M:init()
	self.root = self:get_node("root")

	self.text_name = self.druid:new_text("text_name")
		:set_text_adjust("scale_then_trim_left", 0.3)

	self.button_inspect = self.druid:new_button("button_inspect")

	self.container = self.druid:new_container(self.root)
	self.container:add_container("text_name")
	self.container:add_container("E_Anchor")
end


function M:set_text(text)
	self.text_name:set_text(text)
	return self
end


return M
