local HC = require("HC")
local Layer = require("AsciiTheory/Layer")
local Cell = require("AsciiTheory/Cell")

local TextField = {
    -- non instance
    theory = nil,
    type = "textField",

    -- instance
    dim = nil,
    collider = nil,
    id = nil,
    text = nil,

    -- window ref
    parent = nil,
    tag = nil,
    children = {},

    -- optional parameters
    verticalAlign = nil,
    horizontalAlign = nil,
    overflow = nil,
    fillBackground = nil,
    width = nil,
    height = nil,

    -- temporary parameters !do not rely on
    fg = {1,1,1},
    bg = {0,0,0},
    repaint = false,
    layer = nil,
}
TextField.__index = TextField


function TextField:new( dim, text, id )
    local o = {}
    o.collider = HC.rectangle( dim:unpack(16) )
    o.dim = dim
    o.text = text
    o.id = id
    setmetatable(o, self)
    return o
end

function TextField:fromObject( o )
    o.text = o.text or ""
    if not o.dim then
        --todo handle unset dim
        error"TextField initialized without dimension"
    end
    o.collider = HC.rectangle( o.dim:unpack(16) )
    setmetatable( o, self)
    return o
end

function TextField:move(...)
    self.dim:move(...)
    self.collider:move(...)
    for _, child in pairs(self.children) do
        child:move(...)
    end
end

function TextField:paint()
    if self.repaint or not self.layer then
        local text = self.text
        local pos_x, pos_y, width, height = self.dim:unpack()

        -- split into the appropriate number of lines
        local lines = {}
        if text:len() > width then
            local line = ""
            for word in text:gmatch("%S+") do

                if line:len() + word:len() + 1 > width then
                    if line:len() > 0 then
                        table.insert(lines, line)
                        line = ""
                    end
                    while word:len() > width do
                        table.insert(lines, word:sub(1,width))
                        word = word:sub(width+1)
                    end
                    if word:len() == width then
                        table.insert(lines, word)
                    else
                        line = line .. word
                    end
                else
                    if line == "" then
                        line = word
                    else
                        line = line .. " " .. word
                    end
                end
            end
            if line:len() > 0 then
                table.insert(lines, line)
            end
        else
            lines[1] = text
        end
        local layer
        if self.fillBackground then
            layer = Layer:newSolid( self.dim, self.bg )
        else
            layer = Layer:new( pos_x, pos_y )
        end
        if #lines ~= 0 then
            local row_offsets = {}
            for i, line in ipairs(lines) do
                if not self.horizontalAlign or self.horizontalAlign == "min" then
                    row_offsets[i] = 0
                elseif self.horizontalAlign == "max" then
                    row_offsets[i] = width - line:len()
                elseif self.horizontalAlign == "center" then
                    row_offsets[i] = math.floor( (width - line:len()) / 2 )
                end
            end

            local column_offset = 0
            if #lines < height then
                if self.verticalAlign and self.verticalAlign ~= "min" then
                    if self.verticalAlign == "max" then
                        column_offset = 1 + height - #lines
                    elseif self.verticalAlign == "center" then
                        column_offset = 1 + math.floor( (height - #lines) / 2 )
                    end
                end
            end

            for i, line in ipairs(lines) do
                local y = i + column_offset
                for j = 1, line:len() do
                    local x = j + row_offsets[i]
                    local char = line:sub(j,j)
                    local code = self.theory.symbols[char]
                    layer:setCell( x, y, Cell:new( code, self.fg, self.bg))
                end
            end
        end
        self.layer = layer
    end
    self.theory.layers[self.tag] = self.layer
end

function TextField:setText( newText )
    self.text = newText
    self.repaint = true
    self.theory:repaint(self.tag)
end

return TextField