# Use Cases

This section illustrates practical examples of how to use the Decore module in your Defold game development projects.

## Global world module

Often for convenience, we can create a Lua module file which will be used as a global world module.

```lua
-- /game/world.lua

--- Use this module to get the latest created world instance
---@class world
local M = {}
local METATABLE = { __index = nil }

---@param world world
function M.set_world(world)
	METATABLE.__index = world
end

return setmetatable(M, METATABLE)
```

```lua
-- Game script
local decore = require("decore.decore")
local world = require("game.world")

function init(self)
	self.world = decore.new_world(...)
	-- Set a world after creation to have access to it from any script later
	world.set_world(self.world)
end
```
