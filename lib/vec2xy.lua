
-- A basic library of vector2 operations using only x and y numbers.

local vec2    = {}
local vec2_mt = {} -- only used for __call = new

local acos    = math.acos
local atan2   = math.atan2
local sqrt    = math.sqrt
local cos     = math.cos
local sin     = math.sin
local PI = math.pi
local TWO_PI = math.pi*2

-- Make a new table with `x` and `y` elements.
--		This is the one outlier, just here for occasional convenience.
--		All the other functions specifically use x and y, NOT tables.
function vec2.new(x, y)
	return { x = x or 0, y = y or x or 0 }
end

function vec2.from_polar(r, th)
	return r * cos(th), r * sin(th)
end

-- Add a vector to another vector.
function vec2.add(ax, ay, bx, by)
	return ax + bx, ay + by
end

-- Subtract a vector from another vector.
function vec2.sub(ax, ay, bx, by)
	return ax - bx, ay - by
end

-- Multiply a vector by a scalar or another vector.
function vec2.mul(ax, ay, bx, by)
	if by then
		return ax * bx, ay * by -- vector
	end
	return ax * bx, ay * bx -- scalar
end

-- Divide a vector by another vector.
function vec2.div(ax, ay, bx, by)
	return ax / bx, ay / by
end

-- Get the normalized version of a vector.
function vec2.normalize(ax, ay)
	if not (ax == 0 and ay == 0) then
		local m = vec2.len(ax, ay)
		return ax / m, ay / m
	end
	return 0, 0
end

-- Trim a vector to a given length.
function vec2.trim(ax, ay, len)
	local l = vec2.len(ax, ay)
	if l > len then
		return ax / l * len, ay / l * len
	end
	return ax, ay
end

-- Clamp a vector's length to be between two scalars.
function vec2.clamp(ax, ay, min, max)
	local cur_l = vec2.len(ax, ay)
	local new_l = cur_l > min and (cur_l < max and cur_l or max) or min
	if new_l == cur_l then
		return ax, ay
	end
	return ax / cur_l * new_l, ay / cur_l * new_l
end

-- Get the cross product of two vectors.
function vec2.cross(ax, ay, bx, by)
	return ax * by - ay * bx
end

-- Get the dot product of two vectors.
function vec2.dot(ax, ay, bx, by)
	return ax * bx + ay * by
end

-- Get the length of a vector.
function vec2.len(ax, ay)
	return sqrt(ax * ax + ay * ay)
end

-- Get the squared length of a vector.
function vec2.len2(ax, ay)
	return ax * ax + ay * ay
end

-- Get the distance between two vectors.
function vec2.dist(ax, ay, bx, by)
	local dx = ax - bx;  local dy = ay - by
	return sqrt(dx * dx + dy * dy)
end

-- Get the squared distance between two vectors.
function vec2.dist2(ax, ay, bx, by)
	local dx = ax - bx;  local dy = ay - by
	return dx * dx + dy * dy
end

-- Rotate a vector.
function vec2.rotate(ax, ay, phi)
	local c = cos(phi);  local s = sin(phi)
	return c * ax - s * ay, s * ax + c * ay
end

-- Get the perpendicular vector of a vector.
function vec2.perpendicular(ax, ay)
	return -ay, ax
end

-- Get the smallest, signed angle from one vector to another.
function vec2.angle_between(ax, ay, bx, by)
	return atan2(ax * by - ay * bx, ax * bx + ay * by)
end

function vec2.angle(x, y)
	return atan2(y, x)
end

-- Lerp between two vectors.
function vec2.lerp(ax, ay, bx, by, s)
	return ax + (bx - ax) * s, ay + (by - ay) * s
end

-- Lerp between two vectors based on time.
function vec2.lerpdt(ax, ay, bx, by, s, dt)
	local k = 1 - 0.5^(dt*s)
	return ax + (bx - ax) * k, ay + (by - ay) * k
end

-- Return a formatted string.
function vec2.to_string(ax, ay)
	return string.format("(%+0.3f,%+0.3f)", ax, ay)
end

function vec2_mt.__call(_, x, y)
	return vec2.new(x, y)
end

return setmetatable(vec2, vec2_mt)
