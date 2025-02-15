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

local HASH_DRAW_TEXT = hash("draw_text")
local MSG_DRAW_TEXT = {
	text = "",
	position = vmath.vector3(),
}
local DEFAULT_COLOR = palette.hex2vector4("#FF6430")
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
		premultiply_alpha = false
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

	--drawpixels.rect(self.buffer, x1, y1, width, height, color.x * 255, color.y * 255, color.z * 255, color.w * 255)

	x1 = x1 - width / 2
	y1 = y1 - height / 2

	drawpixels.line(self.buffer, x1, y1, x1 + width, y1, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	drawpixels.line(self.buffer, x1 + width, y1, x1 + width, y1 + height, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	drawpixels.line(self.buffer, x1 + width, y1 + height, x1, y1 + height, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	drawpixels.line(self.buffer, x1, y1 + height, x1, y1, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)

	self.is_dirty = true
end


function M:draw_text(x, y, text, color)
	self.is_dirty = true

	local x1, y1 = self.world.command_camera:world_to_screen(x, y)
	MSG_DRAW_TEXT.position.x = x1
	MSG_DRAW_TEXT.position.y = y1
	MSG_DRAW_TEXT.text = text

	-- Still are best way to draw text? I can't find any other way, somehow with label factories? or gui?
	-- Probably GUI also can replace draw pixels to use just nodes? sounds good
	msg.post("@render:", HASH_DRAW_TEXT, MSG_DRAW_TEXT)
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
		if not self.is_cleared then
			self.is_cleared = true
		else
			return
		end
	end

	local camera = self.world.command_camera:get_current_camera()
	if not camera then
		return
	end

	local sprite_url = msg.url(nil, camera.game_object.root, "sprite")
	local texture = go.get(sprite_url, "texture0")

	resource.set_texture(texture, self.header, self.buffer.buffer)

	-- Too slow! how update and clear faster?
	drawpixels.fill(self.buffer, 0, 0, 0, 0)

	if self.is_dirty then
		self.is_cleared = false
	end
	self.is_dirty = false
end

function M:convert_to_texture(x, y)
	local camera = self.world.command_camera:get_current_camera()
	local transform = camera.transform
	local scale = transform.scale_x
	local dx = transform.position_x
	local dy = transform.position_y

	-- Adjust zoom and move camera
	x = (x - dx) / scale + 960
	y = (y - dy) / scale + 540

	-- World to texture
	x = x * SIZE / 1920
	y = y * SIZE / 1080

	return x, y
end


return M
