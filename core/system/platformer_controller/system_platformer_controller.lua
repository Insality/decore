local decore = require("decore.decore")

---@class entity
---@field platformer_controller component.platformer_controller|nil

---@class entity.platformer_controller: entity
---@field platformer_controller component.platformer_controller
---@field physics component.physics

---@class component.platformer_controller
---@field direction_x number
---@field direction_y number
decore.register_component("platformer_controller", {
	direction_x = 0,
	direction_y = 0,
})

---@class system.platformer_controller: system
---@field entities entity.platformer_controller[]
---@field input_keys table<hash, boolean>
local M = {}

local KEY_A = hash("key_a")
local KEY_D = hash("key_d")
local KEY_LEFT = hash("key_left")
local KEY_RIGHT = hash("key_right")
local ACTION_ID_TO_SIDE = {
	[KEY_A] = { x = -1 },
	[KEY_D] = { x = 1 },
	[KEY_LEFT] = { x = -1 },
	[KEY_RIGHT] = { x = 1 },
}
local ACTION_JUMP = hash("key_space")

---@static
---@return system.platformer_controller
function M.create_system()
	local system = decore.processing_system(M, "platformer_controller", { "platformer_controller", "platformer_physics" })
	system.input_keys = {}
	return system
end

function M:postWrap()
	self.world.event_bus:process("input_event", self.process_input_event, self)
end


---@param input_event system.input.event
function M:process_input_event(input_event)
	local action_id = input_event.action_id
	local side = ACTION_ID_TO_SIDE[action_id]
	if side or action_id == ACTION_JUMP then
		for index = 1, #self.entities do
			self:apply_input_event(self.entities[index], input_event)
		end
	end
end


---@param entity entity.platformer_controller
---@param input_event system.input.event
function M:apply_input_event(entity, input_event)
	local action_id = input_event.action_id
	if not action_id then
		return
	end

	local action = input_event
	local platformer_controller = entity.platformer_controller

	local side = ACTION_ID_TO_SIDE[action_id]
	if action.pressed and side then
		self.input_keys[action_id] = true
	end
	if action.released and side then
		self.input_keys[action_id] = nil
	end

	do -- direction_x
		platformer_controller.direction_x = 0
		if self.input_keys[KEY_A] or self.input_keys[KEY_LEFT] then
			platformer_controller.direction_x = platformer_controller.direction_x - 1
		end
		if self.input_keys[KEY_D] or self.input_keys[KEY_RIGHT] then
			platformer_controller.direction_x = platformer_controller.direction_x + 1
		end
	end

	if action_id == ACTION_JUMP and action.pressed then
		self.world.command_platformer_physics:jump(entity)
	end
end


---@param entity entity.platformer_controller
---@param dt number
function M:process(entity, dt)
	local platformer_controller = entity.platformer_controller
	self.world.command_platformer_physics:move_vertical(entity, platformer_controller.direction_x)
	self.world.command_platformer_physics:move_horizontal(entity, platformer_controller.direction_y)
end


return M
