local threadCode = [[
require "love.filesystem"
require "love.image"
require "love.timer"

local _args = {...}
local self = _args[1]

local inChannel = love.thread.getChannel("paths")
local outChannel = love.thread.getChannel("images")
local errChannel = love.thread.getChannel("errors")

local function fromAbsolutePath(path)
	local file, error = io.open(path, "rb")
	if not file then  return nil, error  end
	local fileData, error = love.filesystem.newFileData(file:read("*a"), "image")
	file:close()
	if not fileData then  return nil, error  end
	return love.image.newImageData(fileData) -- Also nil or error.
end

local fromLocalPath = love.image.newImageData

local input = inChannel:pop()
while input do
	local nextInput = inChannel:pop()
	if input then
		local path, args = input.path, input.args
		local imageData, error = fromAbsolutePath(path) -- Can change this to the absolute version if needed.
		local isFinished = not nextInput and self
		if imageData then
			outChannel:push({ imageData = imageData, path = path, args = args, isFinished = isFinished })
		else
			errChannel:push({ "load image", path = path, error = error, isFinished = isFinished })
			print(error)
		end
	end
	input = nextInput
end
]]

local M = {}

local maxThreads = love.system.getProcessorCount() - 1
local isRunning = false
local inChannel = love.thread.getChannel("paths")
local outChannel = love.thread.getChannel("images")
local runningThreads = {}
local stoppedThreads = {}

local function start()
	if #runningThreads >= maxThreads then  return  end
	local thread = table.remove(stoppedThreads) or love.thread.newThread(threadCode)
	table.insert(runningThreads, thread)
	thread:start(thread)
end

function M.load(path, ...)
	inChannel:push({ path = path, args = {...} })
	start()
	isRunning = true
end

local function threadFinished(finishedThread)
	for i,thread in ipairs(runningThreads) do
		if thread == finishedThread then
			table.remove(runningThreads, i)
			table.insert(stoppedThreads, finishedThread)
			return
		end
	end
end

function M.update(caller, onImageLoad, onFinishLoading)
	if not isRunning then  return false  end
	local data = outChannel:pop()
	while data do
		local image = love.graphics.newImage(data.imageData)
		onImageLoad(caller, image, data)
		if data.isFinished then
			threadFinished(data.isFinished)
			if #runningThreads == 0 then
				onFinishLoading(caller)
				isRunning = false
			end
		end
		data = outChannel:pop()
	end
end

function M.getNext()
	return outChannel:pop()
end

return M
