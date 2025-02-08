--luacheck: std +love
---luacheck: ignore 21./_.*

local HC               = require "HC"
local Dim              = require "AsciiTheory/Dim"
local Cell             = require "AsciiTheory/Cell"
local Layer            = require "AsciiTheory/Layer"
local Reader           = require "AsciiTheory/Reader"
local Style            = require "AsciiTheory/Style"
local ViewObject       = require "AsciiTheory/ViewObject"
local SymbolDictionary = require "AsciiTheory/SymbolDictionary"

---@class AsciiTheory
---@field private drawables ({ position: Dim, layer: Layer } | nil)[]
---@field private objects table<integer, ViewObject>
---@field private __text love.Text | nil
---@field private __idMap table<string, ViewObject>
---@field private __commandHandlerMap table<string, fun(param: any)>
---@field private __needsRepaint boolean
---@field private __objectsToRepaint integer[]
---@field private __mouseMode boolean
---@field private __focused Button
local AsciiTheory      = {
	drawables = {},
	layerCount = 1,
	objects = {},
	mask = {},

	__idMap = {},
	__commandHandlerMap = {},

	__needsRepaint = false,
	__objectsToRepaint = {},

	__mouseMode = true,
	__focused = nil,
}

AsciiTheory.Dim        = Dim
AsciiTheory.Cell       = Cell
AsciiTheory.Layer      = Layer
AsciiTheory.Style      = Style
ViewObject.theory      = AsciiTheory

---Given an table, returns the subtable consisting of
--- all of the tables non-numeric keys
---@param object table
---@return {[string]: any}
local function ObjectWithoutNumericKeys(object)
	local result = {}

	for key, value in pairs(object) do
		if type(key) ~= "number" then
			result[key] = value
		end
	end

	return result
end


---constructs a view object hierarchy from a definition struct.
--- the struct should use string keys to define view object properties
--- and numeric keys to define child objects. e.g.
--- ```
--- { type = "window",
---   style = "base_page",
---   { type = "button",
---     style = "accept_button",
---     command = "accept",
---   },
--- }
--- ```
--- type is a required field, as it determines what to construct at each level
---@param struct table
---@return ViewObject
function AsciiTheory:parse(struct)
	local buildStackPointer = 1
	---@type table[]
	local buildStack = { struct }
	---@type table[]
	local attachList = {}

	while buildStackPointer <= #buildStack do
		local current = buildStack[buildStackPointer]

		local o = ObjectWithoutNumericKeys(current)
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

--register a base object constructor that just returns the object root
ViewObject:registerViewObjectClass({
	type = "base",
	fromObject = function() return AsciiTheory.objects[1] end
})

---given an table describing an view object, constructs and returns said object
---@param o table
---@return ViewObject
function AsciiTheory:genericFromObject(o)
	assert(type(o.type) == "string", "Typeless value passed to generic from object")

	local typeConstructor = ViewObject.__types[o.type]
	assert(typeConstructor, "Unrecognized object type " .. o.type .. " passed to generic from object")

	o = typeConstructor:fromObject(o)
	if o.id and not self.__idMap[o.id] then
		self.__idMap[o.id] = o;
	end
	return o
end

---dumps an objects hierarchy into the console
---@param object table
---@param depth integer?
local function summaryDump(object, depth)
	depth = depth or 0
	print(("\t"):rep(depth) .. (object and object:tostring()))
	if object and object.children then
		for _, child in ipairs(object.children) do
			summaryDump(child, depth + 1)
		end
	end
end

---tags an object into the theory
---@param object ViewObject
function AsciiTheory:__tagObject(object)
	self.layerCount = self.layerCount + 1
	object.tag = self.layerCount
	self.objects[object.tag] = object
end

