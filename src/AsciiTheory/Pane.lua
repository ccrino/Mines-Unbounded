local ViewObject = require "AsciiTheory/ViewObject"

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

local classMt = {
	__index = ViewObject
}
setmetatable(Pane, classMt)

local instanceMt = {
	__index = Pane
}

---create a new pane
---@return Pane
function Pane:new()
	local o = ViewObject()
	setmetatable(o, instanceMt)
	return o
end

classMt.__call = Pane.new

---create a new pane from an object
---@param o table
---@return Pane
function Pane:fromObject(o)
	assert(o.type == "pane", "Invalid base object for pane:fromObject")

	ViewObject:fromObject(o)
	setmetatable(o, instanceMt)
	return o
end

ViewObject:registerViewObjectClass(Pane)

return Pane
