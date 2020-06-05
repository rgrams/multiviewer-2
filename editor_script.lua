
local fileman = require "file_manager"

local script = {}

local baseTitle = "Multiviewer 2.0 - "
local zoomRate = 0.1

local floor = math.floor
local function round(x, interval)
	if interval then return floor(x / interval + 0.5) * interval end
	return floor(x + 0.5)
end

function script.init(self)
	self.msx, self.msy = 0, 0
	self.mwx, self.mwy = 0, 0
	self.lastmwx, self.lastmwy = 0, 0
	self.lastmsx, self.lastmsy = 0, 0
	self.images = {}
	self.projectFilePath = nil
	self.projectIsDirty = false
end

function script.draw(self)
	love.graphics.setColor(1, 1, 1, 1)
	for i,v in ipairs(self.images) do
		love.graphics.draw(v.img, v.x, v.y, 0, v.scale, v.scale, v.ox, v.oy)
	end
	if self.hoverImg then
		local img = self.hoverImg
		-- Draw outline around hovered image.
		love.graphics.setColor(0, 1, 1, 1)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", img.lt, img.top, img.w*img.scale, img.h*img.scale)

		if self.scaling then
			local z = camera.zoom

			-- Base scale line & end square.
			love.graphics.setLineWidth(4/z)
			love.graphics.setColor(0, 1, 1, 1)
			local vx, vy = vector.normalize(self.mwx - img.x, self.mwy - img.y)
			local x, y = img.x + vx * self.dragStartDist, img.y + vy * self.dragStartDist
			love.graphics.line(img.x, img.y, x, y)
			love.graphics.circle("fill", x, y, 6/z, 4)

			-- Base scale circle.
			local a = math.atan2(vy, vx)
			love.graphics.setLineWidth(1/z)
			love.graphics.setColor(0, 1, 1, 0.6)
			love.graphics.arc("line", "open", img.x, img.y, self.dragStartDist, a + 0.15, a + math.pi*2 - 0.15, 64)

			-- New scale circle.
			love.graphics.setColor(0, 0.5, 0.5, 0.8)
			local r = vector.len(self.mwx - img.x, self.mwy - img.y)
			love.graphics.arc("line", "open", img.x, img.y, r, a + 0.15, a + math.pi*2 - 0.15, 64)

			-- New scale line & end squares.
			love.graphics.setLineWidth(2/z)
			love.graphics.setColor(0, 0.5, 0.5, 1)
			love.graphics.line(img.x, img.y, self.mwx, self.mwy)
			love.graphics.circle("fill", self.mwx, self.mwy, 6/z, 4)
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.circle("fill", self.mwx, self.mwy, 3/z, 4)

			-- Draw scale factor text (with background box).
			love.graphics.push()
			love.graphics.scale(1/z, 1/z)

			local tx, ty = self.mwx*z + 10, self.mwy*z - 30
			local str = "x" .. round(self.dragScale, 0.001)
			local font = love.graphics.getFont()
			local fw, fh = font:getWidth("x1.000") + 9, font:getHeight() + 7
			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.rectangle("fill", tx -3, ty -2, fw, fh, 4, 4, 3)
			love.graphics.setColor(0.5, 0, 0, 1)
			love.graphics.print(str, tx, ty, 0, 1, 1)

			love.graphics.pop()
		end
	end
end

