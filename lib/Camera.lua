
local Camera = {}

-- Global default settings
Camera.viewport_align = { x = 0.5, y = 0.5 }
Camera.pivot = { x = 0.5, y = 0.5 }

-- localize stuff
local min = math.min
local max = math.max
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt

--##############################  Private Functions  ##############################

local function vec2(x, y)
	return { x = x or 0, y = y or 0 }
end

local function rotate(x, y, a) -- vector rotate with x, y
	local ax, ay = cos(a), sin(a)
	return ax*x - ay*y, ay*x + ax*y
end

function set_viewport(camera, x, y, w, h)
	local vp = camera.vp
	local aspect = camera.aspect_ratio
	local align = camera.viewport_align
	local pivot = camera.pivot
	if aspect then  -- letterbox
		vp.w = math.min(w, h * aspect)
		vp.h = vp.w / aspect
		vp.x = x + (w - vp.w) * align.x
		vp.y = y + (h - vp.h) * align.y
	else
		vp.x, vp.y, vp.w, vp.h = x, y, w, h
	end
	vp.pivot = {
		x = vp.x + vp.w * pivot.x,
		y = vp.y + vp.h * pivot.y
	}
	return vp
end

local function update_zoom_after_resize(z, scale_mode, old_w, old_h, new_w, new_h)
	if scale_mode == "expand view" then
		return z
	elseif scale_mode == "fixed area" then
		local new_a = new_w * new_h
		local old_a = old_w * old_h
		return z * sqrt(new_a / old_a) -- zoom is the scale on both axes, hence the square root
	elseif scale_mode == "fixed width" then
		return z * new_w / old_w
	elseif scale_mode == "fixed height" then
		return z * new_h / old_h
	else
		error("Camera - update_zoom_after_resize() - invalid scale mode: " .. tostring(scale_mode))
	end
end

--##############################  Public Functions ##############################

function Camera.setViewport(self, x, y, w, h)
	local vp_w, vp_h = self.vp.w, self.vp.h -- save last values
	-- Must enforce fixed aspect ratio before figuring zoom.
	set_viewport(self, x, y, w, h)
	self.zoom = update_zoom_after_resize(self.zoom, self.scale_mode, vp_w, vp_h, self.vp.w, self.vp.h)
end

function Camera.applyTransform(self)
	love.graphics.push()
	-- start at viewport pivot point
	love.graphics.origin()
	love.graphics.translate(self.vp.pivot.x, self.vp.pivot.y)
	-- view rot and translate are negative because we're really transforming the world
	love.graphics.rotate(-self.angle)
	love.graphics.scale(self.zoom, self.zoom)
	love.graphics.translate(-self.pos.x, -self.pos.y)
end

function Camera.resetTransform(self)
	love.graphics.pop()
end

function Camera.screenToWorld(self, x, y, is_delta)
	-- screen center offset
	if not is_delta then x = x - self.vp.pivot.x;  y = y - self.vp.pivot.y end
	x, y = x/self.zoom, y/self.zoom -- scale
	x, y = rotate(x, y, self.angle) -- rotate
	-- translate
	if not is_delta then x = x + self.pos.x;  y = y + self.pos.y end
	return x, y
end

function Camera.worldToScreen(self, x, y, is_delta)
	if not is_delta then x = x - self.pos.x;  y = y - self.pos.y end
	x, y = rotate(x, y, -self.angle)
	x, y = x*self.zoom, y*self.zoom
	if not is_delta then x = x + self.vp.pivot.x;  y = y + self.vp.pivot.y end
	return x, y
end

-- zoom in or out by a percentage
function Camera.zoomIn(self, z, xScreen, yScreen)
	local xWorld, yWorld
	if xScreen and yScreen then
		xWorld, yWorld = self:screenToWorld(xScreen, yScreen)
	end
	self.zoom = self.zoom * (1 + z)
	if xScreen and yScreen then
		local xScreen2, yScreen2 = self:worldToScreen(xWorld, yWorld)
		local dx, dy = xScreen2 - xScreen, yScreen2 - yScreen
		dx, dy = self:screenToWorld(dx, dy, true)
		self.pos.x, self.pos.y = self.pos.x + dx, self.pos.y + dy
	end
end

local mt = { __index = Camera }

function new(x, y, angle, zoom, scale_mode)
	self = {}
	self.pos = { x = x or 0, y = y or 0 }
	self.angle = angle or 0
	self.scale_mode = scale_mode or 'fixed area'

	self.zoom = zoom or 1
	self.vp = {}
	setmetatable(self, mt)
	set_viewport(self, 0, 0, love.graphics.getDimensions())
	return self
end

return new
