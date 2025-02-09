require "common"
local palette_sets = require "colors"

---@alias RGB {[1]: number, [2]: number, [3]: number}
---@alias HSV {h: number, s: number, v: number}

---@alias base_palette { darkest: RGB, dark: RGB, normal: RGB, lighter: RGB, lightest: RGB }
---@alias ext_palette { bgdark: RGB, bglite: RGB, tiledark: RGB, tilelite: RGB, bghalodark: RGB, bghalolite: RGB, halodark: RGB, halolite: RGB }

---convert rgb to hsv
---@param color RGB
---@return HSV
local function rgbToHsv(color)
    local r, g, b = unpack(color)
    local hsv = {}

    local cMax = math.max(r, g, b)
    local cMin = math.min(r, g, b)
    local delta = cMax - cMin

    -- compute hue
    if delta == 0 then
        hsv.h = 0
    elseif cMax == r then
        hsv.h = 60 * ((g - b) / delta % 6)
    elseif cMax == g then
        hsv.h = 60 * ((b - r) / delta + 2)
    elseif cMax == b then
        hsv.h = 60 * ((r - g) / delta + 4)
    end

    -- compute saturation
    if cMax == 0 then
        hsv.s = 0
    else
        hsv.s = delta / cMax
    end

    -- compute value
    hsv.v = cMax

    return hsv
end

---convert hsv to rgb
---@param hsv HSV
---@return RGB
local function hsvToRgb(hsv)
    local c = hsv.v * hsv.s
    local x = c * (1 - math.abs((hsv.h / 60) % 2 - 1))
    local m = hsv.v - c

    local r, g, b
    if hsv.h < 60 then
        r, g, b = c, x, 0
    elseif hsv.h < 120 then
        r, g, b = x, c, 0
    elseif hsv.h < 180 then
        r, g, b = 0, c, x
    elseif hsv.h < 240 then
        r, g, b = 0, x, c
    elseif hsv.h < 300 then
        r, g, b = x, 0, c
    elseif hsv.h < 360 then
        r, g, b = c, 0, x
    end

    return { r + m, g + m, b + m }
end

---performs a rotation on the hue component of an HSV value
---@param hsv HSV
---@param deg number
---@return HSV
local function colorRotate(hsv, deg)
    local newH = hsv.h + deg

    while newH >= 360 do
        newH = newH - 360
    end
    while newH < 0 do
        newH = newH + 360
    end

    return {
        h = newH,
        s = hsv.s,
        v = hsv.v,
    }
end

---blends two colors by a specified mixing ratio
---@param color1 RGB
---@param color2 RGB
---@param t number
---@return RGB
local function colorBlend(color1, color2, t)
    return {
        color1[1] * (1 - t) + color2[1] * t,
        color1[2] * (1 - t) + color2[2] * t,
        color1[3] * (1 - t) + color2[3] * t,
    }
end


local function getHaloColor(color, angle)
    local hsv = rgbToHsv(color)
    if hsv.s < 0.15 then
        hsv.s = hsv.s + 0.15
    elseif hsv.s > 0.85 then
        hsv.s = hsv.s - 0.15
    end
    hsv = colorRotate(hsv, angle or 60)
    return hsvToRgb(hsv)
end

local gen_palette_ext = {}

for i, set in ipairs(palette_sets) do
    local pal_ext = {}

    pal_ext.bgdark = set.darker or colorBlend(set.darkest, set.dark, 0.5)
    pal_ext.bglite = colorBlend(set.darkest, set.dark, 1.0)
    pal_ext.tiledark = colorBlend(set.dark, set.normal, 1.0)
    pal_ext.tilelite = set.light or colorBlend(set.normal, set.lighter, 0.5)

    pal_ext.bghalodark = getHaloColor(pal_ext.bgdark, set.angle)
    pal_ext.bghalolite = getHaloColor(pal_ext.bglite, set.angle)
    pal_ext.halodark = getHaloColor(pal_ext.tiledark, set.angle)
    pal_ext.halolite = getHaloColor(pal_ext.tilelite, set.angle)

    for j = 1, 9 do
        pal_ext[j] = colorBlend(set.normal, COLORS[j], 0.75)
    end

    -- pal_ext.bgdark = {   0,  32/255,  64/255};
    -- pal_ext.bglite = {   0,  41/255,  83/255};
    -- pal_ext.tiledark = {   0,  70/255, 140/255};
    -- pal_ext.tilelite = {   0,  89/255, 178/255};
    -- pal_ext.bghalodark = {  81/255, 0, 107/255};
    -- pal_ext.bghalolite = {  96/255, 0, 128/255};
    -- pal_ext.halodark = { 163/255, 0, 217/255};
    -- pal_ext.halolite = { 191/255, 0, 255/255};

    gen_palette_ext[i] = pal_ext
