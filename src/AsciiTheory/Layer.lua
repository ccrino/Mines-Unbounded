local Cell = require("AsciiTheory/Cell")

---@class Layer
---@field public type "layer"
---@field public theory AsciiTheory
---@field public dx number
---@field public dy number
---@field public width number
---@field public height number
---@field private __cells table<number, table<number, Cell>>
local Layer = {
    type = "layer",
    width = 0,
    height = 0,
    dx = 0,
    dy = 0,
}

local classMt = {}
setmetatable(Layer, classMt)

local instanceMt = {
    __index = Layer
}

---creates a new layer
---@param x? number
---@param y? number
---@return Layer
function Layer:new(x, y)
    local o = {}
    o.__cells = {}
    o.width = 0
    o.height = 0
    o.dx = x or 0
    o.dy = y or 0
    setmetatable(o, instanceMt)
    return o
end

classMt.__call = Layer.new

---creates a new layer of solid color
---@param dim Dim
---@param bg color
---@return Layer
function Layer:newSolid(dim, bg)
    local layer = Layer:new(dim.x, dim.y)
    for i = 1, dim.h do
        for j = 1, dim.w do
            layer:setCell(j, i, Cell:new(33, { 0, 0, 0 }, bg))
        end
    end
    return layer
end

---moves the layer
---@param dx number
---@param dy number
function Layer:move(dx, dy)
    self.dx = self.dx + dx
    self.dy = self.dy + dy
end

---get a cell within the layer
---@param x number
---@param y number
---@return Cell | nil
function Layer:getCell(x, y)
    if x and y and self.__cells[y] then
        return self.__cells[y][x]
    end
    return nil
end

---sets a cell in the layer
---@param x number
---@param y number
---@param value Cell
function Layer:setCell(x, y, value)
    if x and y then
        self.__cells[y] = self.__cells[y] or {}
        self.__cells[y][x] = value
        self.height = math.max(self.height, y)
        self.width = math.max(self.width, x)
    end
end

---duplicates a region within sourceLayer to the designated location in this Layer
---@param sourceLayer Layer
---@param source Dim
---@param dest Dim
function Layer:copyRegion(sourceLayer, source, dest)
    for yi = 0, source.h - 1 do
        for xi = 0, source.w - 1 do
            local cell = sourceLayer:getCell(source.x + xi, source.y + yi)
            if cell then
                self:setCell(dest.x + xi, dest.y + yi, cell:copy())
            end
        end
    end
    self.width = math.max(self.width, dest.x + source.w - 1)
    self.height = math.max(self.height, dest.y + source.h - 1)
end

---iterates over every cell in Layer in no specified order
---@return fun(): integer | nil, integer | nil, Cell | nil
function Layer:cells()
    local cells = self.__cells
    local y, x, rowcells, cell
    return function()
        repeat
            if rowcells then
                x, cell = next(rowcells, x)

                if cell then
                    return x, y, cell
                end
            end
            y, rowcells = next(cells, y)
        until not y
    end
end

return Layer
