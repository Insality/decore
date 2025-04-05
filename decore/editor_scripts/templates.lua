---@diagnostic disable: redundant-return-value
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
script: ]] .. (options.is_druid_widget and "\"/druid/druid_widget.gui_script\"" or "\"/entity/{NAME_LOWER}/{NAME_LOWER}.gui_script\"") .. [[

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
  id: "{NAME_LOWER}"
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
name: "{NAME_LOWER}"
scale_along_z: 0
embedded_instances {
  id: "go"
  data: "embedded_components {\n"
  "  id: \"sprite\"\n"
  "  type: \"sprite\"\n"
  "  data: \"tile_set: \\\"/druid/druid.atlas\\\"\\n"
  "default_animation: \\\"ui_circle_64\\\"\\n"
  "material: \\\"/builtins/materials/sprite.material\\\"\\n"
  "blend_mode: BLEND_MODE_ALPHA\\n"
  "\"\n"
  "}\n"
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
  scale3 {
    x: 1.0
    y: 1.0
    z: 1.0
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
local {NAME_LOWER} = require("entity.{NAME_LOWER}.{NAME_LOWER}")

function init(self)
	self.druid = druid.new(self)
	self.widget = self.druid:new_widget({NAME_LOWER}, "{NAME_LOWER}")
	-- Initialize test here
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
---@return string
function M.get_system_registration_code(name)
    local template = "require(\"system.{NAME_LOWER}.system_{NAME_LOWER}\").create_system(),"

    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_test_registration_code(name)
	local template = "deftest.add(require(\"system.{NAME_LOWER}.test_{NAME_LOWER}\"))"
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
	self.root = self:get_node("{NAME_LOWER}")
end

return M
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_test_gui_collection_template(name, options)
    local template = [[
name: "test_{NAME_LOWER}"
scale_along_z: 0
embedded_instances {
  id: "gui"
  data: "components {\n"
  "  id: \"test_{NAME_LOWER}\"\n"
  "  component: \"/entity/{NAME_LOWER}/test/test_{NAME_LOWER}.gui\"\n"
  "  position {\n"
  "    x: 0.0\n"
  "    y: 0.0\n"
  "    z: 0.0\n"
  "  }\n"
  "  rotation {\n"
  "    x: 0.0\n"
  "    y: 0.0\n"
  "    z: 0.0\n"
  "    w: 1.0\n"
  "  }\n"
  "}\n"
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
  scale3 {
    x: 1.0
    y: 1.0
    z: 1.0
  }
}
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_test_system_template(name, options)
    local template = [[
return function()
	describe("System {NAME_LOWER}", function()
		local decore ---@type decore
		local world ---@type world
		local system_{NAME_LOWER} ---@type system.{NAME_LOWER}

		before(function()
			decore = require("decore.decore")
			system_{NAME_LOWER} = require("system.{NAME_LOWER}.system_{NAME_LOWER}")

			world = decore.world()
			world:add(system_{NAME_LOWER}.create_system())
		end)

		it("Should init entities", function()
			local entity = world:add({ {NAME_LOWER} = {} })
			world:refresh()

			-- Add assertions for your system here
			assert(entity.{NAME_LOWER} ~= nil)
		end)
	end)
end
]]
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@return string
function M.get_test_system_registration_code(name)
    local template = "deftest.add(require(\"system.{NAME_LOWER}.test/test_system_{NAME_LOWER}\"))"
    return template:gsub("{NAME_LOWER}", name:lower())
end


---@param name string
---@param options table
---@return string
function M.get_test_gui_template(name, options)
    local template = [[
script: "/entity/{NAME_LOWER}/test/test_{NAME_LOWER}.gui_script"

nodes {
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
  scale {
    x: 1.0
    y: 1.0
    z: 1.0
  }
  size {
    x: 1.0
    y: 1.0
    z: 1.0
  }
  id: "root"
  type: TYPE_BOX
  layer: ""
  inherit_alpha: true
  alpha: 1.0
  template: "/entity/{NAME_LOWER}/{NAME_LOWER}.gui"
  template_node_child: false
  custom_type: 0
  enabled: true
}
material: "/builtins/materials/gui.material"
adjust_reference: ADJUST_REFERENCE_PARENT
]]

    return template:gsub("{NAME_LOWER}", name:lower()):gsub("{NAME}", name)
end


return M
