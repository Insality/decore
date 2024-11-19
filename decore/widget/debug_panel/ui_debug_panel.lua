local decore_data = require("decore.internal.decore_data")
local properties_panel = require("druid.widget.properties_panel.properties_panel")

---@class decore.widget.debug_panel: druid.widget
local M = {}

local PAGES = {
	MAIN = "main", -- Main page
	ENTITIES = "entities", -- View list of entities
	SYSTEMS = "systems", -- View list of systems
	SYSTEM = "system", -- View system
	ENTITY = "entity", -- View entity
	ENTITY_PREFABS = "entity_prefabs", -- View entity prefabs
}

function M:init()
	self.properties_panel = self.druid:new_widget(properties_panel, "properties_panel")
	self.button_back = self.druid:new_button("button_back", self.on_button_back)
		:set_key_trigger("key_backspace")
	self.text_prev_page = self.druid:new_text("text_prev_page")
	gui.set_parent(self:get_node("header"), self.properties_panel:get_node("header"), true)
	self.page_stack = {}
end


---@param world world
function M:set_world(world)
	self.world = world
	self:select_page(PAGES.MAIN, nil, "Decore Panel")
end


function M:on_button_back()
	local stacks = #self.page_stack
	if stacks <= 1 then
		return
	end

	table.remove(self.page_stack)
	local page = self.page_stack[#self.page_stack]
	self:select_page(page[1], page[2], page[3], true)
end


function M:select_page(page, context, page_name, is_going_back)
	self.properties_panel:clear()
	self.context = context

	if not is_going_back then
		table.insert(self.page_stack, { page, context, page_name })
	end

	-- Update prev page text
	local preb_stack = self.page_stack[#self.page_stack - 1]
	self.text_prev_page:set_text(preb_stack and preb_stack[3] or "")
	self.properties_panel.text_header:set_text(page_name or "")

	if page == PAGES.MAIN then
		self.properties_panel:add_input("World Name", "Dreams", function(value)
			print("World", value)
		end)

		self.properties_panel:add_button("Entities", function()
			self:select_page(PAGES.ENTITIES, self.world.entities, "Entities")
		end):set_text_button("Inspect")
			:set_color("#A1D7F5")

		self.properties_panel:add_button("Systems" , function()
			self:select_page(PAGES.SYSTEMS, self.world.systems, "Systems")
		end):set_text_button("Inspect")
			:set_color("#E6DF9F")

		self.properties_panel:add_button("Entity Prefabs" , function()
			self:select_page(PAGES.ENTITY_PREFABS, nil, "Entity Prefabs")
		end):set_text_button("Open")
	end

	if page == PAGES.ENTITIES then
		local entities = context
		self.properties_panel.text_header:set_text(page_name .. " (" .. #entities .. ")")

		for i = 1, #entities do
			local entity = entities[i]
			local entity_name = entity.id .. ". " .. (entity.prefab_id or "No Prefab")
			self.properties_panel:add_button(entity_name, function()
				self:select_page(PAGES.ENTITY, entity, entity.prefab_id or "No Prefab")
			end):set_text_button("Inspect")
		end
	end

	if page == PAGES.SYSTEMS then
		local systems = context
		self.properties_panel.text_header:set_text(page_name .. "(" .. #systems .. ")")
		for i = 1, #systems do
			local system = systems[i]
			local system_name = system.id .. " (" .. #system.entities .. ")"
			self.properties_panel:add_button(system_name, function()
				self:select_page(PAGES.SYSTEM, system, system.id)
			end)
		end
	end

	if page == PAGES.SYSTEM then
		local system = context
		self.properties_panel.text_header:set_text("System " .. page_name)

		local entities = system.entities
		for i = 1, #entities do
			local entity = entities[i]
			local entity_name = entity.id .. ". " .. (entity.prefab_id or "No Prefab")
			self.properties_panel:add_button(entity_name, function()
				self:select_page(PAGES.ENTITY, entity, entity.prefab_id or "No Prefab")
			end):set_text_button("Inspect")
		end

		local command_system_id = "command_" .. system.id
		if self.world[command_system_id] then
			self.properties_panel:add_button("Command", function()
				self:select_page(PAGES.ENTITY, self.world[command_system_id], command_system_id)
			end):set_text_button("Inspect")
		end
	end

	-- Should draw a table basically
	if page == PAGES.ENTITY then
		local entity = context

		local component_order = {}
		for component_id in pairs(entity) do
			table.insert(component_order, component_id)
		end
		table.sort(component_order, function(a, b)
			-- Sort by type first then by name
			local a_type = type(entity[a])
			local b_type = type(entity[b])
			if a_type ~= b_type then
				return a_type < b_type
			end

			return tostring(a) < tostring(b)
		end)

		for i = 1, #component_order do
			local component_id = component_order[i]
			local component = entity[component_id]
			self:add_property_component(component_id, component, context)
		end

		-- Draw metatable values
		local metatable = getmetatable(entity)
		if metatable and metatable.__index then
			for component_id, component in pairs(metatable.__index) do
				self:add_property_component("M:" .. component_id, component, context)
			end
		end
	end

	if page == PAGES.ENTITY_PREFABS then
		for _, pack_id in ipairs(decore_data.entities_order) do
			self.properties_panel:add_text("Pack id: " .. pack_id)
			for prefab_id, prefab_data in pairs(decore_data.entities[pack_id]) do
				if type(prefab_id) == "string" then
					self.properties_panel:add_button(prefab_id, function()
						self:select_page(PAGES.ENTITY, prefab_data, prefab_id)
					end)
				end
			end
		end
	end
end


function M:add_property_component(component_id, component, context)
	local component_type = type(component)

	if component_type == "table" then
		local is_empty = next(component) == nil
		local is_array = component[1] ~= nil
		local name = "Inspect"
		if is_empty then
			name = "Inspect (Empty)"
		end
		if is_array then
			name = "Inspect (" .. #component .. ")"
		end
		self.properties_panel:add_button(component_id, function()
			self:select_page(PAGES.ENTITY, component, component_id)
		end):set_text_button(name)
	end

	if component_type == "string" then
		self.properties_panel:add_input(component_id, component, function(value)
			context[component_id] = value
		end)
	end

	if component_type == "number" then
		self.properties_panel:add_input(component_id, component, function(value)
			context[component_id] = tonumber(value)
		end)
	end

	if component_type == "boolean" then
		self.properties_panel:add_checkbox(component_id, component, function(value)
			context[component_id] = value
		end)
	end

	if component_type == "userdata" then
		self.properties_panel:add_text(tostring(component_id), tostring(component))
	end

	if component_type == "function" then
		self.properties_panel:add_button(tostring(component_id), function()
			component(context)
		end):set_text_button("Call")
	end
end


return M