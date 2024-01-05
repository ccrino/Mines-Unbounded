local HC = require("HC")

---@class Button
---@field public type "button"
---@field public theory AsciiTheory
---@field public dim Dim
---@field public style Style
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

local classMt = {}
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
	local o = {}
	o.dim = dim
	o.collider = HC.rectangle(dim:unpack(16))
	o.style = style
	o.command = command
	o.id = id
	o.drawables = style:scale(dim.w, dim.h)
	for _, drawable in pairs(o.drawables) do
		drawable:move(dim.x, dim.y)
	end
	o.state = "normal"
	o.children = {}
	setmetatable(o, instanceMt)
	return o
end
classMt.__call = Button.new

---create a new button from a object
---@param o table
---@return Button
function Button:fromObject(o)
	if not o.style then
		--todo handle default styles
		error "Button initialized without a set style"
	end
	if o.dim then
		o.collider = HC.rectangle(o.dim:unpack(16))
		o.drawables = o.style:scale(o.dim.w, o.dim.h)
		for _, drawable in pairs(o.drawables) do
			drawable:move(o.dim.x, o.dim.y)
		end
	end
	o.state = "normal"
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
	self.drawables = self.style:scale(newDim.w, newDim.h)
	for _, drawable in pairs(self.drawables) do
		drawable:move(newDim.x, newDim.y)
	end
	self.theory:repaint(self.tag)
end

---move the button instance
---@param ... number[]
function Button:move(...)
	self.collider:move(...)
	self.dim:move(...)
	for _, drawable in pairs(self.drawables) do
		drawable:move(...)
	end
end

---render object content to a layer
function Button:paint()
	if not self.drawables then
		error"Button could not be drawn, no drawables generated"
	end
	self.theory.layers[self.tag] = self.drawables[self.state]
	for _, child in pairs(self.children) do
		self.theory:repaint(child.tag)
	end
end

return Button