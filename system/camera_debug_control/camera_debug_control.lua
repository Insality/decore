local decore = require("decore.decore")

---@class system.camera_debug_control: system
---@field is_ctrl boolean
local M = {}

local HASH_CMD = hash("key_lsuper")
local HASH_CTRL = hash("key_lctrl")


---@return system.camera_debug_control
function M.create_system()
	local system = decore.system(M, "camera_debug_control")
	system.is_ctrl = false
	system.is_hold = false

	return system
end


function M:postWrap()
	self.world.event_bus:process("input_event", self.process_input_event, self)
end


---@param input_event system.input.event
function M:process_input_event(input_event)
	-- Process mod key
	local action_id = input_event.action_id
	local is_ctrl = (action_id == HASH_CTRL or action_id == HASH_CMD)
	if is_ctrl and input_event.pressed then
		self.is_ctrl = true
	elseif is_ctrl and input_event.released then
		self.is_ctrl = false
	end

	-- process drag camera
	if self.is_ctrl then
		self:process_drag_camera(input_event)
	end
end


---@param input_event system.input.event
function M:process_drag_camera(input_event)
	local action_id = input_event.action_id
	if action_id == hash("touch") then
		if input_event.pressed then
			self.is_hold = true
			self.start_x = input_event.x
			self.start_y = input_event.y
		elseif input_event.released then
			self.is_hold = false
		end
	end

	if self.is_hold and action_id == nil then
		local entity = self.world.command_camera:get_current_camera()
		local zoom = entity.camera.zoom
		local koef = 1 / zoom
		self.world.command_transform:add_position(entity, -input_event.screen_dx * koef, -input_event.screen_dy * koef)
	end

	if self.is_ctrl then
		-- check wheel
		if input_event.action_id == hash("mouse_wheel_down") then
			local entity = self.world.command_camera:get_current_camera()
			--local new_size_x = entity.transform.size_x * 1.1
			--local new_size_y = entity.transform.size_y * 1.1
			--self.world.command_transform:set_size(entity, new_size_x, new_size_y)

			local new_scale_x = entity.transform.scale_x * 1.1
			local new_scale_y = entity.transform.scale_y * 1.1
			self.world.command_transform:set_scale(entity, new_scale_x, new_scale_y)
			self.world.command_transform:set_animate_time(entity, 0.2, go.EASING_OUTSINE)
		end
		if input_event.action_id == hash("mouse_wheel_up") then
			local entity = self.world.command_camera:get_current_camera()
			--local new_size_x = entity.transform.size_x * 0.9
			--local new_size_y = entity.transform.size_y * 0.9
			--self.world.command_transform:set_size(entity, new_size_x, new_size_y)
			local new_scale_x = entity.transform.scale_x * 0.9
			local new_scale_y = entity.transform.scale_y * 0.9
			self.world.command_transform:set_scale(entity, new_scale_x, new_scale_y)
			self.world.command_transform:set_animate_time(entity, 0.2, go.EASING_OUTSINE)
		end
	end
end


return M