local function changeDepth(self, image, dir)
	local from
	for i,img in ipairs(self.images) do
		if img == image then
			from = i
			break
		end
	end
	if not from then  return  end
	local to = math.clamp(from + 1 * dir, 1, #self.images)
	if input.get("ctrl") then
		to = dir == 1 and #self.images or 1
	end
	if to ~= from then
		table.remove(self.images, from)
		table.insert(self.images, to, image)
	end
end

local function setDirty(self, dirty)
	if not self.projectFilePath then  return  end
	if dirty and not self.projectIsDirty then
		self.projectIsDirty = true
		local title = love.window.getTitle()
		title = title .. "*"
		love.window.setTitle(title)
	elseif not dirty and self.projectIsDirty then
		self.projectIsDirty = false
		local title = love.window.getTitle()
		title = string.sub(title, 1, -2)
		love.window.setTitle(title)
	end
end

local function updateImageRect(img)
	local w, h = img.w * img.scale, img.h * img.scale
	img.lt, img.rt = img.x - w/2, img.x + w/2
	img.top, img.bot = img.y - h/2, img.y + h/2
end

local function addImage(self, imgData, name, x, y, scale, dontDirty)
	if not dontDirty then  setDirty(self, true)  end
	x = x or 0;  y = y or 0;  scale = scale or 1
	local i = {
		img = imgData, name = name,
		x = x, y = y, scale = scale
	}
	local w, h = imgData:getDimensions()
	i.w, i.h = w, h
	i.ox, i.oy = w/2, h/2
	w, h = w * scale, h * scale
	i.lt, i.rt, i.top, i.bot = x - w/2, x + w/2, y - h/2, y + h/2
	table.insert(self.images, i)
	shouldUpdate = true
end

local function getImageFromAbsolutePath(path)
	local imgData
	local file, error = io.open(path, "rb")
	if error then
		print(error)
		return
	end
	local fileData, error = love.filesystem.newFileData(file:read("*a"), "new.jpg")
	file:close()
	if not error then
		return love.graphics.newImage(fileData)
	else
		print(error)
	end
end

local function safeLoadNewImage(file)
	local success, img = pcall(love.graphics.newImage, file)
	if success then
		return img
	end
end

function script.openProjectFile(self, absPath)
	local data = fileman.decode_project_file(absPath)
	if not data then  return  end

	if not self.projectFilePath then -- Use opened project as the current one.
		self.projectIsDirty = false
		self.projectFilePath = absPath
		if #self.images ~= 0 then  self.projectIsDirty = true  end

		local filename = fileman.get_filename_from_path(absPath)
		local title = baseTitle .. filename .. ".multiview "
		if self.projectIsDirty then  title = title .. "*"  end
		love.window.setTitle(title)

		if data.camera then -- Set camera pos and zoom from loaded data.
			local cd = data.camera
			camera.pos.x, camera.pos.y = cd.pos.x, -cd.pos.y
			camera.zoom = 1/cd.zoom
		end
	end

	-- Append images from opened project to the current workspace.
	local images = (data[1] and data or data.images) or {}
	for i,img in ipairs(images) do
		-- Save Format = { path, z, pos = { x, y }, size = { x, y } }
		local image = getImageFromAbsolutePath(img.path)
		if image then
			local w, h = image:getDimensions()
			local scale = img.size.x / w
			addImage(self, image, img.path, img.pos.x, -img.pos.y, scale, true)
		end
	end

	return data
end

-- Gets a Love File object with an absolute path filename.
function script.fileDropped(self, file)
	local absPath = file:getFilename()
	local img = safeLoadNewImage(file)
	if img then
		local x, y = self.mwx, self.mwy
		addImage(self, img, absPath, x, y)
	elseif fileman.get_file_extension(absPath) == fileman.fileExt then
		local data = script.openProjectFile(self, absPath)

	end
end

-- Gets the absolute path to a directory, which is allowed to be mounted with love.filesystem.
--   From that you can get the local and absolute paths of files in the directory.
function script.directoryDropped(self, absDirPath)
	love.filesystem.mount(absDirPath, "newImages")
	local files = love.filesystem.getDirectoryItems("newImages")
	local x, y = self.mwx, self.mwy
	for k,path in pairs(files) do
		local mountedPath = "newImages/" .. path
		local info = love.filesystem.getInfo(mountedPath)
		if not info then
			print("ERROR: Can't get file info for path: \n  " .. mountedPath)
		elseif info.type == "file" then
			local img = safeLoadNewImage(mountedPath)
			if img then  addImage(self, img, absDirPath .. "/" .. path, x, y)  end
		end
	end
end

local function makeProjectData(self)
	local data = { camera = {}, images = {} }

	-- Set camera data.
	local cd = data.camera
	cd.zoom = 1/camera.zoom
	cd.pos = { x = camera.pos.x, y = -camera.pos.y }

	-- Set image data.
	local id = data.images
	for i,img in ipairs(self.images) do
		-- Save Format = { path, z, pos = { x, y }, size = { x, y } }
		local iw, ih = img.img:getDimensions()
		local w, h = iw * img.scale, ih * img.scale
		id[i] = {
			path = img.name, z = i,
			pos = { x = img.x, y = -img.y }, size = { x = w, y = h }
		}
	end

	return data
end

local function saveProject(self)
	if self.projectFilePath then
		if self.projectIsDirty then
			local data = makeProjectData(self)
			fileman.encode_project_file(data, self.projectFilePath)
		end
	else
		print("WARNING: Save Project - No project file path, can't save.")
	end
end

local function posOverlapsImage(img, x, y)
	return x < img.rt and x > img.lt and y < img.bot and y > img.top
end

local function updateHoverList(self, except)
	self.hoverList = {}
	for i,img in ipairs(self.images) do
		if posOverlapsImage(img, self.mwx, self.mwy) then
			table.insert(self.hoverList, img)
		end
	end
end

function script.update(self, dt)
	self.msx, self.msy = love.mouse.getPosition()
	self.mwx, self.mwy = camera:screenToWorld(self.msx, self.msy)

	if self.dragging then
		local img = self.hoverImg
		if img then
			local x, y = self.mwx + self.dragx, self.mwy + self.dragy
			if x ~= img.x or y ~= img.y then  setDirty(self, true)  end
			img.x, img.y = x, y
			updateImageRect(img)
		end
	elseif self.scaling then
		local img = self.hoverImg
		if img then
			local ox, oy = img.x - self.mwx, img.y - self.mwy
			local newDist = vector.len(ox, oy)
			local scale = newDist / self.dragStartDist
			if scale ~= 1 then  setDirty(self, true)  end
			img.scale = self.dragStartScale * scale
			self.dragScale = scale
			updateImageRect(img)
		end
	else
		updateHoverList(self)
		self.hoverImg = self.hoverList[#self.hoverList]
	end

	if self.panning then
		local dx, dy = self.msx - self.lastmsx, self.msy - self.lastmsy
		if dx ~= 0 or dy ~= 0 then  setDirty(self, true)  end
		dx, dy = camera:screenToWorld(dx, dy, true)
		local camPos = camera.pos
		camPos.x, camPos.y = camPos.x - dx, camPos.y - dy
	end

	self.lastmsx, self.lastmsy = self.msx, self.msy
	self.lastmwx, self.lastmwy = self.mwx, self.mwy
end

function script.input(self, name, change)
	shouldUpdate = true
	if name == "click" then
		if change == 1 and self.hoverImg then
			self.dragging = true
			self.dragx, self.dragy = self.hoverImg.x - self.mwx, self.hoverImg.y - self.mwy
		elseif change == -1 then
			self.dragging = nil
			self.dropTarget = nil
		end
	elseif name == "scale" then
		if change == 1 and self.hoverImg and not self.scaling then
			self.scaling = true
			self.dragx, self.dragy = self.hoverImg.x - self.mwx, self.hoverImg.y - self.mwy
			self.dragStartDist = vector.len(self.dragx, self.dragy)
			self.dragStartScale = self.hoverImg.scale
		elseif change == -1 then
			self.scaling = false
		end
	elseif name == "zoom in" then
		setDirty(self, true)
		camera:zoomIn(zoomRate)
	elseif name == "zoom out" then
		setDirty(self, true)
		camera:zoomIn(-zoomRate)
	elseif name == "pan" then
		if change == 1 then
			self.panning = { x = camera.pos.x, y = camera.pos.y }
		else
			self.panning = nil
		end
	elseif name == "move up" and change == 1 then
		if self.hoverImg then
			changeDepth(self, self.hoverImg, 1)
		end
	elseif name == "move down" and change == 1 then
		if self.hoverImg then
			changeDepth(self, self.hoverImg, -1)
		end
	elseif name == "delete" and change == 1 then
		setDirty(self, true)
		if self.hoverImg then
			for i,v in ipairs(self.images) do
				if v == self.hoverImg then  table.remove(self.images, i)  end
			end
			self.hoverImg = nil
		end
	elseif name == "save" and change == 1 then
		if input.get("ctrl") then
			saveProject(self)
			setDirty(self, false)
		end
	elseif name == "copy" and change == 1 then
		if input.get("ctrl") and self.hoverImg then
			love.system.setClipboardText(self.hoverImg.name)
		end
	elseif name == "paste" and change == 1 then
		if input.get("ctrl") then
			local path = love.system.getClipboardText()
			local image = getImageFromAbsolutePath(path)
			if image then
				addImage(self, image, path, self.mwx, self.mwy)
			end
		end
	elseif name == "confirm" and change == 1 then
		if input.get("alt") then -- Toggle borderless.
			local w, h, flags = love.window.getMode()
			flags.borderless = not flags.borderless
			love.window.setMode(w, h, flags)
			shouldUpdate = true
		end
	elseif name == "quit" and change == 1 then
		love.event.quit(0)
	end
end

local mt = { __index = script }

function new(self)
	return setmetatable({}, mt)
end

return new
