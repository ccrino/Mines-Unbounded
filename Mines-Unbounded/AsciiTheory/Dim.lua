
local Dim = {
    x = nil,
    y = nil,
    w = nil,
    h = nil
}
Dim.__index = Dim

function Dim:new( x, y, w, h)
	local o = { x=x, y=y, w=w, h=h }
	setmetatable(o, self)
	return o
end

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