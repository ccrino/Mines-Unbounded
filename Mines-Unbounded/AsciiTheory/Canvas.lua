local EXP = require("rexpaint")

local Layer = require("AsciiTheory/Layer")
local Frame = require("AsciiTheory/Frame")
local Cell = require("AsciiTheory/Cell")
--local Dim = require("AsciiTheory/Dim")

local Canvas = {
    layers = {},
    layerCount = 0
}
Canvas.__index = Canvas

function Canvas:new( filename, x, y )
	local o
	if filename then
		o = self:read( filename )
	else
		o = { layers = {}, layerCount = 0 }
	end
	setmetatable( o, self )
	if o.layers then
		for _, layer in ipairs(o.layers) do
			setmetatable( layer, Layer )
			layer.dx = x
			layer.dy = y
		end
	end
	return o
end

function Canvas:newAnimated( layers, x, y, filename, ... )
	local layer
	if filename then
		local temp = EXP:read( filename )
		layer = { frames = temp.layers, frameCount = temp.layerCount, animated = true }
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

function Canvas.read( _, filename )
	local rex_canvas
	if filename then
		rex_canvas = EXP:read( filename )
	else
		return {}
	end
	local canvas = { layerCount = rex_canvas.layerCount, layers = {} }
	for layer_key = 1, rex_canvas.layerCount do
		local rex_layer = rex_canvas.layers[layer_key]
		local layer = Layer:new();
		layer.width = rex_layer.width;
		layer.height = rex_layer.height;
		for _, cell in ipairs(rex_layer.cells) do
			layer:setCell( cell.x+1, cell.y+1, Cell:new( cell.char, cell.fg, cell.bg ) )
		end
		canvas.layers[layer_key] = layer
	end
	return canvas
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