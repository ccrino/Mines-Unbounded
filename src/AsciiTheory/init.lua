--luacheck: std +love
---luacheck: ignore 21./_.*

local HC              = require 'HC'

local Dim             = require "AsciiTheory/Dim";
local Cell            = require "AsciiTheory/Cell";
local Layer           = require "AsciiTheory/Layer";
local Reader          = require "AsciiTheory/Reader";
local Style           = require "AsciiTheory/Style";
local Window          = require "AsciiTheory/Window";
local Pane            = require "AsciiTheory/Pane";
local Button          = require "AsciiTheory/Button";
local TextField       = require "AsciiTheory/TextField";

---@class AsciiTheory
---@field private drawables ({ position: Dim, layer: Layer } | nil)[]
---@field private __text love.Text | nil
local AsciiTheory     = {
	drawables = {},
	layerCount = 1,
	objects = {},

	symbols = require "AsciiTheory/SymbolDictionary",
	mask = {},

	__idMap = {},
	__commandHandlerMap = {},

	__needsRepaint = false,
	__objectsToRepaint = {},
}

AsciiTheory.Dim       = Dim
AsciiTheory.Cell      = Cell
AsciiTheory.Layer     = Layer
AsciiTheory.Reader    = Reader
AsciiTheory.Style     = Style
AsciiTheory.Window    = Window
AsciiTheory.Pane      = Pane
AsciiTheory.Button    = Button
AsciiTheory.TextField = TextField


Dim.theory = AsciiTheory
Cell.theory = AsciiTheory
Layer.theory = AsciiTheory
Reader.theory = AsciiTheory
Style.theory = AsciiTheory
Window.theory = AsciiTheory
Pane.theory = AsciiTheory
Button.theory = AsciiTheory
TextField.theory = AsciiTheory


function AsciiTheory:parse(struct)
	local buildStackPointer = 1
	local buildStack = { struct }
	local attachList = {}

	while buildStackPointer <= #buildStack do
		local current = buildStack[buildStackPointer]
		local o = {}
		for i, x in pairs(current) do
			if type(i) ~= "number" then
				o[i] = x
			end
		end
		current.__o = self:genericFromObject(o)
		if #current > 0 then
			table.insert(attachList, current)
			for i = 1, #current do
				table.insert(buildStack, current[i])
			end
		end
		buildStackPointer = buildStackPointer + 1
	end

	for _, parent in ipairs(attachList) do
		for _, child in ipairs(parent) do
			self:attach(parent.__o, child.__o)
		end
	end

	return struct.__o
end

---@type table<string, { fromObject: fun(self: table, o: table): table }>
local __types = {
	base = { fromObject = function() return AsciiTheory.objects[1] end },
	window = Window,
	pane = Pane,
	button = Button,
	textField = TextField,
}
setmetatable(__types, {
	__index = function(_, t)
		error("unrecognized object type " .. t .. " passed to generic from object")
	end
})

function AsciiTheory:genericFromObject(o)
	if not o.type then
		error "Typeless value passed to generic from object"
	end
	local typeConstructor = __types[o.type]
	o = typeConstructor:fromObject(o)
	if o.id and not self.__idMap[o.id] then
		self.__idMap[o.id] = o;
	end
	return o
end

local function summaryDump(object, depth)
	depth = depth or 0
	print(("\t"):rep(depth) .. (object and (object.id or object.type) or tostring(object)))
	if object and object.children then
		for _, child in ipairs(object.children) do
			summaryDump(child, depth + 1)
		end
	end
end

function AsciiTheory:attach(parent, object)
	if type(parent) == "number" then
		parent = self.objects[parent]
		if not parent then
			error "Invalid parent tag, this tag is not defined"
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
			if not current.tag then
				error "non-tree like node structure detected aborting"
			end
			if current.children then
				for _, x in ipairs(current.children) do
					if not x.tag then
						current = x
						break
					end
				end
			end
			if current.tag then
				current = current.parent
			else
				self.layerCount = self.layerCount + 1
				current.tag = self.layerCount
				self.objects[current.tag] = current
			end
		until current.tag == parent.tag
		self:repaint(object.tag)
	end
end

function AsciiTheory:detach(object)
	local parent = object.parent
	if parent then
		local childIndex
		for i, child in ipairs(parent.children) do
			if child == object then
				childIndex = i
			end
		end

		if not childIndex then
			error "detach called for a corrupted object"
		end

		-- break attachment refs
		object.parent = nil
		table.remove(parent.children, childIndex)

		-- cleanup object tags if present
		if parent.tag then
			local reclaimedTags = {}
			local current = object
			repeat
				if current.children then
					for _, x in ipairs(current.children) do
						if x.tag then
							current = x
							break
						end
					end
				end
				if not current.tag then
					current = current.parent
				else
					reclaimedTags[current.tag] = true
					current.tag = nil
				end
			until current == nil

			self:clearTags(reclaimedTags)
		end
	end
end

function AsciiTheory:clearTags(tagsToClear)
	for tag in pairs(tagsToClear) do
		self.objects[tag] = nil
		self.drawables[tag] = nil
	end

	self:forceRepaintAll()
end

-- Mapped Color Setup
---@param table table<string, number[]> mapping from color string to color value
function AsciiTheory:registerMappedColors(table)
	for name, color in pairs(table) do
		self:registerMappedColor(name, color)
	end
end

