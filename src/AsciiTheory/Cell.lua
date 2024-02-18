---@alias color {[1]: number, [2]: number, [3]: number}

---@class Cell
---@field public type "cell"
---@field public theory AsciiTheory
---@field public char integer
---@field private fg color | string
---@field private bg color | string
local Cell = {
    type = 'cell',
    __colorMap = {},
}
Cell.__index = Cell

local classMt = {}
setmetatable(Cell, classMt)

local instanceMt = {
    __index = Cell
}

---create a new cell
---@param char integer
---@param fg color | string
---@param bg color | string
---@return Cell
function Cell:new(char, fg, bg)
    assert(char, "no character passed to cell constructor")
    assert(fg, "no foreground color passed to cell constructor")
    assert(bg, "no background color passed to cell constructor")

    local cell = {}
    cell.char = char
    cell.fg = fg
    cell.bg = bg
    setmetatable(cell, instanceMt)
    return cell
end

---@overload fun(char: integer, fg: color|string, bg: color|string): Cell
classMt.__call = Cell.new

---duplicates a cell
---@param cell? Cell
---@return Cell
function Cell:copy(cell)
    if cell then
        return Cell:new(cell.char, cell.fg, cell.bg)
    end

    return Cell:new(self.char, self.fg, self.bg)
end

---returns the foreground color for the cell
---@return color
function Cell:getFg()
    return Cell:__mapColor(self.fg)
end

---returns the background color for the cell
---@return color
function Cell:getBg()
    return Cell:__mapColor(self.bg)
end

---adds a color mapping
---@param name string
---@param rgba color
function Cell:setMapColor(name, rgba)
    self.__colorMap[name] = rgba
end

---removes a color mapping
---@param name string
function Cell:clearMapColor(name)
    self.__colorMap[name] = nil
end

---converts mapped colors to literal colors
---@param rgbas string | color
---@return color
---@private
function Cell:__mapColor(rgbas)
    if type(rgbas) == "string" then
        return self.__colorMap[rgbas] or { 0, 0, 0 }
    else
        return rgbas
    end
end

---compares two Cells
---@param cell Cell
---@return boolean
function Cell:equals(cell)
    if not cell or cell.type ~= "cell" then
        return false
    elseif self.char == cell.char and
        self.fg[1] == cell.fg[1] and self.fg[2] == cell.fg[2] and self.fg[3] == cell.fg[3] and
        self.bg[1] == cell.bg[1] and self.bg[2] == cell.bg[2] and self.bg[3] == cell.bg[3]
    then
        return true
    end
    return false
end

instanceMt.__eq = Cell.equals

return Cell
