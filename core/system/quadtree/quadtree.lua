---@class quadtree_state
---@field x number
---@field y number
---@field width number
---@field height number
---@field data any
---@field quadtree quadtree

---@class quadtree
---@field split_threshold_count number
---@field max_levels number
---@field level number
---@field x number
---@field y number
---@field width number
---@field height number
---@field objects table<quadtree_state, boolean> -- Dictionary for O(1) access
---@field objects_count number -- Number of objects in this node
---@field len number -- Total number of objects in the quadtree
---@field sectors quadtree[] -- The 4 child nodes, [1] = bottom left, [2] = top left, [3] = top right, [4] = bottom right
---@field parent quadtree|nil -- The parent node
local M = {}

---Create new quadtree object. Inner objects are also quadtrees
---@param split_threshold_count number
---@param max_levels number
---@param level number|nil
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
---@return quadtree
function M.create(split_threshold_count, max_levels, level, x, y, width, height)
	local self = setmetatable({
		split_threshold_count = split_threshold_count or 4,
		max_levels = max_levels or 5,
		level = level or 0,
		x = x or 0,
		y = y or 0,
		width = width or 0,
		height = height or 0,
		objects = nil,
		objects_count = 0,
		len = 0, -- Total number of objects
		sectors = nil,
	}, { __index = M })
	return self
end

---Insert entity into quadtree
---@param data any
---@param x number
---@param y number
---@param width number
---@param height number
---@return quadtree_state
function M:insert(data, x, y, width, height)
	local quadtree_state = { x = x, y = y, width = width, height = height, data = data }
	self:insert_state(quadtree_state)
	return quadtree_state
end


---Insert a quadtree_state into the quadtree
---@param quadtree_state quadtree_state
---@return boolean success
function M:insert_state(quadtree_state)
	quadtree_state.quadtree = self
	self.objects = self.objects or {}

	-- If sectors exist, insert into sector
	if self.sectors then
		local x, y = quadtree_state.x, quadtree_state.y
		local width, height = quadtree_state.width, quadtree_state.height
		local index = self:get_index(x, y, width, height)
		if index ~= 0 then
			return self.sectors[index]:insert_state(quadtree_state)
		end
	end

	local is_inserted = false
	if not self.objects[quadtree_state] then
		is_inserted = true
		self.objects[quadtree_state] = true
		self.objects_count = self.objects_count + 1

		if not self.sectors then
			if self.objects_count > self.split_threshold_count and self.level < self.max_levels then
				self:subdivide()
			end
		end
	end

	return is_inserted
end


function M:union()
	if self.sectors and self:count_objects() - self.objects_count == 0 then
		self.sectors = nil
	end
end


---Remove entity from quadtree
---@param quadtree_state quadtree_state
---@return boolean success
function M:remove(quadtree_state)
	-- If no sector or object is not in sector
	if self.objects and self.objects[quadtree_state] then
		self.objects[quadtree_state] = nil
		self.objects_count = self.objects_count - 1
		--if self.parent then
		--	self.parent:remove_empty_sectors()
		--end
		return true
	end

	if self.sectors then
		local index = self:get_index(quadtree_state.x, quadtree_state.y, quadtree_state.width, quadtree_state.height)
		if index ~= 0 then
			return self.sectors[index]:remove(quadtree_state)
		end
	end

	return false
end

---Subdivide the node into four child nodes
function M:subdivide()
	local half_width = self.width / 2
	local half_height = self.height / 2
	local x = self.x
	local y = self.y
	local level = self.level + 1

	--print(self.max_levels, level)
	-- Bottom left
	self.sectors = {}

	self.sectors[1] = M.create(self.split_threshold_count, self.max_levels, level, x, y, half_width, half_height)
	self.sectors[1].parent = self
	-- Top left
	self.sectors[2] = M.create(self.split_threshold_count, self.max_levels, level, x, y + half_height, half_width, half_height)
	self.sectors[2].parent = self
	-- Top right
	self.sectors[3] = M.create(self.split_threshold_count, self.max_levels, level, x + half_width, y + half_height, half_width, half_height)
	self.sectors[3].parent = self
	-- Bottom right
	self.sectors[4] = M.create(self.split_threshold_count, self.max_levels, level, x + half_width, y, half_width, half_height)
	self.sectors[4].parent = self

	-- Split objects into sectors
	for obj in pairs(self.objects) do
		local index = self:get_index(obj.x, obj.y, obj.width, obj.height)
		if index ~= 0 then
			self.objects[obj] = nil
			self.objects_count = self.objects_count - 1
			obj.quadtree = nil

			self.sectors[index]:insert_state(obj)
		end
	end
end

