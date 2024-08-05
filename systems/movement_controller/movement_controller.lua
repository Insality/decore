local ecs = require("decore.ecs")

local movement_controller_command = require("systems.movement_controller.movement_controller_command")

---@class entity
---@field movement_controller component.movement_controller|nil

---@class entity.movement_controller: entity
---@field movement_controller component.movement_controller

---@class component.movement_controller
---@field speed number
---@field movement_x number
---@field movement_y number

---@class system.movement_controller: system
---@field entities entity.movement_controller[]
local M = {}


---@static
---@return system.movement_controller, system.movement_controller_command
function M.create_system()
	local system = setmetatable(ecs.processingSystem(), { __index = M })
	system.filter = ecs.requireAll("movement_controller")
	system.id = "movement_controller"

	return system, movement_controller_command.create_system(system)
end


function M:process(entity, dt)
	local movement_controller = entity.movement_controller

	local speed = movement_controller.speed
	local movement_x = movement_controller.movement_x
	local movement_y = movement_controller.movement_y

	if movement_x ~= 0 or movement_y ~= 0 then
		---@type component.transform_command
		local transform_command = {
			entity = entity,
		}
		transform_command.position_x = entity.transform.position_x + movement_x * speed * dt
		transform_command.position_y = entity.transform.position_y + movement_y * speed * dt

		self.world:addEntity({ transform_command = transform_command })
	end
end


return M