end


local CONFIG_FILE = "unbounded.config"

---@class Config
---@field private paletteIndex integer
---@field private symbolColors table<VALUE, integer>
---@field private doCheckers boolean
local Config = {
    paletteIndex = 1,
    symbolColors = {
        [VALUE.FLAG] = 6,
        [VALUE.MINE] = 1,
        [VALUE.NONE] = 1, -- never used
        [VALUE.ONE] = 2,
        [VALUE.TWO] = 3,
        [VALUE.THREE] = 4,
        [VALUE.FOUR] = 5,
        [VALUE.FIVE] = 6,
        [VALUE.SIX] = 7,
        [VALUE.SEVEN] = 8,
        [VALUE.EIGHT] = 9,
    },
    doCheckers = true,
    gameMode = GAME_MODE.NORMAL,
}

---resets config to default values
---@param visualFineTuneOnly? boolean flag to only set defaults for visual fine tuning settings
function Config:setDefault(visualFineTuneOnly)
    if not visualFineTuneOnly then
        self.paletteIndex = 1
        self.gameMode = GAME_MODE.NORMAL
    end
    self.symbolColors[VALUE.FLAG] = 6
    self.symbolColors[VALUE.MINE] = 1
    self.symbolColors[VALUE.NONE] = 1 -- never used
    self.symbolColors[VALUE.ONE] = 2
    self.symbolColors[VALUE.TWO] = 3
    self.symbolColors[VALUE.THREE] = 4
    self.symbolColors[VALUE.FOUR] = 5
    self.symbolColors[VALUE.FIVE] = 6
    self.symbolColors[VALUE.SIX] = 7
    self.symbolColors[VALUE.SEVEN] = 8
    self.symbolColors[VALUE.EIGHT] = 9
    self.doCheckers = true
end

---gets the color for a specified symbol
---@param symbol VALUE
---@return RGB
function Config:getSymbolColor(symbol)
    return Config:getPaletteExt()[self.symbolColors[symbol]]
    -- return COLORS[self.symbolColors[symbol]]
end

---rotates the internal setting for a symbols color
---@param symbol VALUE
---@param direction direction
function Config:rotateSymbolColor(symbol, direction)
    if self.symbolColors[symbol] then
        self.symbolColors[symbol] = Utils.wrap(self.symbolColors[symbol] + direction, 1, 9)
    end
end

local function colorAsHex(colorRgb)
    return string.format("#%02x%02x%02x", colorRgb[1] * 255, colorRgb[2] * 255, colorRgb[3] * 255)
end

function Config:dumpColors()
    local pal_base = self:getPaletteBase()
    local pal_ext = self:getPaletteExt()

    for name, color in pairs(pal_base) do
        if type(color) == 'table' then
            print(("%-11s"):format(name) .. "=", colorAsHex(color))
        else
            print(("%-11s"):format(name) .. "=", color)
        end
    end

    for name, color in pairs(pal_ext) do
        if type(color) == 'table' then
            print(("%-11s"):format(name) .. "=", colorAsHex(color))
        else
            print(("%-11s"):format(name) .. "=", color)
        end
    end
end

function Config:invertPalette()
    for _, palette in ipairs(palette_sets) do
        palette.darkest, palette.lightest = palette.lightest, palette.darkest
        palette.dark, palette.lighter = palette.lighter, palette.dark
    end

    for index, palette in ipairs(gen_palette_ext) do
        local set = palette_sets[index]
        palette.bgdark = colorBlend(set.darkest, set.dark, 0.5)
        palette.bglite = colorBlend(set.darkest, set.dark, 1.0)
        palette.tiledark = colorBlend(set.dark, set.normal, 1.0)
        palette.tilelite = colorBlend(set.normal, set.lighter, 0.5)

        palette.bghalodark = getHaloColor(palette.bgdark)
        palette.bghalolite = getHaloColor(palette.bglite)
        palette.halodark = getHaloColor(palette.tiledark)
        palette.halolite = getHaloColor(palette.tilelite)
    end
