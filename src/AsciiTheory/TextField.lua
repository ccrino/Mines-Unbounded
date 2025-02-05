local HC = require "HC"
local Utils = require "AsciiTheory/Utils"
local Dim = require "AsciiTheory/Dim"
local Layer = require "AsciiTheory/Layer"
local Cell = require "AsciiTheory/Cell"
local ViewObject = require "AsciiTheory/ViewObject"
local SymbolDictionary = require "AsciiTheory/SymbolDictionary"

---@class TextField : ViewObject
---@field public type "textField"
---@field public dim Dim
---@field public id? string
---@field public parent? table
---@field public tag? integer
---@field public children table[]
---@field public verticalAlign? "min" | "center" | "max"
---@field public horizontalAlign? "min" | "center" | "max"
---@field public overflow? string
---@field public fillBackground? string
---@field public width? number
---@field public height? number
---@field protected collider table
---@field private text string
---@field private fg color
---@field private bg color
---@field private layer Layer
---@field private repaint boolean
local TextField = {
    -- non instance
    type = "textField",
}

local classMt = {
    __index = ViewObject
}
setmetatable(TextField, classMt)

local instanceMt = {
    __index = TextField
}

---creates a new text field
---@param dim Dim
---@param text string
---@param id? string
---@return TextField
function TextField:new(dim, text, id)
    local o = ViewObject()
    o.collider = HC.rectangle(dim:unpack(16))
    o.dim = dim
    o.text = text
    o.id = id
    o.fg = { 1, 1, 1 }
    o.bg = { 0, 0, 0 }
    setmetatable(o, instanceMt)
    return o
end

classMt.__call = TextField.new

---creates a new text field from an object base
---@param o table
---@return TextField
function TextField:fromObject(o)
    ViewObject:fromObject(o)

    assert(o.dim, "TextField initialized without dimension")

    o.text = o.text or ""
    o.fg = o.fg or { 1, 1, 1 }
    o.bg = o.bg or { 0, 0, 0 }
    o.collider = HC.rectangle(o.dim:unpack(16))
    setmetatable(o, instanceMt)
    return o
end

---move the textfield instance
---@param dx integer
---@param dy integer
function TextField:__onMove(dx, dy)
    self.collider:move(dx, dy)
    self.dim:move(dx, dy)
end

---gets the layer for the textfield
---@return Layer, Dim
function TextField:__onPaintLayer()
    if self.repaint or not self.layer then
        local text = self.text
        local width = self.dim.w
        local height = self.dim.h

        local lines = Utils.SplitTextIntoLines(text, width)

        local layer
        if self.fillBackground then
            layer = Layer:newSolid(Dim(0, 0, width, height), self.bg)
        else
            layer = Layer:new()
        end

        if #lines > 0 then
            local column_offset = Utils.GetOffsetForAlignment(self.verticalAlign, #lines, height)
            for i, line in ipairs(lines) do
                local y = i + column_offset
                if y > height then
                    break
                end

                local row_offset = Utils.GetOffsetForAlignment(self.horizontalAlign, utf8.len(line), width)
                for j = 1, utf8.len(line) do
                    local x = j + row_offset
                    if x > width then
                        break
                    end

                    local char = line:sub(utf8.offset(line, j), utf8.offset(line, j + 1) - 1)
                    local code = SymbolDictionary[char]
                    layer:setCell(x, y, Cell:new(code, self.fg, self.bg))
                end
            end
        end
        self.layer = layer
    end

    return self.layer, self.dim
end

---sets the text field to a new string
---@param newText any
function TextField:setText(newText)
    self.text = newText
    self.repaint = true
    self:__repaintSelf()
end

ViewObject:registerViewObjectClass(TextField)

return TextField
