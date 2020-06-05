
local M = {}

local actions = {}
local bindings = {
	key = {},
	scancode = {},
	mouse = {},
	wheel = {}
}

function M.callback(name, change)
end

function M.isPressed(name)
	if actions[name] then
		return actions[name].isPressed
	end
end

local function newAction()
	return { isPressed = false, pressCount = 0 }
end

function M.bind(device, button, action)
	bindings[device][button] = action
	actions[action] = actions[action] or newAction()
end

local function pressAction(actionName, isWheel)
	local a = actions[actionName]
	if a then
		a.isPressed = true
		a.pressCount = a.pressCount + 1
		if a.pressCount == 1 then  M.callback(actionName, 1)  end
		if isWheel then  a.pressCount = 0  end
	end
end

local function releaseAction(actionName)
	local a = actions[actionName]
	if a then
		a.pressCount = a.pressCount - 1
		if a.pressCount == 0 then
			a.isPressed = false
			M.callback(actionName, -1)
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	pressAction(bindings.key[key])
	pressAction(bindings.scancode[scancode])
end

function love.keyreleased(key, scancode)
	releaseAction(bindings.key[key])
	releaseAction(bindings.scancode[scancode])
end

function love.mousepressed(x, y, button, isTouch)
	pressAction(bindings.mouse[button])
end

function love.mousereleased(x, y, button, isTouch)
	releaseAction(bindings.mouse[button])
end

function love.wheelmoved(x, y)
	if y ~= 0 then  pressAction(bindings.wheel[y], true)  end
end

return M
