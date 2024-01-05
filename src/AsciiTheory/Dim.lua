
---@class Dim
---@field public type "dim"
---@field public theory AsciiTheory
---@field public x number
---@field public y number
---@field public w number
---@field public h number
local Dim = {
	type = 'dim',
}

local classMt = {}
setmetatable(Dim, classMt)

local instanceMt = {
	__index = Dim
}

function Dim:new( x, y, w, h)
	local o = { x=x, y=y, w=w, h=h }
	setmetatable(o, instanceMt)
	return o
end
classMt.__call = Dim.new

function Dim:unpack( mul )
	if mul then
		return self.x * mul, self.y * mul, self.w * mul, self.h * mul
	end
	return self.x, self.y, self.w, self.h
end

function Dim:move( dx, dy )
	self.x = self.x + dx
	self.y = self.y + dy
end

return Dim