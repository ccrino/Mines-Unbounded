local HC = require("HC")

local Button = {
	-- non instance
	type = "button",
	theory = nil,

	-- instance parameters
	dim = nil,
	style = nil,
	command = nil,
	collider = nil,
	id = nil,
	state = "normal",
	drawables = {},

	-- optional parameters
	width = nil,
	height = nil,

	-- structure ref
	parent = nil,
	tag = nil,
	children = {},

	--internal parameters
	__delay = 0,
}
Button.__index = Button

function Button:new( dim, style, command, id)
	local o = {}
	o.dim = dim
	o.collider = HC.rectangle( dim:unpack(16) )
	o.style = style
	o.command = command
	o.id = id
	o.drawables = style:scale(dim.w, dim.h)
	for _, drawable in pairs(o.drawables) do
		drawable:move( dim.x, dim.y )
	end
	setmetatable(o, self)
	return o
end

function Button:fromObject( o )
	if not o.style then
		--todo handle default styles
		error"Button initialized without a set style"
	end
	if o.dim then
		o.collider = HC.rectangle( o.dim:unpack(16) )
		o.drawables = o.style:scale(o.dim.w, o.dim.h)
		for _, drawable in pairs(o.drawables) do
			drawable:move( o.dim.x, o.dim.y )
		end
	end
	setmetatable(o, self)
	return o
end

function Button:scale( newDim )
	self.dim = newDim
	HC.remove(self.collider)
	self.collider = HC.rectangle( newDim:unpack(16) )
	self.drawables = self.style:scale(newDim.w, newDim.h)
	for _, drawable in pairs(self.drawables) do
		drawable:move( newDim.x, newDim.y )
	end
	self.theory:repaint(self.tag)
end

function Button:move(...)
	self.collider:move(...)
	self.dim:move(...)
	for _, drawable in pairs(self.drawables) do
		drawable:move( ... )
	end
end

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