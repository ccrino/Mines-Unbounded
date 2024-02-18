local HC = require "HC"
local ViewObject = require 'AsciiTheory/ViewObject'

local Style = require 'AsciiTheory/Style'
---@module "AsciiTheory/Style"
---@module "AsciiTheory/StyleExtract"

---@class Button : ViewObject
---@field public type "button"
---@field public theory AsciiTheory
---@field public dim Dim
---@field public style string
---@field private __styleDef StyleInstance
---@field public command? string
---@field public state "normal" | "hovered" | "pressed"
---@field public width? number
---@field public height? number
---@field public id? string
---@field public parent? any
---@field public tag? integer
---@field public children any[]
---@field protected collider any
---@field protected drawables any
---@field private __delay number
local Button = {
	-- non instance
	type = "button",
}

local classMt = {
	__index = ViewObject
}
setmetatable(Button, classMt)

local instanceMt = {
	__index = Button
}

---create a new button
---@param dim Dim
---@param style Style
---@param command string
---@param id string
---@return Button
function Button:new(dim, style, command, id)
	local o = ViewObject()
	o.dim = dim
	o.collider = HC.rectangle(dim:unpack(16))
	o.style = style
	o.command = command
	o.id = id

	o.state = "normal"
	o.__delay = 0
	setmetatable(o, instanceMt)
	return o
end

classMt.__call = Button.new

---create a new button from a object
---@param o table
---@return Button
function Button:fromObject(o)
	ViewObject:fromObject(o)
	if not o.style then
		--todo handle default styles
		error "Button initialized without a set style"
	else
		o.__styleDef = Style:getStyleInstance(Button, o.style)
	end

	if o.dim then
		o.collider = HC.rectangle(o.dim:unpack(16))
		o.__styleDef:scale(o.dim.w, o.dim.h)
	end
	o.state = "normal"
	o.__delay = 0
	o.children = {}
	setmetatable(o, instanceMt)
	return o
end

---change the dimensions of the button
---@param newDim Dim
function Button:scale(newDim)
	self.dim = newDim
	HC.remove(self.collider)
	self.collider = HC.rectangle(newDim:unpack(16))

	self.__styleDef:scale(newDim.w, newDim.h)
	self.theory:repaint(self.tag)
end

---move the button instance
---@param dx integer
---@param dy integer
function Button:__onMove(dx, dy)
	self.collider:move(dx, dy)
	self.dim:move(dx, dy)
end

---gets the layer for the button
---@return Layer, Dim
function Button:__onPaintLayer()
	return self.__styleDef:getState(self.state), self.dim
end

Style:defineStyleParser(Button, function(SE)
	SE:box("normal")
	SE:box("hovered")
	SE:box("pressed")
end)

return Button
