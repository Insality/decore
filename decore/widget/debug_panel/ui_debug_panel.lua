local helper = require("druid.helper")
local decore = require("decore.decore")
local decore_data = require("decore.internal.decore_data")
local properties_panel = require("druid.widget.properties_panel.properties_panel")

local property_prefab = require("decore.widget.debug_panel.properties.property_prefab")
local property_system = require("decore.widget.debug_panel.properties.property_system")

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
	self.properties_panel.paginator.button_left:set_key_trigger("key_minus")
	self.properties_panel.paginator.button_right:set_key_trigger("key_equals")

	self.button_back = self.druid:new_button("button_back", self.on_button_back)
		:set_key_trigger("key_backspace")

	self.key_lctrl = self.druid:new_hotkey({ "key_lctrl", "key_lsuper" })

	self.text_prev_page = self.druid:new_text("text_prev_page")
	gui.set_parent(self:get_node("header"), self.properties_panel:get_node("header"), true)

	self.prefab_property_prefab = self:get_node("property_prefab/root")
	gui.set_enabled(self.prefab_property_prefab, false)

	self.prefab_property_system = self:get_node("property_system/root")
	gui.set_enabled(self.prefab_property_system, false)

	self.page_stack = {}
	self.undo_stack = {}

	--self.properties_panel:toggle_hide()
end


