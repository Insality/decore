local panthera = require("panthera.panthera")
local animation = require("examples.boids.boid.boid_sensor_panthera")

---@class gui.boid_sensor: druid.widget
local M = {}

local HASH_POSITION_X = hash("position.x")
local HASH_POSITION_Y = hash("position.y")
local HASH_ROTATION = hash("euler.z")

function M:init()
	self.root = self:get_node("root")
	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	panthera.play(self.animation, "default", {
		is_loop = true
	})
end


function M:set_position(x, y)
	gui.set(self.root, HASH_POSITION_X, x)
	gui.set(self.root, HASH_POSITION_Y, y)
end


function M:set_rotation(angle)
	gui.set(self.root, HASH_ROTATION, angle)
end


return M