---Determine which node the object belongs to
---@param x number
---@param y number
---@param width number
---@param height number
---@return number index The 1 is bottom left, 2 is top left, 3 is top right, 4 is bottom right. 0 if object cannot completely fit within a child node
function M:get_index(x, y, width, height)
	local mid_x = self.x + (self.width / 2)
	local mid_y = self.y + (self.height / 2)

	local is_left = x + width <= mid_x
	local is_right = x >= mid_x
	local is_bottom = y + height <= mid_y
	local is_top = y >= mid_y

	if is_left then
		if is_bottom then
			return 1
		elseif is_top then
			return 2
		end
	elseif is_right then
		if is_top then
			return 3
		elseif is_bottom then
			return 4
		end
	end

	return 0
end

---Update entity in quadtree
---@param quadtree_state quadtree_state
---@param x number
---@param y number
---@param width number
---@param height number
function M:update(quadtree_state, x, y, width, height)
	local parent_quadtree = self:get_state_to_put(x, y, width, height)
	local is_quadtree_state_changed = quadtree_state.quadtree ~= parent_quadtree

	if not is_quadtree_state_changed then
		quadtree_state.x = x
		quadtree_state.y = y
		quadtree_state.width = width
		quadtree_state.height = height
		return
	end

	local prev_quadtree = quadtree_state.quadtree
	prev_quadtree:remove(quadtree_state)

	quadtree_state.x = x
	quadtree_state.y = y
	quadtree_state.width = width
	quadtree_state.height = height
	parent_quadtree:insert_state(quadtree_state)
end


function M:remove_empty_sectors()
	if not self.sectors then
		return
	end

	local is_sectors_empty = true
	for i = 1, 4 do
		if self.sectors[i] and self.sectors[i]:count_objects() > 0 then
			is_sectors_empty = false
			break
		end
	end

	if is_sectors_empty then
		self.sectors = nil
	end
end

---Get the appropriate node to place the object
---@param x number
---@param y number
---@param width number
---@param height number
---@return quadtree
function M:get_state_to_put(x, y, width, height)
	if self.sectors then
		local index = self:get_index(x, y, width, height)
		if index ~= 0 then
			return self.sectors[index]:get_state_to_put(x, y, width, height)
		end
	end
	return self
end

---Retrieve all entities within a given rectangular area
---@param callback fun(quadtree_state: quadtree_state)
---@param x number
---@param y number
---@param w number
---@param h number
function M:retrieve(callback, x, y, w, h)
	if self.sectors then
		local index = self:get_index_area(x, y, w, h)
		if index ~= 0 then
			self.sectors[index]:retrieve(callback, x, y, w, h)
		end
	end

	if self.objects then
		for obj in pairs(self.objects) do
			callback(obj.data)
		end
	end
end

---Get index for area
---@param x number
---@param y number
---@param w number
---@param h number
---@return number
function M:get_index_area(x, y, w, h)
	local index = 0
	local mid_x = self.x + (self.width / 2)
	local mid_y = self.y + (self.height / 2)

	local is_bottom = y + h <= mid_y
	local is_top = y >= mid_y

	local is_left = x + w <= mid_x
	local is_right = x >= mid_x

	if is_left then
		if is_bottom then
			index = 1
		elseif is_top then
			index = 2
		end
	elseif is_right then
		if is_top then
			index = 3
		elseif is_bottom then
			index = 4
		end
	end

	return index
end

---Get all entities in radius
---@param x number X position
---@param y number Y position
---@param radius number Circle radius
function M:get_in_radius(x, y, radius, callback)
	local x_area = x - radius
	local y_area = y - radius
	local w_area = radius * 2
	local h_area = radius * 2
	self:retrieve(callback, x_area, y_area, w_area, h_area)
end

---Get all entities in a rectangle
---@param x number
---@param y number
---@param width number
---@param height number
---@param callback fun(quadtree_state: quadtree_state)
function M:get_in_rect(x, y, width, height, callback)
	return self:retrieve(callback, x, y, width, height)
end

---Get all entities in the quadtree
---@param callback fun(quadtree_state: quadtree_state)
function M:get_all(callback)
	return self:retrieve(callback, self.x, self.y, self.width, self.height)
end

---Count the total number of objects in the quadtree
---@return number
function M:count_objects()
	local objects = self.objects_count
	if self.sectors then
		for i = 1, #self.sectors do
			objects = objects + self.sectors[i]:count_objects()
		end
	end
	return objects
end

function M:print_scheme(ident)
	ident = ident or ""
	print(ident .. "Level: " .. self.level)
	print(ident .. "Objects: " .. self.objects_count, "Total: " .. self:count_objects())
	print(ident .. "Sectors: " .. self.sectors and #self.sectors)
	if self.sectors then
		for i = 1, #self.sectors do
			self.sectors[i]:print_scheme(ident .. "  ")
		end
	end
end

return M
