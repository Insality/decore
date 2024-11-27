local palette = require("druid.color")
local decore = require("decore.decore")
local command_debug_draw = require("core.system.debug_draw.command_debug_draw")

---@class entity
---@field debug_draw component.debug_draw|nil

---@class entity.debug_draw: entity
---@field debug_draw component.debug_draw
---@field game_object component.game_object

---@class component.debug_draw
decore.register_component("debug_draw", {})

---@class system.debug_draw: system
---@field buffer table
---@field header table
---@field entities entity.debug_draw[]
---@field is_dirty boolean
local M = {
	--interval = 0.2
}

local DEFAULT_COLOR = palette.hex2vector4("#4F5152")
local SIZE = 1024

---@return system.debug_draw
function M.create_system()
	local system = decore.system(M, "debug_draw", { "debug_draw" })

	system.buffer = {
	buffer = buffer.create(SIZE * SIZE, {{
			name = hash("my_buffer"),
			type = buffer.VALUE_TYPE_UINT8,
			count = 4 -- same as channels
		}}),
		width = SIZE,
		height = SIZE,
		channels = 4,
		premultiply_alpha = true
	}

	system.header = {
		width  = SIZE,
		height = SIZE,
		type   = graphics.TEXTURE_TYPE_2D,
		format = graphics.TEXTURE_FORMAT_RGBA,
	}

	return system
end


function M:onAddToWorld()
	self.is_dirty = false
	self.world.command_debug_draw = command_debug_draw.create(self)
end


---@param x number center
---@param y number center
---@param width number
---@param height number
---@param color vector4
function M:draw_rectangle(x, y, width, height, color)
	local x1, y1 = self:convert_to_texture(x, y)
	color = color or DEFAULT_COLOR

	local x2, y2 = self:convert_to_texture(x + width, y + height)
	width = (x2 - x1)
	height = (y2 - y1)

	drawpixels.rect(self.buffer, x1, y1, width, height, color.x * 255, color.y * 255, color.z * 255, color.w * 255)
	self.is_dirty = true
end


function M:draw_text(x, y, text, color)
	self.is_dirty = true
end


function M:draw_line(x1, y1, x2, y2, color)
	x1, y1 = self:convert_to_texture(x1, y1)
	x2, y2 = self:convert_to_texture(x2, y2)
	color = color or DEFAULT_COLOR
	drawpixels.line(self.buffer, x1, y1, x2, y2, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	self.is_dirty = true
end


function M:update()
	if not self.is_dirty then
		return
	end
	local camera = self.world.command_camera:get_current_camera()
	local sprite_url = msg.url(nil, camera.game_object.root, "sprite")
	local texture = go.get(sprite_url, "texture0")

	resource.set_texture(texture, self.header, self.buffer.buffer)
	drawpixels.fill(self.buffer, 0, 0, 0, 0)
	self.is_dirty = false
end

function M:convert_to_texture(x, y)
	local camera = self.world.command_camera:get_current_camera()
	local scale = camera.transform.scale_x
	local dx = camera.transform.position_x
	local dy = camera.transform.position_y

	-- Adjust zoom and move camera
	x = (x / scale) - (dx / scale) + 1920 / 2
	y = (y / scale) - (dy / scale) + 1080 / 2

	-- World to texture
	local x_koef = 1920 / SIZE
	local y_koef = 1080 / SIZE
	x = x / x_koef
	y = y / y_koef

	return x, y
end


return M
