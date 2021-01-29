--luacheck: std +love
--luacheck: ignore 21./_.*

local HC = require 'HC'


local Window 	= require "AsciiTheory/Window"
local Button 	= require "AsciiTheory/Button"
local Dim 		= require "AsciiTheory/Dim"
local Cell 		= require "AsciiTheory/Cell"
local Canvas 	= require "AsciiTheory/Canvas"
local Style 	= require "AsciiTheory/Style"
local TextField = require "AsciiTheory/TextField"
local Pane 		= require "AsciiTheory/Pane"

local AsciiTheory = {
	layers = {};
	layerCount = 1;
	objects = {};
	idDict = {};
	styles = {};
	commands = {};
	loveCanvas = love.graphics.newCanvas();
	symbols = require "AsciiTheory/SymbolDictionary";
	mask = {},
	__needsRepaint = false;
	__objectsToRepaint = {};
}
AsciiTheory.__index = AsciiTheory


Window.theory = AsciiTheory
Button.theory = AsciiTheory
TextField.theory = AsciiTheory
Pane.theory = AsciiTheory

function AsciiTheory.window( _, ... ) return Window:new( ... ) end
function AsciiTheory.pane( _, ... ) return Pane:new( ... ) end
function AsciiTheory.button( _, ... ) return Button:new( ... ) end
function AsciiTheory.textField( _, ... ) return TextField:new( ... ) end
function AsciiTheory.dim( _, ... ) return Dim:new( ... ) end
function AsciiTheory.cell( _, ... ) return Cell:new( ... ) end
function AsciiTheory.canvas( _, ... ) return Canvas:new( ... ) end

function AsciiTheory:parse( struct )
	local buildStack = { struct }
	local attachList = {}

	while #buildStack > 0 do
		local current = table.remove(buildStack)
		local o = {}
		for i,x in pairs(current) do
			if type(i) ~= "number" then
				o[i] = x
			end
		end
		current.__o = self:genericFromObject(o)
		if #current > 0 then
			table.insert(attachList, current)
			for i=#current, 1, -1 do
				table.insert(buildStack, current[i])
			end
		end
	end

	for _, parent in ipairs(attachList) do
		for _, child in ipairs(parent) do
			self:attach( parent.__o, child.__o )
		end
	end

	return struct.__o
end

local __types = {
	base = { fromObject = function () return AsciiTheory.objects[1] end };
	window = Window;
	pane = Pane;
	button = Button;
	textField = TextField;
	__index = function (_,t) error("unrecognized object type " .. t .. " passed to generic from object") end;
}
setmetatable(__types, __types)

function AsciiTheory:genericFromObject( o )
	if not o.type then
		error"Typeless value passed to generic from object"
	end
	o = __types[o.type]:fromObject(o)
	if o.id then
		self.idDict[o.id] = o
	end
	return o
end

function AsciiTheory:attach( parent, object )
	if type(parent) == "number" then
		parent = self.objects[parent]
		if not parent then
			error"Invalid parent tag, this tag is not defined"
		end
	end
	if parent.tag then
		if self.objects[parent.tag] == parent then
			self.layerCount = self.layerCount + 1
			object.tag = self.layerCount
			self.objects[object.tag] = object
			parent:addChild(object)
		else
			error("attempted to attach a " .. (object.type or "Invalid Object") .. " to Invalid object")
		end
	else
		--tag less build, tags generated when attached to base
		parent:addChild(object)
	end
	if object.tag and #object.children > 0 then
		local current = object
		repeat
			for _,x in ipairs(current.children) do
				if not x.tag then
					current = x
					break
				end
			end
			if current.tag then
				current = current.parent
			end
			if not current.tag then
				self.layerCount = self.layerCount + 1
				current.tag = self.layerCount
				self.objects[current.tag] = current
			end
		until current == parent
		self:repaint(object.tag)
	end
end

-- define style for theory
function AsciiTheory:buttonStyle( name, ... )
	self.styles[name] = Style:newButtonStyle( ... )
end

--initialize theory
function AsciiTheory:Init()
	self.globalSpace = HC.new(100) -- define new collider space
	self.mouse = HC.point(0,0) --define mouse object
	local base = {
		type = "base";
		tag = 1;
		children = {};
		theory = self;
	}
	function base:addChild( child ) --luacheck: ignore
		table.insert(self.children, child)
		child.parent = self
		self.theory:repaint(child.tag)
	end
	self.objects[1] = base
end

function AsciiTheory:update( dt )
	self.mouse:moveTo(love.mouse.getPosition())
	for tag, object in pairs(self.objects) do
		if object.__delay then
			if object.__delay <= 0 then
				if object.collider and object.collider:collidesWith( self.mouse ) then
					-- mouse over actions
					if object.state then
						object.state = "hovered"
						self:repaint(tag)
					end
				else
					if object.state and object.state ~= "normal" then
						object.state = "normal"
						self:repaint(tag)
					end
				end
			else
				object.__delay = object.__delay - dt
			end
		end
	end
end

function AsciiTheory:draw()
	if self.__needsRepaint then
		self.__needsRepaint = false;

		local loveCanvas = self.loveCanvas
		local layers = self.layers
		local mask = self.mask
		table.sort( self.__objectsToRepaint )
		-- display canvas
		love.graphics.setCanvas(loveCanvas)
		local lastTag = -1
		for _, tag in ipairs(self.__objectsToRepaint) do
			if tag ~= lastTag then
				lastTag = tag
				local layer = layers[tag]
				if layer then
					for layer_y, rowcells in pairs( layer.cells )do
						for layer_x, cell in pairs( rowcells ) do
							local x = layer_x + layer.dx - 1
							local y = layer_y + layer.dy - 1
							if cell and cell.char ~= 1 and not( mask[x] and mask[x][y] and mask[x][y] > tag ) then
								love.graphics.setColor( cell.bg )
								love.graphics.print(tostring( self.symbols[220] ), 16*x, 16*y )
								love.graphics.setColor( cell.fg )
								love.graphics.print(tostring( self.symbols[cell.char] ), 16*x, 16*y )
								mask[x] = mask[x] or {}
								mask[x][y] = tag
							end
						end
					end
				end
			end
		end
		love.graphics.setCanvas()
		self.__objectsToRepaint = {}
	end
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(self.loveCanvas)
end

function AsciiTheory:repaint( tag )
	if not tag then return end
	self.__needsRepaint = true;
	table.insert(self.__objectsToRepaint, tag)
	self.objects[tag]:paint()
end

function AsciiTheory:forceRepaintAll()
	for _,obj in ipairs(self.objects) do
		if obj.tag and obj.type ~= "base" then
			self:repaint(obj.tag)
		end
	end
end

function AsciiTheory:mousepressed( x, y, _button, _istouch )
	for tag, object in pairs(self.objects) do
		if object.collider and object.collider:contains(x,y) then
			if object.command ~= nil then
				if self.commands[object.command] then
					self.commands[object.command]()
				end
				object.__delay = .25
				object.state = "pressed"
				self:repaint(tag)
			end
		end
	end
end

function AsciiTheory.mousereleased( _self, _x, _y, _button, _istouch )
	--sliderLock = nil
end

return AsciiTheory