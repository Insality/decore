---@class world
---@field command_debug_draw command.debug_draw

---@class command.debug_draw
---@field debug_draw system.debug_draw
local M = {}


---@return command.debug_draw
function M.create(debug_draw)
	return setmetatable({ debug_draw = debug_draw }, { __index = M })
end


function M:draw_rectangle(x, y, width, height, color)
	self.debug_draw:draw_rectangle(x, y, width, height, color)
end

function M:draw_line(x1, y1, x2, y2, color)
	self.debug_draw:draw_line(x1, y1, x2, y2, color)
end


function M:draw_text(x, y, text)
	self.debug_draw:draw_text(x, y, text)
end


return M
