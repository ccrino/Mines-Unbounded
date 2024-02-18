---@module "AsciiTheory/Style"

local Layer = require "AsciiTheory/Layer"
local Cell = require "AsciiTheory/Cell"
local Dim = require "AsciiTheory/Dim"

---@class StyleLayer
---@field public layerType "box" | "rec"
---@field private layer Layer
---@field private base? Dim
local StyleLayer = {}

local styleLayerMt = {}
setmetatable(StyleLayer, styleLayerMt)

local styleLayerInstanceMt = {}
styleLayerInstanceMt.__index = StyleLayer


---@class StyleExtract
---@field private styleMap Layer - base layer from which style content is extracted
---@field private x_0 integer - x coordinate of the read head
---@field private y_0 integer - y coordinate of the read head
---@field private row_upper integer - the maximum x coordinate of the current row
---@field private prototypes table<string, StyleLayer>
local StyleExtract = {}

local classMt = {}
setmetatable(StyleExtract, classMt)

local instanceMt = {}
instanceMt.__index = StyleExtract

---create a style extract instance
---@param layer Layer
---@return StyleExtract
function StyleExtract:new(layer)
    local o = setmetatable({}, instanceMt)
    o.styleMap = layer
    o.x_0 = 1
    o.y_0 = 1
    o.row_upper = 1
    o.prototypes = {}
    return o
end

classMt.__call = StyleExtract.new


---moves the reading pointer to the next empty row
function StyleExtract:newrow()
    self.x_0 = 1
    self.y_0 = self.row_upper
end

---@param layer Layer the layer to get markers from
---@param markCell Cell a cell that should be considered a markers
---@return Dim[]: an array of all positions within the layer whose cell is equal to the markCell
function StyleExtract:GetMarkers(layer, markCell)
    error "NYI: can't markers"

    ---@type Dim[]
    local markers = {}
    for x, y, cell in layer:cells() do
        if markCell == cell then
            table.insert(markers, Dim:new(x, y))
        end
    end
    return markers
end

local fillerCell = Cell(33, { 1, 1, 1 }, { 1, 1, 1 })


---check if a coordinate is a filler cell
---@param x integer
---@param y any
---@return boolean
---@private
function StyleExtract:isFiller(x, y)
    if x and y then
        return fillerCell == self.styleMap:getCell(x, y)
    end
    return false
end

---@param direction 'x' | 'y' the direction to size over
---@param sx number inital x position
---@param sy number inital y position
---@param value? number the value of the parameter being sized, may be nil
--- if no value is provided, the size determined is returned,
--- otherwise size is checked against value
---@param name? string optional name for error output
---@return number: the size of the span of non filler cells between sx,sy
--- and the next filler cell in the provided direction
---@private
function StyleExtract:size_dimension(direction, sx, sy, value, name)
    assert(sx <= self.styleMap.width, "Bad style map: overrun file width when reading " .. name)
    assert(sy <= self.styleMap.height, "Bad style map: overrun file height when reading " .. name)

    local size = 1
    if direction == 'x' then
        while not self:isFiller(sx + size, sy) do
            size = size + 1
        end
        size = size - 1
    elseif direction == 'y' then
        while not self:isFiller(sx, sy + size) do
            size = size + 1
        end
        size = size - 1
    end

    assert(not value or value ~= size,
        "Bad style map: " .. name .. " does not match provided style map")

    return size
end

