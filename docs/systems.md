# Systems

## Overview

Each system in ECS can be splitted into three sub-systems if needed:
- The system - the main system that contains the logic of the system.
- The system_command - the system that contains the logic of the command over the system. You can think about it as external "API" for the system.
- The system_event - the system that contains the struct of the event that system is throwing. It just take a logic to remove the events from the system at the end of the update cycle.

## System

Let's see on the example of the system transform:

```lua
local ecs = require("decore.ecs")

local transform_command = require("decore.system.transform.transform_command")
local transform_event = require("decore.system.transform.transform_event")

---@class entity
---@field transform component.transform|nil

---@class entity.transform: entity
---@field transform component.transform

---@class entity.transform_command: entity
---@field transform component.transform

---@class component.transform
---@field position_x number
---@field position_y number
---@field position_z number
---@field size_x number
---@field size_y number
---@field size_z number
---@field scale_x number
---@field scale_y number
---@field scale_z number
---@field rotation number
---@field animate_time number|nil
---@field easing userdata|nil

---@class system.transform: system
---@field entities entity.transform[]
local M = {}


---@return system.transform, system.transform_command, system.transform_event
function M.create_system()
	local system = setmetatable(ecs.system(), { __index = M })
	system.filter = ecs.requireAll("transform")

	return system, transform_command.create_system(system), transform_event.create_system()
end


return M
```

Each of system have a description of the component and a system logic. There a main entry point for your system. When you add the system to the world, it can add a several sub-systems to the world.

```lua
local system_transform = require("decore.system.transform.transform")

function init(self)
	self.world = decore.world("main")
	self.world:add(system_transform.create_system()) -- Add the all transform systems
end
```

## System Command

Let's see on the example of the system transform command:

```lua
local ecs = require("decore.ecs")

---@class entity
---@field transform_command component.transform_command|nil

---@class entity.transform_command: entity
---@field transform_command component.transform_command

---@class component.transform_command
---@field entity entity The entity to apply the transform to.
---@field position_x number|nil Position x in pixels.
---@field position_y number|nil Position y in pixels.
---@field position_z number|nil Position z in pixels.
---@field scale_x number|nil Scale x in pixels.
---@field scale_y number|nil Scale y in pixels.
---@field scale_z number|nil Scale z in pixels.
---@field size_x number|nil Size x in pixels.
---@field size_y number|nil Size y in pixels.
---@field size_z number|nil Size z in pixels.
---@field rotation number|nil Rotation around x axis in degrees.
---@field animate_time number|nil If true will animate the transform over time.
---@field easing userdata|nil The easing function to use for the animation.
---@field relative boolean|nil If true, the values are relative to the current values.

---@class system.transform_command: system
---@field entities entity.transform_command[]
local M = {}


---@return system.transform_command
function M.create_system()
	local system = ecs.system()

	system.filter = ecs.requireAny("transform_command")

	return setmetatable(system, { __index = M })
end


---@param entity entity.transform_command
function M:onAdd(entity)
	local command = entity.transform_command
	if command then
		self:process_command(command)
	end

	self.world:removeEntity(entity)
end


---@param command component.transform_command
function M:process_command(command)
	local entity = command.entity --[[@as entity.transform]]
	local t = entity.transform

	local is_position_changed = command.position_x ~= nil or command.position_y ~= nil or command.position_z ~= nil
	t.position_x = command.position_x or t.position_x
	t.position_y = command.position_y or t.position_y
	t.position_z = command.position_z or t.position_z

	local is_scale_changed = command.scale_x ~= nil or command.scale_y ~= nil or command.scale_z ~= nil
	t.scale_x = command.scale_x or t.scale_x
	t.scale_y = command.scale_y or t.scale_y
	t.scale_z = command.scale_z or t.scale_z

	local is_size_changed = command.size_x ~= nil or command.size_y ~= nil or command.size_z ~= nil
	t.size_x = command.size_x or t.size_x
	t.size_y = command.size_y or t.size_y
	t.size_z = command.size_z or t.size_z

	local is_rotation_changed = command.rotation ~= nil
	t.rotation = command.rotation or t.rotation

	local is_any_changed = is_position_changed or is_scale_changed or is_rotation_changed or is_size_changed

	if is_any_changed then
		---@type entity.transform_event
		local transform_event = { transform_event = {
			entity = entity,
			is_position_changed = is_position_changed,
			is_scale_changed = is_scale_changed,
			is_size_changed = is_size_changed,
			is_rotation_changed = is_rotation_changed,
			animate_time = command.animate_time,
			easing = command.easing
		}}

		self.world:addEntity(transform_event)
	end
end


return M
```

Each of command system have a description of the command that it's processing and simple logic to remove the command from the system after processing.

These systems have not update function, since they are processing the command on the add event.

These systems is a place to connect other systems event to handle the logic. For example, we can add a processing command for events like `window_event`, `input_event` etc.

## System Event

Let's see on the example of the system transform event:

```lua
local ecs = require("decore.ecs")

---@class entity
---@field transform_event component.transform_event|nil

---@class entity.transform_event: entity
---@field transform_event component.transform_event

---@class component.transform_event
---@field entity entity The entity that was changed.
---@field is_position_changed boolean If true, the position was changed.
---@field is_scale_changed boolean If true, the scale was changed.
---@field is_rotation_changed boolean If true, the rotation was changed.
---@field is_size_changed boolean If true, the size was changed.
---@field animate_time number|nil If true, the time it took to animate the transform.
---@field easing userdata|nil The easing function used for the animation.

---@class system.transform_event: system
---@field entities entity.transform_event[]
local M = {}


---@return system.transform_event
function M.create_system()
	local system = ecs.system()

	system.filter = ecs.requireAll("transform_event")

	return setmetatable(system, { __index = M })
end


function M:postWrap()
	for index = #self.entities, 1, -1 do
		self.world:removeEntity(self.entities[index])
	end
end


return M
```

Each of event system have a description of the event that it's throwing and simple logic to remove the events from the system at the end of the update cycle.

To create a `transform_event` system you need to create a new entity with the `transform_event` component and add it to the world.

```lua
---@type entity.transform_event
local transform_event = { transform_event = {
	entity = entity,
	is_position_changed = is_position_changed,
	is_scale_changed = is_scale_changed,
	is_size_changed = is_size_changed,
	is_rotation_changed = is_rotation_changed,
	animate_time = command.animate_time,
	easing = command.easing
}}

self.world:addEntity(transform_event)
```

The autocomplete and field checking will help you to create the event correctly. If transform_event is changed, the linter will show you the error.

Usually, these events are created in the `system` or `system_command` system, since the `system` and `system_command` system is the one that changes the entity.
