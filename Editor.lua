
local fileman = require "file_manager"
local threadedLoader = require "lib.threaded-loader"

local Editor = {}

local defaultWindowTitleName = "No project"
local zoomRate = 0.1
local dragZoomRate = 0.005

local floor = math.floor
local function round(x, interval)
	if interval then return floor(x / interval + 0.5) * interval end
	return floor(x + 0.5)
end

local function clamp(x, min, max)
	return x > min and (x < max and x or max) or min
end

function Editor.init(self)
	self.msx, self.msy = 0, 0
	self.mwx, self.mwy = 0, 0
	self.lastmwx, self.lastmwy = 0, 0
	self.lastmsx, self.lastmsy = 0, 0
	self.images = {}
	self.projectFilePath = nil
	self.projectIsDirty = false
	self.droppedGroups = {}
end

function Editor.draw(self)
	love.graphics.setColor(1, 1, 1, 1)
	for i,v in ipairs(self.images) do
		if v.img then
			love.graphics.draw(v.img, v.x, v.y, 0, v.scale, v.scale, v.ox, v.oy)
		end
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
	if self.isLoadingImages then
		love.graphics.setColor(1, 1, 1)
		love.graphics.push()
		love.graphics.origin()
		love.graphics.print("LOADING...", 10, 10)
		love.graphics.pop()
	end
end

local function setWindowTitle(self)
	local filename = self.projectFileName or defaultWindowTitleName
	local title = BASE_WINDOW_TITLE .. filename
	if self.projectIsDirty then  title = title .. "*"  end
	love.window.setTitle(title)
end

local function setDirty(self, dirty)
	if dirty and not self.projectIsDirty then
		self.projectIsDirty = true
		setWindowTitle(self)
	elseif not dirty and self.projectIsDirty then
		self.projectIsDirty = false
		setWindowTitle(self)
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
	local to = clamp(from + 1 * dir, 1, #self.images)
	if input.isPressed("ctrl") then
		to = dir == 1 and #self.images or 1
	end
	if to ~= from then
		table.remove(self.images, from)
		table.insert(self.images, to, image)
		setDirty(self, true)
	end
end

local function updateImageRect(img)
	local w, h = img.w * img.scale, img.h * img.scale
	img.lt, img.rt = img.x - w/2, img.x + w/2
	img.top, img.bot = img.y - h/2, img.y + h/2
end

local function loadImage(self, path, x, y, w, h, groupIdx, idxInGroup)
	local index = #self.images + 1
	self.images[index] = { path = path }
	self.isLoadingImages = true
	threadedLoader.load(path, path, index, x, y, w, h, groupIdx, idxInGroup)
end

function Editor.openProjectFile(self, absPath)
	local data = fileman.decode_project_file(absPath)
	if not data then  return  end

	if not self.projectFilePath then -- Use opened project as the current one.
		self.projectIsDirty = false
		self.projectFilePath = absPath
		self.projectFileName = fileman.get_filename_from_path(absPath)

		if #self.images ~= 0 then  self.projectIsDirty = true  end

		setWindowTitle(self)

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
		local x, y, w, h = img.pos.x, img.pos.y, img.size.x, img.size.y
		loadImage(self, img.path, x, y, w, h)
	end

	return data
end

local function openFile(self, file, x, y)
	local absPath = file:getFilename()
	if fileman.get_file_extension(absPath) == fileman.fileExt then
		Editor.openProjectFile(self, absPath)
	else
		loadImage(self, absPath, x, y)
		setDirty(self, true)
	end
end

function Editor.filesDropped(self, files)
	local count = #files
	if count == 1 then
		openFile(self, files[1], self.mwx, self.mwy)
		return
	end

	local dropGroup = {
		count = 0,
		loadedCount = 0,
		index = #self.droppedGroups + 1
	}
	table.insert(self.droppedGroups, dropGroup)
	local groupIdx = dropGroup.index
	for i,file in ipairs(files) do
		local absPath = file:getFilename()
		if fileman.get_file_extension(absPath) == fileman.fileExt then
			self:openProjectFile(absPath)
		else
			dropGroup.count = dropGroup.count + 1
			local x, y, w, h = nil, nil, nil, nil
			local idxInGroup = dropGroup.count
			loadImage(self, absPath, x, y, w, h, groupIdx, idxInGroup)
			setDirty(self, true)
		end
	end
end

local function setImage(self, index, image, x, y, w, h)
	local img = self.images[index]
	img.img = image
	img.x, img.y = x, -y
	img.w, img.h = image:getDimensions()
	img.ox, img.oy = img.w/2, img.h/2
	img.scale = w / img.w
	updateImageRect(img)
	shouldUpdate = true
end

local function sumImageSizes(imageGroup)
	local totalW, totalH = 0, 0
	for i=1,imageGroup.count do
		local data = imageGroup[i]
		if data then
			local w, h = data.image:getDimensions()
			totalW, totalH = totalW + w, totalH + h
		end
	end
	return totalW, totalH
end

local function setImagesInGrid(self, imageGroup)
	local count = imageGroup.count
	local totalW, totalH = sumImageSizes(imageGroup)
	local rows = math.floor(math.sqrt(count))
	local cols = math.ceil(count / rows)
	local width, height = (cols + 1) * totalW/count, (rows + 1) * totalH/count
	local tlx, tly = self.mwx - width/2, self.mwy - height/2
	local xSpacing = width/(cols + 1)
	local ySpacing = height/(rows + 1)
	for row=1,rows do
		for col=1,cols do
			local i = (row-1)*cols + col
			local data = imageGroup[i]
			if data then
				if not data.image then  break  end
				local x, y = tlx + col * xSpacing, tly + row * ySpacing
				setImage(self, data.index, data.image, x, y, data.image:getDimensions())
			end
		end
	end
end

-- Receives the absolute path to a directory, which is allowed to be mounted with love.filesystem.
--   From that you can get the local and absolute paths of files in the directory.
--	  Need to mount the directory to iterate over its files.
function Editor.directoryDropped(self, absDirPath)
	love.filesystem.mount(absDirPath, "newImages")
	local files = love.filesystem.getDirectoryItems("newImages")
	local x, y = self.mwx, self.mwy
	for _,path in pairs(files) do
		local mountedPath = "newImages/" .. path
		local info = love.filesystem.getInfo(mountedPath)
		if not info then
			print("ERROR: Can't get file info for path: \n  " .. mountedPath)
		elseif info.type == "file" then
			local absPath = absDirPath .. "/" .. path
			loadImage(self, absPath, x, y)
			setDirty(self, true)
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
			path = img.path, z = i,
			pos = { x = img.x, y = -img.y }, size = { x = w, y = h }
		}
	end

	return data
