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
    -- Add post wrap logic here
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
local decore = require("decore.decore")

---@class entity.{NAME_LOWER}: entity
local M = {}


---@param world world
---@return entity.{NAME_LOWER}
function M.create(world)
    local entity = decore.create_entity("{NAME_LOWER}")
    world:addEntity(entity)
    return entity
end


return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_gui_script_template(name, options)
    local template = [[
local druid = require("druid.druid")

---@class {NAME_LOWER}: druid.widget
local M = {}


function M:init()
    -- Initialize your widget here
end


function M:final()
    -- Clean up here
end


function M:update(dt)
    -- Update logic here
end


return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_gui_template(name, options)
    local template = [[
script: "/druid/druid_widget.gui_script"
fonts {
  name: "druid_text_normal"
  font: "/druid/fonts/druid_text_normal.font"
}
textures {
  name: "druid"
  texture: "/druid/druid.atlas"
}
nodes {
  position {
    x: 0.0
    y: 0.0
  }
  size {
    x: 200.0
    y: 200.0
  }
  type: TYPE_BOX
  id: "root"
  pivot: PIVOT_CENTER
  inherit_alpha: true
  size_mode: SIZE_MODE_AUTO
  visible: false
}
]]

    -- If this is a druid widget, add more specific template
    if options.is_druid_widget then
        template = template .. [[
nodes {
  position {
    x: 0.0
    y: 0.0
  }
  size {
    x: 200.0
    y: 50.0
  }
  type: TYPE_BOX
  id: "background"
  parent: "root"
  inherit_alpha: true
  size_mode: SIZE_MODE_MANUAL
}
nodes {
  position {
    x: 0.0
    y: 0.0
  }
  size {
    x: 180.0
    y: 40.0
  }
  color {
    x: 1.0
    y: 1.0
    z: 1.0
    w: 1.0
  }
  type: TYPE_TEXT
  text: "{NAME}"
  font: "druid_text_normal"
  id: "text"
  parent: "root"
  align: ALIGN_CENTER
  valign: VALIGN_MIDDLE
  inherit_alpha: true
}
]]
    end

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
    local template = [[    {
        id = "{NAME_LOWER}",
        file = require("sys.{NAME_LOWER}"),
    },]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_test_registration_code(name)
    local template = [[    {
        id = "test_{NAME_LOWER}",
        file = require("test_{NAME_LOWER}"),
    },]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_entity_registration_code(name)
    local template = [[    {
        id = "{NAME_LOWER}",
        file = require("{NAME_LOWER}"),
    },]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_command_template(name, options)
    local template = [[
local decore = require("decore.decore")

---@class command.{NAME_LOWER}: command
local M = {}


function M:execute()
    -- Implement command execution logic here
end


function M:undo()
    -- Implement undo logic here
end


return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


return M
