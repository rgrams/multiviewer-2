io.stdout:setvbuf("no")

require "love_run"
vector = require "lib.vec2xy"
input = require "input"

local Camera = require "lib.Camera"
local Editor = require "editor_script"

local backgroundColor = { 0.2, 0.2, 0.2 }

local editor
camera = nil

function love.load(arg)
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(backgroundColor)

	local font = love.graphics.newFont("font/source/OpenSans-Semibold.ttf", 15)
	love.graphics.setFont(font)

	for i,binding in ipairs(require("input_bindings")) do
		input.bind(unpack(binding))
	end

	love.window.maximize()

	camera = Camera(0, 0, 0, nil, "expand view")

	editor = Editor()
	editor:init()
	editor:update(0.01)

	if arg[1] then
		editor:openProjectFile(arg[1])
	end
end

function input.callback(name, change)
	editor:input(name, change)
end

function love.update(dt)
	editor:update(dt)
end

function love.draw()
   camera:applyTransform()
   editor:draw()
	camera:resetTransform()
end

function love.filedropped(file)
	editor:fileDropped(file)
end

function love.directorydropped(absDirPath)
	editor:directoryDropped(absDirPath)
end

function love.resize(w, h)
	camera:setViewport(0, 0, w, h)
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
