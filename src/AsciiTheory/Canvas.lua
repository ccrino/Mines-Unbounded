local Reader = require "AsciiTheory/Reader"
local Layer = require "AsciiTheory/Layer"
local Frame = require "AsciiTheory/Frame"

---@class Canvas
---@field public type "canvas"
---@field public theory AsciiTheory
local Canvas = {
    layers = {},
    layerCount = 0,
	type = 'canvas',
}

local classMt = {}
setmetatable(Canvas, classMt)

local instanceMt = {
	__index = Canvas
}

function Canvas:new( filename, x, y )
	local o = {}
	local layers = (filename and Reader:read(filename)) or {}

	o.layers = layers
	o.layerCount = #layers

	setmetatable( o, instanceMt )
	if o.layers then
		for _, layer in ipairs(o.layers) do
			layer.dx = x
			layer.dy = y
		end
	end
	return o
end
classMt.__call = Canvas.new

function Canvas:newAnimated( layers, x, y, filename, ... )
	local layer
	if filename then
		local temp_layers = Reader:read(filename)
		layer = { frames = temp_layers, frameCount = #temp_layers, animated = true }
		setmetatable( layer, Layer )
		for _, frame in ipairs( layer.frames ) do
			setmetatable( frame, Frame )
		end
	else
		return layers
	end
	if not layers then
		layers = {}
		layers[1] = layer
		layers = self:newAnimated( layers, x, y, ... )
		local o = {}
		o.layers = layers
		o.layerCount = #layers
		setmetatable( o, self )
		o:move( x, y )
		return o
	else
		layers[ #layers + 1 ] = layer
		return self:newAnimated( layers, x, y, ... )
	end
end

function Canvas:move( ... )
	for _, layer in ipairs( self.layers ) do
		layer:move( ... )
	end
end

function Canvas:add( canvas )
	if self then
		for _, layer in pairs( canvas.layers ) do
			self.layers[#self.layers + 1] = layer
		end
		self.layerCount = #self.layers
	else
		self = canvas
	end
	return self
end
Canvas.__add = Canvas.add

return Canvas