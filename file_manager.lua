
local M = {}

local json = require "lib.json"

M.fileExt = ".multiview"
local data = {}

function M.get_file_extension(path)
	local dotPos = string.find(path, "%.[^%.]+$") -- find pattern: dot, any number of non-dot characters, then end of string
	if dotPos then
		return string.sub(path, dotPos)
	else
		return nil
	end
end

function M.get_filename_from_path(path)
	return string.match(path, ".*[\\/]([^\\/%.]+)%.(.*)$")
end

function M.ensure_file_extension(path)
	if M.get_file_extension(path) == M.fileExt then
		return path
	else
		path = path .. M.fileExt
	end
	return path
end

function M.decode_project_file(path)
	if M.get_file_extension(path) ~= M.fileExt then  return  end
	local file = io.open(path, "r")
	local str = file:read("*a")
	file:close()
	if #str > 0 then
		return json.decode(str)
	else
		return {}
	end
end

function M.encode_project_file(data, path)
	local file = io.open(path, "w+")
	local str = json.encode(data)
	file:write(str)
	file:close()
end

return M
