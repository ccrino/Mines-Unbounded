

local Pane = {
	-- non instance
	theory = nil,
    type = "pane",

	layer = nil,
	tag = nil,
    children = {}, -- only objects that are direct decendents

    style = nil,
    orientation = nil,
}
Pane.__index = Pane

function Pane:new( layer )
	local o = {}
	o.layer = layer
	o.children = {}
    setmetatable(o, self) --assign Pane functions
	return o
end

function Pane:fromObject( o )
	if o.type ~= "pane" then
		error"Invalid base object to pane:fromObject"
	end
	setmetatable(o, self)
	return o
end

function Pane:paint()
	self.theory.layers[self.tag] = self.layer
	for _, child in pairs(self.children) do
		self.theory:repaint(child.tag)
	end
end

function Pane:addChild( object )
	table.insert(self.children, object)
	object.parent = self
	self.theory:repaint(object.tag)
end

function Pane:move( dx, dy )
	for _, object in pairs(self.children) do
		object:move( dx, dy )
	end
	if self.layer then
		self.layer:move(dx, dy)
	end
end

return Pane