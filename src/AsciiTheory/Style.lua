local Reader = require "AsciiTheory/Reader"
local StyleExtract = require "AsciiTheory/StyleExtract"
local Layer = require "AsciiTheory/Layer"
local Cell = require "AsciiTheory/Cell"
local Dim = require "AsciiTheory/Dim"

---@alias StyleParserFunction fun(styleExtractor: StyleExtract)


---@class Style
---@field public theory AsciiTheory
---@field public styleType string
---@field private __isDefinition boolean
---@field private __definitionTypeMap table<string, table<string, Style>>
---@field private __typeParserMap table<string, StyleParserFunction>
---@field private __prototypes table<string, StyleLayer>
local Style = {
    __definitionTypeMap = {},
    __typeParserMap = {},
}

local styleClassMt = {}
setmetatable(Style, styleClassMt)

local styleDefinitionMt = {}
styleDefinitionMt.__index = Style


---@class StyleInstance
---@field private __definition Style style reference
---@field private __needsScaling boolean
---@field private __dim Dim
local StyleInstance = {}

local instanceClassMt = {}
setmetatable(StyleInstance, instanceClassMt)

local styleInstanceMt = {}
styleInstanceMt.__index = StyleInstance


---defines the parser logic for converting layers
---into style objects
---@param class table Class object
---@param parser StyleParserFunction
function Style:defineStyleParser(class, parser)
    self.__typeParserMap[class.type] = parser
end

---Creates new styles for a class
---@param class table Class object
---@param styles table<string, string> table mapping style name to filepath
function Style:newStyles(class, styles)
    for name, filename in pairs(styles) do
        Style:newStyle(class, name, filename)
    end
end

---Creates a new style for a class
---@param class table Class object
---@param name string name of new style
---@param filename string filepath
function Style:newStyle(class, name, filename)
    local styleMap
    if filename then
        local layers = Reader:read(filename)
        styleMap = layers[1] or {}
    end

    local SE = StyleExtract(styleMap)
    local parser = self.__typeParserMap[class.type]

    parser(SE)

    local styleDef = setmetatable({}, styleDefinitionMt)

    styleDef.__isDefinition = true
    styleDef.__prototypes = SE:getPrototypes()
    styleDef.styleType = class.type

    self:addStyleDefinition(class, name, styleDef)
end

---saves a style definition into the style global
---@param class table Class object
---@param name string name of new style
---@param definition Style
---@protected
function Style:addStyleDefinition(class, name, definition)
    if not self.__definitionTypeMap[class.type] then
        self.__definitionTypeMap[class.type] = {}
    end

    self.__definitionTypeMap[class.type][name] = definition
end

---creates a style instances from the saved definition
---@param class table Class object
---@param name string name of the style to instance
---@return StyleInstance
function Style:getStyleInstance(class, name)
    local definition = self.__definitionTypeMap[class.type][name]

    return StyleInstance:new(definition)
end

---scale a definitions saved prototypes for specified dimensions
---@param width integer
---@param height integer
---@return table<string, Layer>
function Style:__scale(width, height)
    assert(self.__isDefinition, "Cannot scale a non-definition style")

    local states = {}
    for state, layer in pairs(self.__prototypes) do
        states[state] = layer:scale(width, height)
    end
    return states
end

---construct a style instance
---@param styleDef Style
---@return StyleInstance
function StyleInstance:new(styleDef)
    local o = setmetatable({}, styleInstanceMt)

    o.__definition = styleDef
    o.__needsScaling = true
    o.__dim = Dim:new(0, 0, 0, 0)

    return o
end

---change the scaling of the style
---@param width integer
---@param height integer
function StyleInstance:scale(width, height)
    if self.__dim.w ~= width or self.__dim.h ~= height then
        self.__needsScaling = true
    end

    self.__dim.w = width
    self.__dim.h = height
end

---return the appropriate layer for a style state string
---@param name string state name
---@return Layer
function StyleInstance:getState(name)
    if self.__needsScaling then
        self.__needsScaling = false
        self:__scale()
    end

    return self.states[name]
end

---internal logic to actually scale the instance
function StyleInstance:__scale()
    self.states = self.__definition:__scale(self.__dim.w, self.__dim.h)
end

return Style