---attaches an object to a parent object
---@param parent ViewObject | integer
---@param object ViewObject
function AsciiTheory:attach(parent, object)
	if type(parent) == "number" then
		---@type ViewObject
		parent = self.objects[parent]
		assert(parent, "Invalid parent tag, this tag is not defined")
	end

	---@cast parent ViewObject

	-- assign tags if parent is also tagged
	if parent.tag then
		assert(self.objects[parent.tag] == parent,
			"attempted to attach a " .. (object.type or "Invalid Object") .. " to Invalid object")

		self:__tagObject(object)
	end

	parent:addChild(object)

	-- cascade assign tags for children
	if object.tag and #object.children > 0 then
		local current = object
		repeat
			assert(current.tag, "non-tree like node structure detected aborting")

			for _, x in ipairs(current.children) do
				if not x.tag then
					current = x
					break
				end
			end

			if current.tag then
				assert(current.parent, "non-tree like node structure detected aborting")
				current = current.parent
			else
				self:__tagObject(current)
			end

			---@cast current ViewObject
		until current.tag == parent.tag
		self:repaint(object.tag)
	end
end

---dettaches an object from its parent object
---@param object ViewObject
function AsciiTheory:detach(object)
	local parent = object.parent
	if parent then
		---@type integer
		local childIndex
		for i, child in ipairs(parent.children) do
			if child == object then
				childIndex = i
			end
		end

		assert(childIndex, "detach called for a corrupted object")

		-- break attachment refs
		object.parent = nil
		table.remove(parent.children, childIndex)

		-- cleanup object tags if present
		if parent.tag then
			local reclaimedTags = {}
			local current = object
			repeat
				for _, x in ipairs(current.children) do
					if x.tag then
						current = x
						break
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

---removes all data for tags specified in dictionary
---@param tagsToClear {[integer]: boolean}
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

---sets the theory handling for mouse interaction
---@param enabled boolean
function AsciiTheory:setMouseMode(enabled)
	self.__mouseMode = enabled
	self:update(0)
end

---looks up objects by id
---@param id string
---@return ViewObject | nil
function AsciiTheory:getElementById(id)
	return self.__idMap[id]
end

---initialize theory
---@param x integer - width of render target
---@param y integer - height of render target
function AsciiTheory:Init(x, y)
	self.loveCanvas = love.graphics.newCanvas(x * 16, y * 16)
	self.globalSpace = HC.new(100) -- define new collider space
	self.mouse = HC.point(0, 0) --define mouse object

	-- define root object
	self.objects[1] = ViewObject:fromObject({
		type = "base",
		tag = 1,
	})
end

---love update handler
---@param dt number time since last update
function AsciiTheory:update(dt)
	local x, y
	if self.__mouseMode then
		x, y = love.mouse.getPosition()
	else
		x, y = -1, -1
	end
	self.mouse:moveTo(x, y)
	for tag, object in pairs(self.objects) do
		if object.__delay then
			---@cast object +Button
			if object.__delay <= 0 then
				if object.collider and (
						(self.__mouseMode and object.collider:collidesWith(self.mouse))
						or (not self.__mouseMode and self.__focused == object)) then
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

---internal drawing logic for populating cached canvas
---@private
function AsciiTheory:__drawCanvas()
	if self.__needsRepaint then
		self.__needsRepaint = false;

		if not self.__text then
			self.__text = love.graphics.newText(love.graphics.getFont())

			-- WTF pre-rendering offscreen fixes weird issue not rendering certain glyphs
			-- with no apparent rhyme or reason.
			for char = 32, 128 do
				self.__text:add(SymbolDictionary[char], -16, -16)
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

---draw a single tagged object
---@param tag integer
---@private
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
			self.__text:add({ cell:getBg(), SymbolDictionary[220] }, 16 * x, 16 * y)
			self.__text:add({ cell:getFg(), SymbolDictionary[cell.char] }, 16 * x, 16 * y)

			mask[x] = mask[x] or {}
			mask[x][y] = tag
		end
	end
end

---love draw handler, call directly within love.draw
function AsciiTheory:draw()
	self:__drawCanvas()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.loveCanvas)
end

---alternate draw method, call to get a drawable object for the theory current state
---@return love.Canvas
function AsciiTheory:getDrawable()
	self:__drawCanvas()
	return self.loveCanvas
