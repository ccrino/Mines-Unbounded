

local Cell = {
    char = 1,
    fg = {0,0,0},
    bg = {0,0,0}
}
Cell.__index = Cell

function Cell:new( char, fg, bg )
    local cell = {}
    cell.char = char
    cell.fg = fg
    cell.bg = bg
    setmetatable(cell, self)
    return cell
end

function Cell:copy( cell )
    if cell then
        return self:new( cell.char, cell.fg, cell.bg)
    end
    return self:new( self.char, self.fg, self.bg )
end

return Cell