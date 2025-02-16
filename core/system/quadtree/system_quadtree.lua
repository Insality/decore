local decore = require("decore.decore")
local quadtree = require("core.system.quadtree.quadtree")

local command_quadtree = require("core.system.quadtree.command_quadtree")

local logger = decore.get_logger("system_quadtree")

---@class entity
---@field quadtree boolean|nil

---@class entity.quadtree: entity
---@field quadtree component.quadtree
---@field transform component.transform

---@class component.quadtree: boolean
decore.register_component("quadtree", false)

---@class system.quadtree: system
---@field quadtree quadtree
---@field debug_is_draw_quadtree boolean
---@field entity_to_state table<entity, quadtree_state>
---@field entity_to_update table<entity.quadtree, quadtree_state>
local M = {}

local width = sys.get_config_int("display.width")
local height = sys.get_config_int("display.height")

---@return system.quadtree
function M.create_system()
	local system = decore.system(M, "quadtree", { "transform", "quadtree" })
	system.quadtree = quadtree.create(5, 6, 0, -width/2, -height/2, width, height)
	system.debug_is_draw_quadtree = false
	system.entity_to_state = {}
	system.entity_to_update = {}

	return system
end


function M:onAddToWorld()
	self.world.command_quadtree = command_quadtree.create(self)
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)

	for entity, quadtree_state in pairs(self.entity_to_update) do
		local t = entity.transform
		self.quadtree:update(quadtree_state, t.position_x, t.position_y, t.size_x, t.size_y)
	end
end


---@param entity entity.transform
function M:onAdd(entity)
	local t = entity.transform
	local x = t.position_x
	local y = t.position_y
	local w = t.size_x
	local h = t.size_y

	local quadtree_state = self.quadtree:insert(entity, x, y, w, h)
	self.entity_to_state[entity] = quadtree_state
end


function M:onRemove(entity)
	local quadtree_state = self.entity_to_state[entity]
	self.quadtree:remove(quadtree_state)
	self.entity_to_state[entity] = nil
end


function M:update(dt)
	if self.debug_is_draw_quadtree then
		self:debug_draw_quadtree(self.quadtree)
	end
end


---@param quadtree quadtree
function M:debug_draw_quadtree(quadtree)
	if not self.world.command_debug_draw then
		return
	end

	if quadtree.objects_count > 0 then
		local x, y, w, h = quadtree.x, quadtree.y, quadtree.width, quadtree.height
		self.world.command_debug_draw:draw_rectangle(x + w/2, y + h/2, w, h)
		--self.world.command_debug_draw:draw_text(x, y, #quadtree.objects)
	end

	if quadtree.sectors then
		for index = 1, #quadtree.sectors do
			self:debug_draw_quadtree(quadtree.sectors[index])
		end
	end
end


---@param event system.transform.event
function M:process_transform_event(event)
	local entity = event.entity
	local quadtree_state = self.entity_to_state[entity]
	if not quadtree_state then
		return
	end

	if event.is_position_changed or event.is_size_changed then
		self.entity_to_update[entity] = quadtree_state
	end
end


---@param entity entity.transform
---@param radius number
---@param callback fun(entity: entity)
function M:get_neighbors(entity, radius, callback)
	local position_x = entity.transform.position_x
	local position_y = entity.transform.position_y
	self.quadtree:get_in_radius(position_x, position_y, radius, callback)
end


return M