end

---force repaint a specified tagged object
---@param tag integer
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

---force repaint for all tagged objects
function AsciiTheory:forceRepaintAll()
	for _, obj in pairs(self.objects) do
		if obj and obj.tag and obj.type ~= "base" then
			self:repaint(obj.tag)
		end
	end
	self.mask = {}
end

---love mouse pressed handler
---@param x number
---@param y number
---@param _button any
---@param _istouch any
function AsciiTheory:mousepressed(x, y, _button, _istouch)
	if not self.__mouseMode then
		self:setMouseMode(true)
	end
	for tag, object in pairs(self.objects) do
		---@cast object +Button
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

---love mouse released handler
---@param _x number
---@param _y number
---@param _button any
---@param _istouch any
function AsciiTheory:mousereleased(_x, _y, _button, _istouch)
	--sliderLock = nil
end

---sets the focused element of the theory for NavigationKey mode
---@param object ViewObject | string | integer
function AsciiTheory:setFocused(object)
	if type(object) == "number" then
		object = self.objects[object]
	elseif type(object) == "string" then
		local nullableObject = self:getElementById(object)
		if not nullableObject then return end
		object = nullableObject
	end

	---@cast object +Button
	if not object.collider then
		return
	end

	---@cast object Button
	self.__focused = object
end

---@enum THEORY_NAV_DIRECTION
THEORY_NAV_DIRECTION = {
	LEFT = 1,
	RIGHT = 2,
	UP = 3,
	DOWN = 4,
}

function AsciiTheory:navigateKeyMode(navDirection)
	if not self.__focused or not self.__focused.collider then
		return
	end

	local CAST_DIST = 100 * 16
	local cx, cy = self.__focused.collider:center()
	local scanTriangle

	local xWeight, yWeight = 1, 1
	if navDirection == THEORY_NAV_DIRECTION.LEFT then
		xWeight, yWeight = 1, 16
		scanTriangle = HC.polygon(cx, cy, cx - CAST_DIST, cy + CAST_DIST, cx - CAST_DIST, cy - CAST_DIST)
	elseif navDirection == THEORY_NAV_DIRECTION.RIGHT then
		xWeight, yWeight = 1, 16
		scanTriangle = HC.polygon(cx, cy, cx + CAST_DIST, cy + CAST_DIST, cx + CAST_DIST, cy - CAST_DIST)
	elseif navDirection == THEORY_NAV_DIRECTION.UP then
		xWeight, yWeight = 16, 1
		scanTriangle = HC.polygon(cx, cy, cx + CAST_DIST, cy - CAST_DIST, cx - CAST_DIST, cy - CAST_DIST)
	elseif navDirection == THEORY_NAV_DIRECTION.DOWN then
		xWeight, yWeight = 16, 1
		scanTriangle = HC.polygon(cx, cy, cx + CAST_DIST, cy + CAST_DIST, cx - CAST_DIST, cy + CAST_DIST)
	end

	local collides = HC.collisions(scanTriangle)
	local minDistance = 1000
	---@type Button | nil
	local minCandidate = nil
	for _, candidate in pairs(self.objects) do
		---@cast candidate +Button
		if candidate ~= self.__focused
			and candidate.collider
			and candidate.type == "button"
			and collides[candidate.collider] then
			local ocx, ocy = candidate.collider:center()
			local distance = math.sqrt(xWeight * (cx - ocx) ^ 2 + yWeight * (cy - ocy) ^ 2)

			if distance < minDistance then
				minDistance = distance
				minCandidate = candidate --[[@as Button]]
			end
		end
	end

	if minCandidate then
		self.__focused = minCandidate
	end
end

function AsciiTheory:clickKeyMode()
	if not self.__focused or not self.__focused.command then
		return
	end

	local object = self.__focused --[[@as Button]]

	if self.__commandHandlerMap[object.command] then
		self.__commandHandlerMap[object.command](object.param)
	end
	object.__delay = .25
	object.state = "pressed"
	self:repaint(object.tag)
end

return AsciiTheory
