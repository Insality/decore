---@class action
---@field action_id hash|nil

--- JSON file scheme for entities data
---@class decore.entities_pack_data
---@field pack_id string
---@field entities table<string, entity>

--- JSON file scheme for components data
---@class decore.components_pack_data
---@field pack_id string
---@field components table<string, any>

--- JSON file scheme for worlds data
---@class decore.worlds_pack_data
---@field pack_id string
---@field worlds table<string, decore.world.instance>

---@class decore.world.instance_id
---@field world_id string|nil
---@field pack_id string|nil

---@class decore.entities_pack_data.instance
---@field prefab_id string|nil
---@field pack_id string|nil
---@field components table<string, any>|nil

---@class decore.world.instance
---@field included_worlds decore.world.instance_id[]|nil
---@field entities decore.entities_pack_data.instance[]



