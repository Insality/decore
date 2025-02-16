local decore = require("decore.decore")

---@class entity
---@field text_game_timer component.text_game_timer|nil

---@class entity.text_game_timer: entity
---@field text_game_timer component.text_game_timer
---@field game_object component.game_object

---@class component.text_game_timer
---@field label_url string
decore.register_component("text_game_timer", {
	label_url = "#label",
})

---@class system.text_game_timer: system
---@field entities entity.text_game_timer[]
---@field create_time number
local M = {}

function M.create_system()
	local system = decore.system(M, "text_game_timer", { "text_game_timer", "game_object" })
	system.create_time = socket.gettime()
	return system
end


---@param entity entity.text_game_timer
function M:onAdd(entity)
	entity.text_game_timer.label_url = hash(entity.text_game_timer.label_url) --[[@as string]]
end


function M:update(dt)
	local current_time = socket.gettime()
	local time_diff = current_time - self.create_time

	for index = 1, #self.entities do
		local entity = self.entities[index]
		local text_game_timer = entity.text_game_timer
		local root_url = entity.game_object.object[text_game_timer.label_url]
		label.set_text(root_url, string.format("%.2f", time_diff))
	end
end


return M