---@param world world
function M:set_world(world)
	self.world = world
	self:select_page(PAGES.MAIN, nil, "Decore Panel")

	-- And systems
	--self:select_page(PAGES.SYSTEMS, self.world.systems, "Systems")
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
	self.properties_panel:add_input(function(input)
		input:set_text_property("World Name")
		input:set_text_value("Dreams")
		input:on_change(function(_, value)
			print("World", value)
		end)
	end)

	self.properties_panel:add_button(function(button)
		button.text_name:set_text("Entities")
		button.text_button:set_text(string.format("Inspect (%d)", #self.world.entities))
		button:set_color("#A1D7F5")
		button.button.on_click:subscribe(function()
			self:select_page(PAGES.ENTITIES, self.world.entities, "Entities")
		end)
	end)

	self.properties_panel:add_button(function(button)
		button:set_text_property("Systems")
		button:set_text_button(string.format("Inspect (%d)", #self.world.systems))
		button:set_color("#E6DF9F")
		button.button.on_click:subscribe(function()
			self:select_page(PAGES.SYSTEMS, self.world.systems, "Systems")
		end)
	end)

	self.properties_panel:add_button(function(button)
		button:set_text_property("Entity Prefabs")
		button:set_text_button("Open")
		button.button.on_click:subscribe(function()
			self:select_page(PAGES.ENTITY_PREFABS, nil, "Entity Prefabs")
		end)
	end)

	-- Add system interval slider
	self.properties_panel:add_slider(function(slider)
		slider:set_number_type(0.05, 2, 0.01)
		slider:set_text_property("World Speed")
		slider:set_value(self.world.speed or 1)
		slider:on_change(function(value)
			self.world.speed = value
		end)
	end)
end

---Draw entities page
---@param context entity[]
---@param page_name string
function M:draw_page_entities(context, page_name)
	local entities = context
	self.properties_panel.text_header:set_text("World Entities (" .. #entities .. ")")

	for i = 1, #entities do
		self.properties_panel:add_widget(function()
			local entity = entities[i]
			local entity_prefab_id = entity.prefab_id or "No Prefab"
			local entity_name = entity.id .. ". " .. entity_prefab_id

			local widget = self.druid:new_widget(property_prefab, "property_prefab", self.prefab_property_prefab)
			widget:set_text_property(entity_name)
			widget:set_text_button("Inspect")
			widget.button.on_click:subscribe(function()
				self:select_page(PAGES.TABLE, entity, entity.prefab_id or "No Prefab")
			end)

			widget.on_drag_start:subscribe(function()
				entity.follow_cursor = true
				self.world:addEntity(entity)
			end)

			widget.on_drag_end:subscribe(function()
				entity.follow_cursor = nil
				self.world:addEntity(entity)
			end)

			return widget
		end)
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

		self.properties_panel:add_widget(function()
			local widget = self.druid:new_widget(property_system, "property_system", self.prefab_property_system)
			widget:set_system(system)
			widget:set_text(system_name)
			widget.button_inspect.on_click:subscribe(function()
				self:select_page(PAGES.SYSTEM, system, system.id)
			end)

			return widget
		end)
	end
end

---Draw system details page
---@param context table
---@param page_name string
function M:draw_page_system(context, page_name)
	local system = context
	self.properties_panel.text_header:set_text("System " .. page_name)

	-- Add system interval slider
	self.properties_panel:add_slider(function(slider)
		slider:set_text_property("System Interval")
		slider:set_value(system.interval or 0)
		slider:set_number_type(0, 1, 0.01)
		slider:on_change(function(value)
			system.interval = value
			if system.interval == 0 then
				system.interval = nil
			end
			system.bufferedTime = 0
		end)
	end)

	-- Draw system properties
	self:draw_page_table(context, page_name)

	-- If system has command, add button to inspect it
	local command_system_id = "command_" .. system.id
	if self.world[command_system_id] then
		self.properties_panel:add_button(function(button)
			button:set_text_property("Command")
			button:set_text_button("Inspect")
			button.button.on_click:subscribe(function()
				self:select_page(PAGES.TABLE, self.world[command_system_id], command_system_id)
			end)
		end)
	end
end

---Draw table page
---@param context table
---@param page_name string
function M:draw_page_table(context, page_name)
	local data = context

	if data.debug_panel_draw and type(data.debug_panel_draw) == "function" then
		data:debug_panel_draw(self.properties_panel)
		return
	end

	local component_order = {}
	for component_id in pairs(data) do
		table.insert(component_order, component_id)
	end
	table.sort(component_order, function(a, b)
		local a_type = type(data[a])
		local b_type = type(data[b])
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
		local component = data[component_id]
		self:add_property_component(component_id, component, context)
	end

	local metatable = getmetatable(data)
	if metatable and metatable.__index and type(metatable.__index) == "table" then
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
		self.properties_panel:add_text(function(text)
			text:set_text_property("Pack id")
			text:set_text_value(pack_id)
		end)

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
				self.properties_panel:add_widget(function()
					local widget = self.druid:new_widget(property_prefab, "property_prefab", self.prefab_property_prefab)
					widget:set_text_property(prefab_id)
					widget:set_text_button("Inspect")
					widget.button.on_click:subscribe(function()
						self:select_page(PAGES.TABLE, decore_data.entities[pack_id][prefab_id], prefab_id)
					end)

					---@type entity
					local entity_to_create = nil
					local drag_n_drop_entity = nil

					widget.on_drag_start:subscribe(function()
						entity_to_create = decore.create_entity(prefab_id, pack_id)
						drag_n_drop_entity = decore.create_entity(nil, nil, {
							game_object = entity_to_create.game_object,
							transform = entity_to_create.transform,
							color = entity_to_create.color,
							follow_cursor = true,
						})
						self.world:addEntity(drag_n_drop_entity)
					end)

					widget.on_drag_end:subscribe(function()
						if not entity_to_create or not drag_n_drop_entity then
							return

						end
						entity_to_create.transform = drag_n_drop_entity.transform

						self.world:removeEntity(drag_n_drop_entity)
						self.world:addEntity(entity_to_create)

						entity_to_create = nil
						drag_n_drop_entity = nil
					end)

					return widget
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

		self.properties_panel:add_button(function(button)
			button:set_text_property(button_name)
			button:set_text_button(name)
			button.button.on_click:subscribe(function()
				self:select_page(PAGES.TABLE, component, component_id)
			end)
		end)
	end

	if component_type == "string" then
		self.properties_panel:add_input(function(input)
			input:set_text_property(tostring(component_id))
			input:set_text_value(tostring(component))
			input:on_change(function(_, value)
				context[component_id] = value
			end)
		end)
	end

	if component_type == "number" then
		self.properties_panel:add_input(function(input)
			input:set_text_property(tostring(component_id))
			input:set_text_value(tostring(helper.round(component, 3)))
			input:on_change(function(_, value)
				context[component_id] = tonumber(value)
			end)
		end)
	end

	if component_type == "boolean" then
		self.properties_panel:add_checkbox(function(checkbox)
			checkbox:set_text_property(tostring(component_id))
			checkbox:set_value(component)
			checkbox:on_change(function(value)
				context[component_id] = value
			end)
		end)
	end

	if component_type == "userdata" then
		if types.is_vector3(component) then
			self.properties_panel:add_vector3(function(vector3)
				vector3:set_text_property(tostring(component_id))
				vector3:set_value(component.x, component.y, component.z)
				vector3.on_change:subscribe(function(value)
					component.x = value.x
					component.y = value.y
					component.z = value.z
					print("Vector3", component)
				end)
			end)
		else
			self.properties_panel:add_text(function(text)
				text:set_text_property(tostring(component_id))
				text:set_text_value(tostring(component))
			end)
		end
	end

	if component_type == "function" then
		self.properties_panel:add_button(function(button)
			button:set_text_property(tostring(component_id))
			button:set_text_button("Call")
			button.button.on_click:subscribe(function()
				component(context)
			end)
		end)
	end
end


return M