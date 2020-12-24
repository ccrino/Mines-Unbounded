local EXP = require("rexpaint")
local Layer = require("AsciiTheory/Layer")
local Cell = require("AsciiTheory/Cell")
local Dim = require("AsciiTheory/Dim")

local Style = {
    type = ""; -- one of button, ...
    prototypes = {};
}
Style.__index = Style

function Style:newButtonStyle( filename )
    local styleMap
    if filename then
        styleMap = Style.read( filename )
    else
        return nil
    end
    if  not styleMap:isFiller( 1, 1) then
        error("bad style map halting")
    end
    local prototypes = {}
    local temp = Dim:new( 2, 2, 1, 1 )
    local states = { "normal", "hovered", "pressed" }
    for _, state in pairs(states) do
        local base = Dim:new()
        local layer = Layer:new()
        local y_offset = {}
        for _x = 1, 3 do
            while not styleMap:isFiller( temp.x + temp.w, temp.y + temp.h - 1 ) do
                temp.w = temp.w + 1
            end
            local w = layer.width + 1
            for _y = 1, 3 do
                y_offset[_y] = y_offset[_y] or layer.height + 1
                while not styleMap:isFiller( temp.x + temp.w - 1, temp.y + temp.h ) do
                    temp.h = temp.h + 1
                end
                layer:copyRegion(styleMap, temp, Dim:new(w, y_offset[_y]))
                if _x == 1 and _y == 1 then
                    base.x = layer.width + 1
                    base.y = layer.height + 1
                elseif _x == 2 and _y == 2 then
                    base.w = temp.w
                    base.h = temp.h
                end
                temp.y = temp.y + temp.h + 1
                temp.h = 1
            end
            temp.y = 2
            temp.x = temp.x + temp.w + 1
            temp.w = 1
        end
        prototypes[state] = { layer=layer, base=base }
    end
    local style = {
        type = "button";
        prototypes = prototypes;
    }
    setmetatable(style, self)
    return style
end

--[[
    1 2 3 4 5 6 7 8 9 0  (2, 2, 3, 2) => ( 1, 1)
    2 X . . # X . # X #  (2, 5, 3, 1) => ( 1, 3)
    3 . . Y # . Y # Y #  (2, 7, 3, 3) => ( 1, 4)
    4 # # # # # # # # #
    5 X . Y # X Y # D #
    6 # # # # # # # # #
    7 X . . # X . # X #
    8 . . . # . . # . #
    9 . . Y # . Y # Y #
    0 # # # # # # # # #
]]

function Layer:isFiller( x, y)
    if self and x and y then
        local cell = self:getCell( x, y )
        return cell and cell.char == 33 and cell.fg[1] == 1 and cell.fg[2] == 1 and cell.fg[3] == 1
            and cell.bg[1] == 1 and cell.bg[2] == 1 and cell.bg[3] == 1
    end
    return nil
end

-- reads in a rx file with a single layer and extracts the layer in the internal format
function Style.read( filename )
	local rex_canvas
	if filename then
		rex_canvas = EXP:read( filename )
	else
		return {}
	end
    local layer = Layer:new()
    local rex_layer = rex_canvas.layers[1]
    layer.width = rex_layer.width
    layer.height = rex_layer.height
    for _, cell in ipairs(rex_layer.cells) do
        layer:setCell( cell.x+1, cell.y+1, Cell:new( cell.char, cell.fg, cell.bg) )
	end
	return layer
end

function Style:scale( width, height )
    local states = {}
    for state, data in pairs(self.prototypes) do
        local layer = Layer:new()
        local base_x, base_y, base_width, base_height = data.base:unpack()
        for final_y = 1, height do
            for final_x = 1, width do
                local style_x, style_y
                if final_y <= base_y - 1 then
                    style_y = final_y
                elseif final_y > base_y - 1 + height - (data.layer.height - base_height) then
                    style_y = final_y - height + data.layer.height
                else
                    style_y = base_y + (final_y-base_y) % base_height
                end
                if final_x <= base_x - 1 then
                    style_x = final_x
                elseif final_x > base_x - 1 + width - (data.layer.width - base_width) then
                    style_x = final_x - width + data.layer.width
                else
                    style_x =  base_x + (final_x-base_x) % base_width
                end
                layer:setCell( final_x, final_y, Cell:copy( data.layer:getCell( style_x, style_y) ) )
            end
        end
        states[state] = layer
    end
    return states
end

return Style