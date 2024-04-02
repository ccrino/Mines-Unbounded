local EXP = require "rexpaint"
local Layer = require "AsciiTheory/Layer"
local Cell = require "AsciiTheory/Cell"

local Reader = {
    mappedColors = {},
}

---reads the contents of a file into layers
---@param filename string
---@return Layer[]
function Reader:read(filename)
    if not filename then
        return {}
    end

    local rex_canvas = EXP:read(filename)
    local layers = {}
    for layer_key = 1, rex_canvas.layerCount do
        local rex_layer = rex_canvas.layers[layer_key]
        local layer = Layer:new()

        layer.width = rex_layer.width
        layer.height = rex_layer.height

        for _, rex_cell in ipairs(rex_layer.cells) do
            local mappedFg = self:mapColor(rex_cell.fg)
            local mappedBg = self:mapColor(rex_cell.bg)
            local cell = Cell:new(rex_cell.char, mappedFg, mappedBg)

            layer:setCell(rex_cell.x + 1, rex_cell.y + 1, cell)
        end

        table.insert(layers, layer)
    end

    return layers
end

---register a color to map to a color string
---@param name string
---@param rgba color
function Reader:registerMapColor(name, rgba)
    local colorString = Reader:toColorString(unpack(rgba))
    self.mappedColors[colorString] = name;
end

---unregister a previously mapped color string
---@param name string
function Reader:unregisterMapColor(name)
    for key, otherName in pairs(self.mappedColors) do
        if name == otherName then
            self.mappedColors[key] = nil
            return
        end
    end
end

---convert a rgba table to a color string if a mapping exists
---@param rgba color
---@return string|color
function Reader:mapColor(rgba)
    if type(rgba) ~= "table" then
        return rgba
    end
    local colorString = Reader:toColorString(unpack(rgba))
    return self.mappedColors[colorString] or rgba
end

---converts a color value triple into a hex string
---@param r number
---@param g number
---@param b number
---@return string
---@private
function Reader:toColorString(r, g, b)
    return string.format(
        "#%x%x%x",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255)
    )
end

return Reader
