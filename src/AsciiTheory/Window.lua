---@module "AsciiTheory/Layer"
---@module "AsciiTheory/Dim"

local Style = require 'AsciiTheory/Style'
local ViewObject = require 'AsciiTheory/ViewObject'

---@class Window : ViewObject
---@field public type "window"
---@field public tag? integer
---@field public children any[]
---@field public style string
---@field private __styleDef StyleInstance
---@field public dim Dim
local Window = {
	-- non instance
	type = "window",
}

--#region Class Metatable definition
local classMt = {}
classMt.__index = ViewObject
setmetatable(Window, classMt)
--#endregion Class Metatable definition

local instanceMt = {
	__index = Window
}

---creates a new window
---@param style string
---@return Window
function Window:new(style)
	assert(style, "Window initialized without a set style")

	local o = ViewObject()
	o.style = style
	o.__styleDef = Style:getStyleInstance(Window, o.style)
	o.children = {}
	setmetatable(o, instanceMt) --assign window functions
	return o
end

classMt.__call = Window.new

---creates a new window from an object
---@param o table
---@return Window
function Window:fromObject(o)
	assert(o.type == "window", "Invalid base object to Window:fromObject")
	assert(o.style, "Window initialized without a set style")

	o.__styleDef = Style:getStyleInstance(Window, o.style)
	o.__styleDef:scale(o.dim.w, o.dim.h)
	o.children = {}
	setmetatable(o, instanceMt)
	return o
end

---paint current layer
---@return Layer, Dim
function Window:__onPaintLayer()
	return self.__styleDef:getState("main"), self.dim
end

---move objects
---@param dx integer
---@param dy integer
function Window:__onMove(dx, dy)
	self.dim:move(dx, dy)
end

---simple style map, only one rectangle
Style:defineStyleParser(Window, function(SE)
	SE:TakeAll("main")
end)

ViewObject:registerViewObjectClass(Window)

return Window