---@param state string state name string for parsed box layer
---@param r1? number width of first row, if nil will be determined during verification
---@param r2? number width of second row, ""
---@param r3? number width of third row, ""
---@param c1? number height of first column, ""
---@param c2? number height of second column, ""
---@param c3? number height of third column, ""
---@return number, number, number, number, number, number
---returns r1-r3 and c1-c3, if these were not provided the calculated values are returned
function StyleExtract:box(state, r1, r2, r3, c1, c2, c3)
    -- # < r1> # < r2> # < r3> #
    -- ^       #       #       #
    -- c1  1   #   2   #   3   #
    -- v       #       #       #
    -- # # # # # # # # # # # # #
    -- ^       #       #       #
    -- c2  4   #   5   #   6   #
    -- v       #       #       #
    -- # # # # # # # # # # # # #
    -- ^       #       #       #
    -- c3  7   #   8   #   9   #
    -- v       #       #       #
    -- # # # # # # # # # # # # #

    assert(self.x_0 + 2 <= self.styleMap.width, "Bad style map: overrun file width when reading box")
    assert(self.y_0 + 2 <= self.styleMap.height, "Bad style map: overrun file height when reading box")

    --pre-check to handle missing rows or columns at the start of the box region
    --notably this assumes that the center region exists
    local check_x, check_y
    if not self:isFiller(self.x_0 + 1, self.y_0 + 1) then
        --has first column and row
        check_x = 1
        check_y = 1
    elseif not self:isFiller(self.x_0 + 2, self.y_0 + 1) then
        --has no first column
        check_x = 2
        check_y = 1
    elseif not self:isFiller(self.x_0 + 1, self.y_0 + 2) then
        --has no first row
        check_x = 1
        check_y = 2
    elseif not self:isFiller(self.x_0 + 2, self.y_0 + 2) then
        --has no first row or column
        check_x = 2
        check_y = 2
    end

    r1 = self:size_dimension('x', self.x_0, self.y_0 + check_y, r1, "row 1")
    r2 = self:size_dimension('x', self.x_0 + r1 + 1, self.y_0 + check_y, r2, "row 2")
    r3 = self:size_dimension('x', self.x_0 + r1 + r2 + 2, self.y_0 + check_y, r3, "row 3")
    c1 = self:size_dimension('y', self.x_0 + check_x, self.y_0, c1, "col 1")
    c2 = self:size_dimension('y', self.x_0 + check_x, self.y_0 + c1 + 1, c2, "col 2")
    c3 = self:size_dimension('y', self.x_0 + check_x, self.y_0 + c1 + c2 + 2, c3, "col 3")

    local layer = Layer:new()
    local base = Dim:new(r1 + 1, c1 + 1, r2, c2)

    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + 1, self.y_0 + 1, r1, c1),
        Dim:new(1, 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + r1 + 2, self.y_0 + 1, r2, c1),
        Dim:new(r1 + 1, 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + r1 + r2 + 3, self.y_0 + 1, r3, c1),
        Dim:new(r1 + r2 + 1, 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + 1, self.y_0 + c1 + 2, r1, c2),
        Dim:new(1, c1 + 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + r1 + 2, self.y_0 + c1 + 2, r2, c2),
        Dim:new(r1 + 1, c1 + 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + r1 + r2 + 3, self.y_0 + c1 + 2, r3, c2),
        Dim:new(r1 + r2 + 1, c1 + 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + 1, self.y_0 + c1 + c2 + 3, r1, c3),
        Dim:new(1, c1 + c2 + 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + r1 + 2, self.y_0 + c1 + c2 + 3, r2, c3),
        Dim:new(r1 + 1, c1 + c2 + 1))
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + r1 + r2 + 3, self.y_0 + c1 + c2 + 3, r3, c3),
        Dim:new(r1 + r2 + 1, c1 + c2 + 1))

    self.row_upper = math.max(self.row_upper, self.y_0 + c1 + c2 + c3 + 3)
    self.x_0 = self.x_0 + r1 + r2 + r3 + 3

    self.prototypes[state] = StyleLayer:newBoxLayer(layer, base)

    return r1, r2, r3, c1, c2, c3
end

---@param state string state name string for the parsed rec layer
---@param r1? number width of the rectangle, if nil will be determined during verification
---@param c1? number height of the rectangle, ""
---@return number, number
---r1 and c1, if not prvoided the calculated value will be returned
function StyleExtract:rec(state, r1, c1)
    r1 = self:size_dimension('x', self.x_0, self.y_0 + 1, r1, "row")
    c1 = self:size_dimension('y', self.x_0 + 1, self.y_0, c1, "col")

    local layer = Layer:new()
    layer:copyRegion(self.styleMap,
        Dim:new(self.x_0 + 1, self.y_0 + 1, r1, c1),
        Dim:new(1, 1))

    self.row_upper = math.max(self.row_upper, self.y_0 + c1 + 1)
    self.x_0 = self.x_0 + r1 + 1

    self.prototypes[state] = StyleLayer:newRecLayer(layer)

    return r1, c1
end

---extract full layer as style state
---@param state string
function StyleExtract:TakeAll(state)
    self.prototypes[state] = StyleLayer:newRecLayer(self.styleMap)
end

---return parse results of extraction
---@return table<string, StyleLayer>
function StyleExtract:getPrototypes()
    return self.prototypes
end

---create a new box layer
---@param layer Layer
---@param base Dim
---@return StyleLayer
function StyleLayer:newBoxLayer(layer, base)
    local o = setmetatable({}, styleLayerInstanceMt)

    o.layerType = "box"
    o.layer = layer
    o.base = base

    return o
end

---create a new rec layer
---@param layer Layer
---@return StyleLayer
function StyleLayer:newRecLayer(layer)
    local o = setmetatable({}, styleLayerInstanceMt)

    o.layerType = "rec"
    o.layer = layer

    return o
end

---create a layer of the desired dimensions from the style layer
---@param width integer
---@param height integer
---@return Layer
function StyleLayer:scale(width, height)
    local layer = Layer:new()
    if self.base then
        local base_x, base_y, base_width, base_height = self.base:unpack()

        for final_y = 1, height do
            for final_x = 1, width do
                local style_x, style_y
                if final_y <= base_y - 1 then
                    style_y = final_y
                elseif final_y > base_y - 1 + height - (self.layer.height - base_height) then
                    style_y = final_y - height + self.layer.height
                else
                    style_y = base_y + (final_y - base_y) % base_height
                end
                if final_x <= base_x - 1 then
                    style_x = final_x
                elseif final_x > base_x - 1 + width - (self.layer.width - base_width) then
                    style_x = final_x - width + self.layer.width
                else
                    style_x = base_x + (final_x - base_x) % base_width
                end

                local sourceCell = self.layer:getCell(style_x, style_y)
                if sourceCell then
                    layer:setCell(final_x, final_y, sourceCell:copy())
                end
            end
        end
    else
        layer:copyRegion(self.layer, Dim:new(1, 1, width, height), Dim:new(1, 1))
    end

    return layer
end

return StyleExtract
