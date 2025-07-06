local evolved = require("decore.evolved")
local components = require("decore.components")

---@class components
---@field color evolved.id
---@field color_sprites evolved.id
---@field color_dirty evolved.id

components.color = evolved.builder():name("color"):default(vmath.vector4(1, 1, 1, 1)):spawn()
components.color_dirty = evolved.builder():name("color_dirty"):tag():spawn()
components.color_sprites = evolved.builder():name("color_sprites"):spawn()

return evolved.builder()
	:include(components.color, components.root_url, components.color_dirty)
	:execute(function(chunk, entity_list, entity_count)
		local color = chunk:components(components.color)
		local root_url = chunk:components(components.root_url)

		for index = 1, entity_count do
			local sprite_url = msg.url(nil, root_url[index], "sprite")
			go.set(sprite_url, "color", color[index])
			evolved.remove(entity_list[index], components.color_dirty)
		end
	end)
	:spawn()


