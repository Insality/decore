local M = {}


---@param name string
---@param options table
---@return string
function M.get_system_template(name, options)
    local template = [[
local decore = require("decore.decore")

---@class entity
---@field {NAME_LOWER} component.{NAME_LOWER}|nil

---@class entity.{NAME_LOWER}: entity
---@field {NAME_LOWER} component.{NAME_LOWER}

---@class component.{NAME_LOWER}
decore.register_component("{NAME_LOWER}", {})

---@class system.{NAME_LOWER}: system
---@field entities entity.{NAME_LOWER}[]
local M = {}


---@static
---@return system.{NAME_LOWER}
function M.create_system()
    return decore.system(M, "{NAME_LOWER}", { "{NAME_LOWER}" })
end

]]
    if options.include_postwrap then
        template = template .. [[

function M:postWrap()
    -- self.world.event_bus:process("transform_event", self.on_transform_event, self)
end


]]
    end

    template = template .. [[
return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_entity_template(name, options)
    local template = [[
---@return entity
return {
	transform = {},
	{NAME_LOWER} = {},
}
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_gui_script_template(name, options)
    local template = [[
local druid = require("druid.druid")

function init(self)
    self.druid = druid.new(self)
end

function final(self)
    self.druid:final()
end

function update(self, dt)
    self.druid:update(dt)
end

function on_message(self, message_id, message, sender)
    self.druid:on_message(message_id, message, sender)
end

function on_input(self, action_id, action)
    return self.druid:on_input(action_id, action)
end
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_gui_template(name, options)
    local template = [[
nodes {
  position {
    x: 960.0
    y: 540.0
  }
  size {
    x: 1920.0
    y: 1080.0
  }
  type: TYPE_BOX
  id: "root"
  adjust_mode: ADJUST_MODE_STRETCH
  inherit_alpha: true
  size_mode: SIZE_MODE_AUTO
  visible: false
}
material: "/builtins/materials/gui.material"
adjust_reference: ADJUST_REFERENCE_PARENT
]]

    return template:gsub("{NAME_LOWER}", name:lower()):gsub("{NAME}", name)
end


---@param name string
---@param options table
---@return string
function M.get_collection_template(name, options)
    local template = [[
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/druid/druid.atlas\"\n"
  "default_animation: \"squircle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_test_template(name, options)
    local template = [[
local druid = require("druid.druid")
local panthera = require("panthera.panthera")

---@class test.{NAME_LOWER}
local M = {}


function M:init()
    self.druid = druid.new(self)
    -- Initialize test here
end


function M:final()
    self.druid:final()
end


function M:update(dt)
    self.druid:update(dt)
end


return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_test_gui_script_template(name, options)
    local template = [[
local druid = require("druid.druid")
local {NAME_LOWER} = require("{NAME_LOWER}")

---@class test.{NAME_LOWER}
local M = {}


function M:init()
    self.druid = druid.new(self)
    self.widget = {NAME_LOWER}:new(self.druid, gui.get_node("root"))
    -- Initialize test here
end


function M:final()
    self.druid:final()
end


function M:update(dt)
    self.druid:update(dt)
end


function M:on_message(message_id, message, sender)
    self.druid:on_message(message_id, message, sender)
end


function M:on_input(action_id, action)
    return self.druid:on_input(action_id, action)
end


return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_system_registration_code(name)
    local template = "require(\"system.{NAME_LOWER}.system_{NAME_LOWER}\").create_system(),"

    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_test_registration_code(name)
	local template = "deftest.add(require(\"system.{NAME_LOWER}/test_{NAME_LOWER}\"))"
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_entity_registration_code(name)
	local template = "[\"{NAME_LOWER}\"] = require(\"entity.{NAME_LOWER}.entity_{NAME_LOWER}\"),"
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_command_template(name, options)
    local template = [[
---@class world
---@field command_{NAME_LOWER} command.{NAME_LOWER}

---@class command.{NAME_LOWER}
---@field {NAME_LOWER} system.{NAME_LOWER}
local M = {}


---@param {NAME_LOWER} system.{NAME_LOWER}
---@return command.{NAME_LOWER}
function M.create({NAME_LOWER})
	return setmetatable({ {NAME_LOWER} = {NAME_LOWER} }, { __index = M })
end


return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_druid_widget_template(name, options)
    local template = [[
---@class widget.{NAME_LOWER}: druid.widget
local M = {}

function M:init()
	self.root = self:get_node("root")
end

return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


return M
