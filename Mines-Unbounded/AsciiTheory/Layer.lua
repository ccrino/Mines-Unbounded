local Cell = require("AsciiTheory/Cell")

local Layer = {
    cells = {},
    width = 0,
    height = 0,
    dx = 0,
    dy = 0,
}
Layer.__index = Layer


function Layer:new( x, y )
    local o = {}
    o.cells = {}
    o.width = 0
    o.height = 0
    o.dx = x or 0
	o.dy = y or 0
    setmetatable( o, self )
	return o
end

function Layer:newSolid( dim, bg )
    local layer = self:new(dim.x, dim.y)
    for i = 1, dim.h do
        for j = 1, dim.w do
            layer:setCell( j, i, Cell:new( 33, {0,0,0}, bg))
        end
    end
    return layer
end

function Layer:move( dx, dy )
	self.dx = self.dx + dx
	self.dy = self.dy + dy
end

function Layer:getCell( x, y )
    if x and y and self.cells[y] then
        return self.cells[y][x]
    end
    return nil
end

function Layer:setCell( x, y, value )
    if x and y then
        self.cells[y] = self.cells[y] or {}
        self.cells[y][x] = value
        self.height = math.max(self.height, y)
        self.width = math.max(self.width, x)
    end
end

function Layer:copyRegion( sourceLayer, source, dest )
    for yi = 0, source.h - 1 do
        for xi = 0, source.w - 1 do
            self:setCell( dest.x + xi, dest.y + yi, sourceLayer:getCell( source.x + xi, source.y + yi ):copy() )
        end
    end
    self.width = math.max( self.width, dest.x + source.w - 1)
    self.height = math.max( self.height, dest.y + source.h - 1)
end

return Layer