---@param name string color name to register
---@param rgba number[] color table in the rgb[a] format
function AsciiTheory:registerMappedColor(name, rgba)
	Reader:registerMapColor(name, rgba)
	Cell:setMapColor(name, rgba)
end

---@param name string color name to unregister
function AsciiTheory:unregisterMappedColor(name)
	Reader:unregisterMapColor(name)
	Cell:clearMapColor(name)
end

---@param table table<string, number[]> update values for a mapping, color string to color value
function AsciiTheory:setMappedColors(table)
	for name, color in pairs(table) do
		self:setMappedColor(name, color)
	end
	self:forceRepaintAll()
end

---@param name string color name to set color for
---@param rgba number[] color value to be set
function AsciiTheory:setMappedColor(name, rgba)
	Cell:setMapColor(name, rgba)
end

---@param table table<string, function> register multiple commands from the keys of the provided table
function AsciiTheory:registerCommandHandlers(table)
	for command, handler in pairs(table) do
		self:registerCommandHandler(command, handler)
	end
end

---@param command string command string to register a handler for
---@param handler function function to run on recieving a command event
function AsciiTheory:registerCommandHandler(command, handler)
	self.__commandHandlerMap[command] = handler
end

---@param command string command string to unregister
function AsciiTheory:unregisterCommandHandler(command)
	self.__commandHandlerMap[command] = nil
end

function AsciiTheory:getElementById(id)
	return self.__idMap[id]
end

--initialize theory
function AsciiTheory:Init(x, y)
	self.loveCanvas = love.graphics.newCanvas(x * 16, y * 16)
	self.globalSpace = HC.new(100) -- define new collider space
	self.mouse = HC.point(0, 0) --define mouse object
	local base = {
		type = "base",
		tag = 1,
		children = {},
		theory = self,
	}
	function base:addChild(child) --luacheck: ignore
		table.insert(self.children, child)
		child.parent = self
		self.theory:repaint(child.tag)
	end

	self.objects[1] = base
end

function AsciiTheory:update(dt)
	local x, y = love.mouse.getPosition()
	self.mouse:moveTo(x, y)
	for tag, object in pairs(self.objects) do
		if object.__delay then
			if object.__delay <= 0 then
				if object.collider and object.collider:collidesWith(self.mouse) then
					-- mouse over actions
					if object.state and object.state ~= "hovered" then
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

function AsciiTheory:__drawCanvas()
	if self.__needsRepaint then
		self.__needsRepaint = false;

		if not self.__text then
			self.__text = love.graphics.newText(love.graphics.getFont())

			-- WTF pre-rendering offscreen fixes weird issue not rendering certain glyphs
			-- with no apparent rhyme or reason.
			for char = 32, 128 do
				self.__text:add(self.symbols[char], -16, -16)
			end
		else
			self.__text:clear()
		end

		table.sort(self.__objectsToRepaint)

		local lastTag = -1
		for _, tag in ipairs(self.__objectsToRepaint) do
			if tag ~= lastTag then
				lastTag = tag

				self:__drawTag(tag)
			end
		end

		self.loveCanvas:renderTo(function()
			love.graphics.draw(self.__text)
		end)

		self.__objectsToRepaint = {}
	end
end

---comment
---@param tag integer
function AsciiTheory:__drawTag(tag)
	local drawable = self.drawables[tag]

	if not drawable then
		return
	end

	local mask = self.mask
	local layer = drawable.layer
	local position = drawable.position or Dim(0, 0, 0, 0)

	for layer_x, layer_y, cell in layer:cells() do
		local x = layer_x + layer.dx + position.x - 1
		local y = layer_y + layer.dy + position.y - 1

		if cell and cell.char ~= 1 and not (mask[x] and mask[x][y] and mask[x][y] > tag) then
			self.__text:add({ cell:getBg(), self.symbols[220] }, 16 * x, 16 * y)
			self.__text:add({ cell:getFg(), self.symbols[cell.char] }, 16 * x, 16 * y)

			mask[x] = mask[x] or {}
			mask[x][y] = tag
		end
	end
end

function AsciiTheory:draw()
	self:__drawCanvas()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.loveCanvas)
end

function AsciiTheory:getDrawable()
	self:__drawCanvas()
	return self.loveCanvas
end

function AsciiTheory:repaint(tag)
	if not tag or not self.objects[tag] then return end

	self.__needsRepaint = true;
	table.insert(self.__objectsToRepaint, tag)
	local layer, position = self.objects[tag]:paint()

	if not layer then
		return
	end

	self.drawables[tag] = {
		layer = layer,
		position = position,
	}
end

function AsciiTheory:forceRepaintAll()
	for _, obj in pairs(self.objects) do
		if obj and obj.tag and obj.type ~= "base" then
			self:repaint(obj.tag)
		end
	end
	self.mask = {}
end

function AsciiTheory:mousepressed(x, y, _button, _istouch)
	for tag, object in pairs(self.objects) do
		if object.collider and object.collider:contains(x, y) then
			if object.command ~= nil then
				if self.__commandHandlerMap[object.command] then
					self.__commandHandlerMap[object.command](object.param)
				end
				object.__delay = .25
				object.state = "pressed"
				self:repaint(tag)
			end
		end
	end
end

function AsciiTheory:mousereleased(_x, _y, _button, _istouch)
	--sliderLock = nil
end

return AsciiTheory
