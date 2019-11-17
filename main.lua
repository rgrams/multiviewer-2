
require "love_run"
require "philtre.init"  -- Load all engine components into global variables.
require "philtre.lib.math-patch"
vector = require "philtre.lib.vec2xy"

physics.setCategoryNames(
	"default", "images"
)
local drawLayers = {
	gui = { "gui" },
	world = { "images" },
}
local defaultLayer = "images"

local clearColor = { 0.2, 0.2, 0.2 }

local root
local editor_script = require "editor_script"

function love.load()
	Input.init()
	Input.bind(require("input_bindings"))

	love.graphics.setBackgroundColor(clearColor)

	local font = love.graphics.newFont("font/source/OpenSans-Semibold.ttf", 15)
	love.graphics.setFont(font)

	scene = SceneTree(drawLayers, defaultLayer)

	-- Add world tree in one chunk so inits are called in bottom-up order.
	root = mod(
		Object(), { name = "root", debugDraw = false, children = {
			mod(World(0, 1800, false), { script = {editor_script} }),
			Camera()
		}}
	)
	scene:add(root)

	world = scene:get("/root/World")
	scene:update(0.01)
end

function love.update(dt)
	scene:update(dt)
end

function love.draw()
   Camera.current:applyTransform()
	root:callRecursive("debugDraw", "images")
   scene:draw("world")
	Camera.current:resetTransform()

	scene:draw("gui")

	love.graphics.setColor(1, 1, 1, 1)
   local avgDt = love.timer.getAverageDelta() * 1000
   love.graphics.print(string.format("%.4f", avgDt))
end

function love.resize(w, h)
	Camera.setAllViewports(0, 0, w, h)
	shouldUpdate = true
end

function love.focus(focus)
	if focus then  shouldUpdate = true  end
end

function love.mousemoved(x, y, dx, dy, istouch)
	if love.window.hasFocus() then
		shouldUpdate = true
	end
end
