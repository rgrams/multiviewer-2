
local script = {}

local zoomRate = 0.1

local images = {}

function script.init(self)
	Input.enable(self)
	self.msx, self.msy = 0, 0
	self.mwx, self.mwy = 0, 0
	self.lastmwx, self.lastmwy = 0, 0
	self.lastmsx, self.lastmsy = 0, 0
end

local function safeLoadNewImage(file)
	local success, img = pcall(love.graphics.newImage, file)
	if success then
		print(file, img)
		return img
	end
end

local function updateImageRect(img)
	img.lt, img.rt = img.x - img.w/2, img.x + img.w/2
	img.top, img.bot = img.y - img.h/2, img.y + img.h/2
end

local function addImage(imgData, name, x, y, sx, sy)
	x = x or 0;  y = y or 0;  sx = sx or 1;  sy = sy or 1
	local i = {
		img = imgData, name = name,
		x = x, y = y, sx = sx, sy = sy
	}
	local w, h = imgData:getDimensions()
	i.w, i.h = w, h
	i.ox, i.oy = w/2, h/2
	i.lt, i.rt, i.top, i.bot = x - w/2, x + w/2, y - h/2, y + h/2
	table.insert(images, i)
end

function script.draw(self)
	for i,v in ipairs(images) do
		love.graphics.draw(v.img, v.x, v.y, 0, v.sx, v.sy, v.ox, v.oy)
	end
	if self.hover then
		local img = self.hover
		love.graphics.setColor(1, 1, 0, 1)
		love.graphics.rectangle("line", img.lt, img.top, img.w*img.sx, img.h*img.sy)
	end
end

function love.filedropped(file)
	local path = file:getFilename()
	print("FILE DROPPED: " .. tostring(file:getFilename()))
	local img = safeLoadNewImage(file)
	if img then  addImage(img, path)  end
end

function love.directorydropped(path)
	print("DIRECTORY DROPPED: " .. tostring(path))
	love.filesystem.mount(path, "newImages")
	local files = love.filesystem.getDirectoryItems("newImages")
	for k,subPath in pairs(files) do
		subPath = "newImages/" .. subPath
		local info = love.filesystem.getInfo(subPath)
		if not info then
			print("ERROR: Can't get file info for path: \n  " .. subPath)
		elseif info.type == "file" then
			local img = safeLoadNewImage(subPath)
			if img then  addImage(img, subPath)  end
		end
	end
end

local function posOverlapsImage(img, x, y)
	return x < img.rt and x > img.lt and y < img.bot and y > img.top
end

local function updateHoverList(self, except)
	self.hoverList = {}
	for i,img in ipairs(images) do
		if posOverlapsImage(img, self.mwx, self.mwy) then
			table.insert(self.hoverList, img)
		end
	end
end

function script.update(self, dt)
	self.msx, self.msy = love.mouse.getPosition()
	self.mwx, self.mwy = Camera.current:screenToWorld(self.msx, self.msy)

	if not self.drag then
		updateHoverList(self)
		self.hover = self.hoverList[1]
	elseif self.drag then -- Drag.
		local img = self.hover
		if img then
			local dx, dy = self.mwx - self.lastmwx, self.mwy - self.lastmwy
			img.x, img.y = img.x + dx, img.y + dy
			updateImageRect(img)
		end
	end

	if self.panning then
		local dx, dy = self.msx - self.lastmsx, self.msy - self.lastmsy
		dx, dy = Camera.current:screenToWorld(dx, dy, true)
		local camPos = Camera.current.pos
		camPos.x, camPos.y = camPos.x - dx, camPos.y - dy
	end

	self.lastmsx, self.lastmsy = self.msx, self.msy
	self.lastmwx, self.lastmwy = self.mwx, self.mwy
end

local function saveFile(fileName, text)
	print("saving file: " .. fileName)
	local file, err = io.open(fileName, "w")
	if not file then
		print(err)
		return
	else
		file:write(text)
		file:close()
		print("success", file)
		return true
	end
end

function script.input(self, name, value, change)
	shouldUpdate = true
	if name == "delete" and change == 1 then
		if self.hover then
			scene:remove(self.hover)
			self.hover = nil
		end
	elseif name == "left click" then
		if change == 1 then
			self.drag = true
		elseif change == -1 then
			self.drag = nil
			self.dropTarget = nil
		end
	elseif name == "zoom" then
		Camera.current:zoomIn(value * zoomRate)
	elseif name == "pan" then
		if value == 1 then
			self.panning = { x = Camera.current.pos.x, y = Camera.current.pos.y }
		else
			self.panning = nil
		end
	elseif name == "quit" and change == 1 then
		love.event.quit(0)
	end
end


return script
