
local M = {}

local json = require "lib.json"

M.fileExt = "multiview"
local data = {}

function M.get_file_extension(path)
	local dotPos = string.find(path, "%.[^%.]+$") -- find pattern: dot, any number of non-dot characters, then end of string
	if dotPos then
		return string.sub(path, dotPos+1)
	else
		return nil
	end
end

function M.get_filename_from_path(path)
	return string.match(path, ".*[\\/%.]([^.]*)%.multiview$")
end

function M.ensure_file_extension(path)
	local dotPos = string.find(path, "%.[^%.]+$")
	if dotPos and string.sub(path, dotPos+1) == M.fileExt then
		return path
	else
		path = path .. "." .. M.fileExt
	end
	return path
end

function M.decode_project_file(path)
	local f = io.open(path, "r")
	local str = f:read("*a")
	if #str > 0 then
		return json.parse(str)
	else
		return {}
	end
end

return M