end

---gets the base palette set in use
---@return base_palette
function Config:getPaletteBase()
    return palette_sets[self.paletteIndex]
end

---gets the ext palette set in use
---@return ext_palette
function Config:getPaletteExt()
    return gen_palette_ext[self.paletteIndex]
end

---returns a numeric unique value for the current palette
---@return integer
function Config:getPaletteNumber()
    return self.paletteIndex
end

---rotates the internal setting for a palette set
---@param direction direction
function Config:rotatePalette(direction)
    self.paletteIndex = Utils.wrap(self.paletteIndex + direction, 1, #palette_sets)
end

---gets whether checkers are configured on
---@return boolean
function Config:getShowChecks()
    return self.doCheckers
end

---toggles checkers
function Config:toggleShowChecks()
    self.doCheckers = not self.doCheckers
end

---gets the configured gameMode
---@return GAME_MODE
function Config:getGameMode()
    return self.gameMode
end

---rotates  the selected gameMode
---@param direction direction
function Config:rotateGameMode(direction)
    self.gameMode = Utils.wrap(self.gameMode + direction, 1, GAME_MODE_COUNT)
end

---loads a saved configuration file from the system
function Config:load()
    local file = love.filesystem.newFile(CONFIG_FILE)
    if not file:open('r') then return end

    local size = love.data.getPackedSize("HBBBBBBBBBBBBH")
    local data = file:read(size)
    local valid
    ---@diagnostic disable-next-line: assign-type-mismatch
    valid, self.paletteIndex, ---@diagnostic disable-next-line: assign-type-mismatch
    self.symbolColors[VALUE.FLAG],
    self.symbolColors[VALUE.MINE],
    self.symbolColors[VALUE.NONE],
    self.symbolColors[VALUE.ONE],
    self.symbolColors[VALUE.TWO],
    self.symbolColors[VALUE.THREE],
    self.symbolColors[VALUE.FOUR],
    self.symbolColors[VALUE.FIVE],
    self.symbolColors[VALUE.SIX],
    self.symbolColors[VALUE.SEVEN],
    self.symbolColors[VALUE.EIGHT], ---@diagnostic disable-next-line: assign-type-mismatch
    self.doCheckers, ---@diagnostic disable-next-line: assign-type-mismatch
    self.gameMode = pcall(love.data.unpack, "HBBBBBBBBBBBBH", data)

    if not valid then
        self:setDefault()
    else
        --validate settings are in range
        for symbol, color in pairs(self.symbolColors) do
            self.symbolColors[symbol] = Utils.wrap(color, 1, 9)
        end
        self.doCheckers = (self.doCheckers == 1)
        self.paletteIndex = Utils.wrap(self.paletteIndex, 1, #palette_sets)
        self.gameMode = Utils.wrap(self.gameMode, 1, GAME_MODE_COUNT)
    end

    file:close()
end

---saves the current configuration into a file
function Config:save()
    local file = love.filesystem.newFile(CONFIG_FILE)
    if not file:open('w') then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    file:write(love.data.pack("string", "HBBBBBBBBBBBBH",
        self.paletteIndex,
        self.symbolColors[VALUE.FLAG],
        self.symbolColors[VALUE.MINE],
        self.symbolColors[VALUE.NONE],
        self.symbolColors[VALUE.ONE],
        self.symbolColors[VALUE.TWO],
        self.symbolColors[VALUE.THREE],
        self.symbolColors[VALUE.FOUR],
        self.symbolColors[VALUE.FIVE],
        self.symbolColors[VALUE.SIX],
        self.symbolColors[VALUE.SEVEN],
        self.symbolColors[VALUE.EIGHT],
        self.doCheckers and 1 or 0,
        self.gameMode))
    file:close()
end

return Config
