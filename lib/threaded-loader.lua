local threadCode = [[
require "love.filesystem"
require "love.image"
require "love.timer"

local _args = {...}
local self = _args[1]

local inChannel = love.thread.getChannel("paths")
local outChannel = love.thread.getChannel("images")

local function fromAbsolutePath(path)
	local file, error = io.open(path, "rb")
	if not file then  return nil, error  end
	local fileData, error = love.filesystem.newFileData(file:read("*a"), "image")
	file:close()
	if not fileData then  return nil, error  end
	local isSuccess, result = pcall(love.image.newImageData, fileData) -- Nil or error.
	if isSuccess then
		return result
	else
		return nil, result
	end
end

local fromLocalPath = love.image.newImageData

local input = inChannel:pop()
if not input then
	outChannel:push({ finishedThread = self })
end
while input do
	local nextInput = inChannel:pop()
	if input then
		local path, args = input.path, input.args
		local imageData, error = fromAbsolutePath(path) -- Can change this to the absolute version if needed.
		local finishedThread = not nextInput and self
		if imageData then
			outChannel:push({ imageData = imageData, path = path, args = args, finishedThread = finishedThread })
		else
			outChannel:push({ error = error, path = path, args = args, finishedThread = finishedThread })
			print("Error in loader thread:", error, "\n   For path: "..tostring(path))
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

local function finalizeThread(thread, caller, onFinishLoading)
	threadFinished(thread)
	if #runningThreads == 0 then
		onFinishLoading(caller)
		isRunning = false
	end
end

function M.update(caller, onImageLoad, onLoadError, onFinishLoading)
	if not isRunning then  return false  end
	local data = outChannel:pop()
	while data do
		if data.error then
			onLoadError(caller, data)
		elseif data.path then -- No path if -just- a "thread finished" entry (for threads that end without doing anything).
			local image = love.graphics.newImage(data.imageData)
			onImageLoad(caller, image, data)
		end
		if data.finishedThread then
			finalizeThread(data.finishedThread, caller, onFinishLoading)
		end
		data = outChannel:pop()
	end
end

function M.getNext()
	return outChannel:pop()
end

return M
