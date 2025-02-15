local decore = require("decore.decore")
local command_game_object = require("core.system.game_object.command_game_object")

---@class entity
---@field game_object component.game_object|nil
---@field hidden boolean|nil

---@class entity.game_object: entity
---@field game_object component.game_object
---@field transform component.transform
---@field hidden boolean|nil

---@class component.game_object
---@field root string|hash
---@field object table<string|hash, string|hash>
---@field factory_url string|nil
---@field is_slice9 boolean|nil
---@field remove_delay number|nil
---@field is_factory boolean|nil
---@field object_scheme table<string, boolean|nil> @For example: {["root"] = true}, used for find objects from already placed game object (not spawned by game object system)
decore.register_component("game_object")
decore.register_component("hidden", false)


---@class go_position_setter
---@field add fun(self, entity, position, rotation)
---@field remove fun(self, entity)
---@field update fun(self)

---@class system.game_object: system
---@field root_to_entity table<string|hash, entity>
---@field go_setter go_position_setter
local M = {}

M.DEBUG_PANEL_UPDATE_MEMORY_LIMIT = 2048
M.DEBUG_PANEL_POSTWRAP_MEMORY_LIMIT = 2048

local TEMP_VECTOR = vmath.vector3(0, 0, 0)
local TEMP_QUAT = vmath.quat(0, 0, 0, 1)
local VECTOR3_ONE = vmath.vector3(1, 1, 1)
local ROOT_URL = hash("/root")
local HASH_POSITION = hash("position")
local HASH_SIZE = hash("size")
local HASH_SCALE = hash("scale")
local HASH_EULER_Z = hash("euler.z")
local sin = math.sin
local cos = math.cos
local rad = math.rad

---@return system.game_object
function M.create_system()
	local system = setmetatable(decore.ecs.system(), { __index = M })
	system.filter = decore.ecs.requireAll("game_object", "transform", decore.ecs.rejectAll("hidden"))
	system.id = "game_object"
	system.root_to_entity = {}
	system.go_setter = go_position_setter.new()

	return system
end


function M:onAddToWorld()
	self.world.command_game_object = command_game_object.create(self)
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param entity entity.game_object
function M:onAdd(entity)
	local is_already_exists = entity.game_object.root or entity.game_object.object
	if is_already_exists then
		self.root_to_entity[entity.game_object.root] = entity
		return
	end


	local object = self:create_object(entity)
	local root = object[ROOT_URL]
	entity.game_object.root = root
	entity.game_object.object = object

	self.go_setter:add(root, entity.transform.position, entity.transform.quaternion)

	if root then
		if entity.game_object.is_slice9 then
			local sprite_url = msg.url(nil, root, "sprite")
			go.set(sprite_url, HASH_SIZE, entity.transform.size)
			go.set(root, HASH_SCALE, VECTOR3_ONE)
		else
			go.set(root, HASH_SCALE, entity.transform.scale)
		end

		--go.set(root, HASH_EULER_Z, entity.transform.rotation)
		go.set_rotation(entity.transform.quaternion, root)
		self.root_to_entity[root] = entity
	end
end


---@param entity entity.game_object
function M:onRemove(entity)
	local remove_delay = entity.game_object.remove_delay

	if not remove_delay then
		self:remove_entity(entity)
	else
		timer.delay(remove_delay, false, function()
			self:remove_entity(entity)
		end)
	end
end


function M:update()
	self.go_setter:update()
end


---@param entity entity.game_object
function M:remove_entity(entity)
	local root = entity.game_object.root
	if root then
		self.root_to_entity[root] = nil
		self.go_setter:remove(root)

		if go.exists(root) then
			go.delete(root, false)
			entity.game_object.root = nil
		end
	end

	local object = entity.game_object.object
	if object then
		for key, node in pairs(object) do
			local related_entity = self.root_to_entity[node]
			if related_entity then
				self.world:removeEntity(related_entity)
			else
				-- TODO: it removes also a childs of the related entity
				-- And I can get errors like panthera trying to play on deleted object
				-- Right before it will be deleted with upper removeEntity
				if go.exists(node) then
					go.delete(node, false)
					object[key] = nil
				end
			end
		end
	end
end


---@param event system.transform.event
---@param entity entity.transform
function M:process_transform_event(event, entity)
	local transform = entity.transform
	local game_object = entity.game_object

	if not decore.is_alive(self, entity) then
		return
	end

	if not game_object or entity.physics then
		return
	end

	local root = game_object.root
	if not root then
		return
	end

	go.set_position(transform.position, root)
	go.set_rotation(transform.quaternion, root)
	go.set_scale(transform.scale, root)

	if game_object.is_slice9 then
		local sprite_url = msg.url(nil, root, "sprite")
		go.set(sprite_url, HASH_SIZE, transform.size)
	end
end


function M:refresh_transform(entity)
	local root = entity.game_object.root
	if not root then
		return
	end

	go.set_position(entity.transform.position, root)
	go.set_scale(entity.transform.scale, root)

	TEMP_QUAT.z = sin(rad(entity.transform.rotation) * 0.5)
	TEMP_QUAT.w = cos(rad(entity.transform.rotation) * 0.5)
	go.set_rotation(TEMP_QUAT, root)
end


local PROPERTIES = {
	[ROOT_URL] = {
		is_spawn_by_entity = true
	}
}
---@param entity entity.game_object
---@return table<string|hash, string|hash>
function M:create_object(entity)
	TEMP_VECTOR.x = entity.transform.position.x
	TEMP_VECTOR.y = entity.transform.position.y
	TEMP_VECTOR.z = self:get_position_z(entity.transform)

	if entity.game_object.is_factory then
		local object = factory.create(entity.game_object.factory_url, TEMP_VECTOR, nil, PROPERTIES[ROOT_URL], entity.transform.scale.x)
		return { [ROOT_URL] = object }
	else
		return collectionfactory.create(entity.game_object.factory_url, TEMP_VECTOR, nil, PROPERTIES, entity.transform.scale.x)
	end
end


---@param t component.transform
---@return number
function M:get_position_z(t)
	return -t.position.y / 10000 + t.position.x / 100000 + t.position.z / 10
end


return M
