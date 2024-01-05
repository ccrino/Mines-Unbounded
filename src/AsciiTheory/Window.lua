---@module "AsciiTheory/Layer"

---@class Window
---@field public type "window"
---@field public theory AsciiTheory
---@field public tag? integer
---@field public children any[]
---@field protected layer Layer
local Window = {
	-- non instance
	type = "window",
}

--#region Class Metatable definition
local classMt = {}
setmetatable(Window, classMt)
--#endregion Class Metatable definition

local instanceMt = {
	__index = Window
}

---creates a new window
---@param layer Layer
---@return Window
function Window:new(layer)
	local o = {}
	o.layer = layer
	o.children = {}
    setmetatable(o, instanceMt) --assign window functions
	return o
end
classMt.__call = Window.new

---creates a new window from an object
---@param o table
---@return Window
function Window:fromObject(o)
	if o.type ~= "window" then
		error"Invalid base object to Window:fromObject"
	end
	o.children = {}
	setmetatable(o, instanceMt)
	return o
end

---render object content to a layer
function Window:paint()
	self.theory.layers[self.tag] = self.layer
	for _, child in pairs(self.children) do
		self.theory:repaint(child.tag)
	end
end

---add a view element as a child of this window
---@param object any
function Window:addChild(object)
	table.insert(self.children, object)
	object.parent = self
	self.theory:repaint(object.tag)
end

---move the window
---@param dx number
---@param dy number
function Window:move(dx, dy)
	for _, object in pairs(self.children) do
		object:move(dx, dy)
	end
	if self.layer then
		self.layer:move(dx, dy)
	end
end

return Window