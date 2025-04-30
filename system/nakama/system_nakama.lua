local log = require("log.log")
local ecs = require("decore.ecs")
local nakama_core = require("system.nakama.nakama_core")
local decore      = require("decore.decore")

local logger = log.get_logger("system.nakama")

---@class entity
---@field nakama component.nakama|nil

---@class entity.nakama: entity
---@field nakama component.nakama

---@class component.nakama
---@field server_host string
---@field server_port number
---@field check_connection_timer number
---@field reconnect_attempts_time number[]
---@field server_key string
---@field http_key string
---@field encryption_key string
---@field refresh_encryption_key string
---@field debug_log boolean
---@field use_ssl boolean
---@field client nakama.client|nil
---@field socket nakama.socket|nil
---@field session nakama.session|nil
---@field is_connected boolean
---@field is_connecting boolean

---@class system.nakama: system
local M = {}


---@static
---@return system.nakama
function M.create_system()
	return decore.processing_system(M, "nakama", { "nakama" })
end


---@param entity entity.nakama
function M:onAdd(entity)
	nakama_core.connect(entity, function()
		self:on_connected()
	end)
end


function M:on_connected()
	logger:trace("on_connected")
end


return M
