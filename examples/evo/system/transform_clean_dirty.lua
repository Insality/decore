local evolved = require("decore.evolved")
local components = require("decore.components")

local query = evolved.builder()
	:include(components.position_dirty)
	:spawn()

return evolved.builder()
	:execute(function() evolved.batch_remove(query, components.position_dirty) end)
	:spawn()
