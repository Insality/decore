local decore = require("decore.decore")

---@class entity
---@field score_counter boolean|nil

---@class entity.score_counter: entity
---@field score_counter boolean
---@field game_object component.game_object
decore.register_component("score_counter", false)

---@class system.score_counter: system
---@field entities entity.score_counter[]
local M = {}


---@return system.score_counter
function M.create_system()
	return decore.system(M, "score_counter", { "score_counter", "game_object" })
end


function M:postWrap()
	self.world.event_bus:process("score_plus", self.process_score_plus, self)
end


function M:process_score_plus()
	for index = 1, #self.entities do
		msg.post(self.entities[index].game_object.root, "score_plus")
	end
end


return M