end

local function saveProject(self)
	if not self.projectFilePath then
		self.projectFileName = "_project" .. fileman.fileExt
		self.projectFilePath = love.filesystem.getWorkingDirectory() .. "/" .. self.projectFileName
		self.projectIsDirty = true
	end
	if self.projectIsDirty then
		local data = makeProjectData(self)
		fileman.encode_project_file(data, self.projectFilePath)
	end
end

local function onImageLoad(self, image, data)
	local args = data.args
	local path, index = args[1], args[2]
	local x, y = args[3] or self.mwx, args[4] or self.mwy
	local w, h = args[5], args[6]
	if not w or not h then
		w, h = image:getDimensions()
	end
	local groupIdx, idxInGroup = args[7], args[8]
	if groupIdx then
		local imageGroup = self.droppedGroups[groupIdx]
		if not imageGroup then
			print("Image load error for drop group "..tostring(groupIdx)..", but that group doesn't exist.")
		else
			imageGroup[idxInGroup] = { path = path, image = image, index = index }
			imageGroup.loadedCount = imageGroup.loadedCount + 1
			if imageGroup.loadedCount == imageGroup.count then
				setImagesInGrid(self, imageGroup)
			end
			return
		end
	end
	setImage(self, index, image, x, y, w, h)
end

local function onLoadError(self, data)
	local args = data.args
	local groupIdx = args[4]
	if groupIdx then
		local imageGroup = self.droppedGroups[groupIdx]
		if imageGroup then
			imageGroup.loadedCount = imageGroup.loadedCount + 1
			if imageGroup.loadedCount == imageGroup.count then
				setImagesInGrid(self, imageGroup)
			end
		end
	end
end

local function onFinishLoading(self)
	self.isLoadingImages = false
	shouldUpdate = true
end

local function posOverlapsImage(img, x, y)
	if not img.img then  return false  end
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

function Editor.update(self, dt)
	threadedLoader.update(self, onImageLoad, onLoadError, onFinishLoading)

	self.msx, self.msy = love.mouse.getPosition()
	self.mwx, self.mwy = camera:screenToWorld(self.msx, self.msy)

	if self.panning then
		local dx, dy = self.msx - self.lastmsx, self.msy - self.lastmsy
		if dx ~= 0 or dy ~= 0 then  setDirty(self, true)  end

		if input.isPressed("ctrl") then
			local z = -dy * dragZoomRate
			-- Zoom around the drag start position, since it's a bit weird to zoom
			-- around a moving cursor (you'd be dragging to zoom and change the zoom pos).
			camera:zoomIn(z, self.panning.x, self.panning.y)
		else
			dx, dy = camera:screenToWorld(dx, dy, true)
			local camPos = camera.pos
			camPos.x, camPos.y = camPos.x - dx, camPos.y - dy
		end

		-- Now that camera has moved, update mouse world pos for smoother dragging & scaling.
		self.mwx, self.mwy = camera:screenToWorld(self.msx, self.msy)
	end

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

	self.lastmsx, self.lastmsy = self.msx, self.msy
	self.lastmwx, self.lastmwy = self.mwx, self.mwy
end

function Editor.input(self, name, change)
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
		camera:zoomIn(zoomRate, self.msx, self.msy)
	elseif name == "zoom out" then
		setDirty(self, true)
		camera:zoomIn(-zoomRate, self.msx, self.msy)
	elseif name == "pan" then
		if change == 1 then
			self.panning = { x = self.msx, y = self.msy }
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
		if input.isPressed("ctrl") and not self.isLoadingImages then
			saveProject(self)
			setDirty(self, false)
		end
	elseif name == "copy" and change == 1 then
		if input.isPressed("ctrl") and self.hoverImg then
			love.system.setClipboardText(self.hoverImg.path)
		end
	elseif name == "paste" and change == 1 then
		if input.isPressed("ctrl") then
			local text = love.system.getClipboardText()
			for path in text:gmatch("[^\r\n]+") do
				loadImage(self, path)
				setDirty(self, true)
			end
		end
	elseif name == "confirm" and change == 1 then
		if input.isPressed("alt") then -- Toggle borderless.
			local w, h, flags = love.window.getMode()
			flags.borderless = not flags.borderless
			love.window.setMode(w, h, flags)
			shouldUpdate = true
		end
	elseif name == "quit" and change == 1 then
		love.event.quit(0)
	end
end

local mt = { __index = Editor }

function new(self)
	return setmetatable({}, mt)
end

return new
