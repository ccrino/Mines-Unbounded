

local Window = {
	-- non instance
	theory = nil,
	type = "window",
	layer = nil,
	tag = nil,
	children = {}, -- only objects that are direct decendents
}
Window.__index = Window

function Window:new( layer )
	local o = {}
	o.layer = layer
	o.children = {}
    setmetatable(o, self) --assign window functions
	return o
end

function Window:fromObject( o )
	if o.type ~= "window" then
		error"Invalid base object to Window:fromObject"
	end
	setmetatable(o, self)
	return o
end

function Window:paint()
	self.theory.layers[self.tag] = self.layer
	for _, child in pairs(self.children) do
		self.theory:repaint(child.tag)
	end
end

function Window:addChild( object )
	table.insert(self.children, object)
	object.parent = self
	self.theory:repaint(object.tag)
end

function Window:move( dx, dy )
	for _, object in pairs(self.children) do
		object:move( dx, dy )
	end
	if self.layer then
		self.layer:move(dx, dy)
	end
end

return Window