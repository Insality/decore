local decore_data = require("decore.internal.decore_data")
local properties_panel = require("druid.widget.properties_panel.properties_panel")

---@class decore.widget.debug_panel: druid.widget
---@field properties_panel widget.properties_panel
local M = {}

local PAGES = {
	MAIN = "main", -- Main page
	ENTITIES = "entities", -- View list of entities
	SYSTEMS = "systems", -- View list of systems
	SYSTEM = "system", -- View system
	TABLE = "table", -- View entity/table/module
	ENTITY_PREFABS = "entity_prefabs", -- View entity prefabs
}

function M:init()
	self.properties_panel = self.druid:new_widget(properties_panel, "properties_panel")
	self.button_back = self.druid:new_button("button_back", self.on_button_back)
		:set_key_trigger("key_backspace")

	self.key_lctrl = self.druid:new_hotkey({ "key_lctrl", "key_lsuper" })

	self.text_prev_page = self.druid:new_text("text_prev_page")
	gui.set_parent(self:get_node("header"), self.properties_panel:get_node("header"), true)

	self.page_stack = {}
	self.undo_stack = {}
end


---@param world world
function M:set_world(world)
	self.world = world
	self:select_page(PAGES.MAIN, nil, "Decore Panel")
end


function M:on_button_back()
	local is_key_ctrl = self.key_lctrl:is_processing()
	if is_key_ctrl then
		-- Undo
		local undo = self.undo_stack[#self.undo_stack]
		if undo then
			self:select_page(undo[1], undo[2], undo[3], undo[4], true)
			table.insert(self.page_stack, { undo[1], undo[2], undo[3], undo[4] })
			table.remove(self.undo_stack)
		end

		return
	end

	local stacks = #self.page_stack
	if stacks <= 1 then
		return
	end

	local removed_page = table.remove(self.page_stack)
	removed_page[4] = self.properties_panel.current_page
	table.insert(self.undo_stack, removed_page)

	local page = self.page_stack[#self.page_stack]
	self:select_page(page[1], page[2], page[3], page[4], true)
end


---Draw main menu page
---@param context any
---@param page_name string
function M:draw_page_main(context, page_name)
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

	self.properties_panel:add_left_right_selector("Number", 0, function(value)
		print("Number", value)
	end):set_number_type(0, 10, true)

	self.properties_panel:add_left_right_selector("Array", 1, function(value)
		print("Array", value)
	end):set_array_type({ 1, 2, 3, 4, 5 }, true)

	self.properties_panel:add_left_right_selector("Number2", 0, function(value)
		print("Number", value)
	end):set_number_type(5, 30, false, 4)

	self.properties_panel:add_left_right_selector("Array", "Hi", function(value)
		print("Array", value)
	end):set_array_type({ "hehe", "Hi", "My", "Name", "Is", "Decore", "..." }, true, 2)
end

---Draw entities page
---@param context table
---@param page_name string
function M:draw_page_entities(context, page_name)
	local entities = context
	self.properties_panel.text_header:set_text("World Entities (" .. #entities .. ")")

	for i = 1, #entities do
		local entity = entities[i]
		local entity_name = entity.id .. ". " .. (entity.prefab_id or "No Prefab")
		self.properties_panel:add_button(entity_name, function()
			self:select_page(PAGES.TABLE, entity, entity.prefab_id or "No Prefab")
		end):set_text_button("Inspect")
	end
end

---Draw systems page
---@param context table
---@param page_name string
function M:draw_page_systems(context, page_name)
	local systems = context
	self.properties_panel.text_header:set_text("World systems (" .. #systems .. ")")
	for i = 1, #systems do
		local system = systems[i]
		local system_name = i .. ". " .. system.id .. " (" .. #system.entities .. ")"
		self.properties_panel:add_button(system_name, function()
			self:select_page(PAGES.SYSTEM, system, system.id)
		end)
	end
end

---Draw system details page
---@param context table
---@param page_name string
function M:draw_page_system(context, page_name)
	local system = context
	self.properties_panel.text_header:set_text("System " .. page_name)

	local entities = system.entities
	for i = 1, #entities do
		local entity = entities[i]
		local entity_name = entity.id .. ". " .. (entity.prefab_id or "No Prefab")
		self.properties_panel:add_button(entity_name, function()
			self:select_page(PAGES.TABLE, entity, entity.prefab_id or "No Prefab")
		end):set_text_button("Inspect")
	end

	local command_system_id = "command_" .. system.id
	if self.world[command_system_id] then
		self.properties_panel:add_button("Command", function()
			self:select_page(PAGES.TABLE, self.world[command_system_id], command_system_id)
		end):set_text_button("Inspect")
	end
end

---Draw table page
---@param context table
---@param page_name string
function M:draw_page_table(context, page_name)
	local entity = context

	local component_order = {}
	for component_id in pairs(entity) do
		table.insert(component_order, component_id)
	end
	table.sort(component_order, function(a, b)
		local a_type = type(entity[a])
		local b_type = type(entity[b])
		if a_type ~= b_type then
			return a_type < b_type
		end
		if type(a) == "number" and type(b) == "number" then
			return a < b
		end
		return tostring(a) < tostring(b)
	end)

	for i = 1, #component_order do
		local component_id = component_order[i]
		local component = entity[component_id]
		self:add_property_component(component_id, component, context)
	end

	local metatable = getmetatable(entity)
	if metatable and metatable.__index then
		local metatable_order = {}
		for key in pairs(metatable.__index) do
			table.insert(metatable_order, key)
		end
		table.sort(metatable_order)

		for i = 1, #metatable_order do
			local component_id = metatable_order[i]
			local component = metatable.__index[component_id]
			self:add_property_component("M:" .. component_id, component, context)
		end
	end
end

---Draw entity prefabs page
---@param context table
---@param page_name string
function M:draw_page_entity_prefabs(context, page_name)
	for _, pack_id in ipairs(decore_data.entities_order) do
		self.properties_panel:add_text("Pack id", pack_id)

		-- Sort
		local entities_ordered = {}
		for prefab_id in pairs(decore_data.entities[pack_id]) do
			table.insert(entities_ordered, prefab_id)
		end
		table.sort(entities_ordered, function(a, b)
			if type(a) == "number" and type(b) == "number" then
				return a < b
			end
			return tostring(a) < tostring(b)
		end)

		for i = 1, #entities_ordered do
			local prefab_id = entities_ordered[i]
			if type(prefab_id) == "string" then
				self.properties_panel:add_button(prefab_id, function()
					self:select_page(PAGES.TABLE, decore_data.entities[pack_id][prefab_id], prefab_id)
				end)
			end
		end
	end
end


---Select page
---@param page string
---@param context any
---@param page_name string
---@param page_index number|nil
---@param is_going_back boolean|nil @If true, then it's going back for track history
function M:select_page(page, context, page_name, page_index, is_going_back)
	page_index = page_index or 1

	if not is_going_back then
		self.undo_stack = {} -- This is undo for going back button, confusing a little?
	end
	self.properties_panel:clear()
	self.context = context

	if not is_going_back then
		table.insert(self.page_stack, { page, context, page_name, page_index })
	end

	local prev_stack = self.page_stack[#self.page_stack - 1]
	if prev_stack then
		self.text_prev_page:set_text(prev_stack[3] or "")
		prev_stack[4] = self.properties_panel.current_page
	end

	self.properties_panel.text_header:set_text(page_name or "")
	self.properties_panel:set_page(page_index)

	if page == PAGES.MAIN then
		self:draw_page_main(context, page_name)
	elseif page == PAGES.ENTITIES then
		self:draw_page_entities(context, page_name)
	elseif page == PAGES.SYSTEMS then
		self:draw_page_systems(context, page_name)
	elseif page == PAGES.SYSTEM then
		self:draw_page_system(context, page_name)
	elseif page == PAGES.TABLE then
		self:draw_page_table(context, page_name)
	elseif page == PAGES.ENTITY_PREFABS then
		self:draw_page_entity_prefabs(context, page_name)
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

		local button_name = component_id
		-- If it's a number or array, try to get the id/name/prefab_id from the component
		if type(component) == "table" and type(component_id) == "number" then
			local extracted_id = component.name or component.prefab_id or component.node_id or component.id
			if extracted_id then
				button_name = component_id .. ". " .. extracted_id
			end
		end

		self.properties_panel:add_button(button_name, function()
			self:select_page(PAGES.TABLE, component, component_id)
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