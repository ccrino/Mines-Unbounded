
---@class Pane
---@field public type "pane"
---@field public theory AsciiTheory
---@field public layer Layer
---@field public tag? integer
---@field public children any[]
local Pane = {
    type = "pane",

	--note to future self, add this feature?
    style = nil,
    orientation = nil,
}

local classMt = {}
setmetatable(Pane, classMt)

local instanceMt = {
	__index = Pane
}

---create a new pane
---@param layer Layer
---@return Pane
function Pane:new(layer)
	local o = {}
	o.layer = layer
	o.children = {}
    setmetatable(o, instanceMt)
	return o
end
classMt.__call = Pane.new

---create a new pane from an object
---@param o table
---@return Pane
function Pane:fromObject(o)
	if o.type ~= "pane" then
		error"Invalid base object to pane:fromObject"
	end
	o.children = {}
	setmetatable(o, instanceMt)
	return o
end

---renders a layer for the object
function Pane:paint()
	self.theory.layers[self.tag] = self.layer
	for _, child in pairs(self.children) do
		self.theory:repaint(child.tag)
	end
end

---adds view elements as children of the pane
---@param object table
function Pane:addChild(object)
	table.insert(self.children, object)
	object.parent = self
	self.theory:repaint(object.tag)
end

---move the pane
---@param dx number
---@param dy number
function Pane:move(dx, dy)
	for _, object in pairs(self.children) do
		object:move(dx, dy)
	end
	if self.layer then
		self.layer:move(dx, dy)
	end
end

return Pane