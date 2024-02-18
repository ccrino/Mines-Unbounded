---@class ViewObject
---@field public theory AsciiTheory
---@field public type string
---@field public id? string
---@field public tag? string
---@field public parent? ViewObject
---@field public children? ViewObject[]
local ViewObject = {
    type = "viewObject"
}


local classMt = {}
setmetatable(ViewObject, classMt)


local instanceMt = {
    __index = ViewObject
}


---create new view object
---@return ViewObject
function ViewObject:new()
    local o = setmetatable({}, instanceMt)
    o.children = {}
    return o
end

classMt.__call = ViewObject.new

---create a new view object from a base object
---@param o table
---@return ViewObject
function ViewObject:fromObject(o)
    setmetatable(o, instanceMt)
    o.children = {}
    return o
end

---Attach an object child
---@param object ViewObject
function ViewObject:addChild(object)
    table.insert(self.children, object)
    object.parent = self
    self.theory:repaint(object.tag)
end

---move the view object by a position
---@param dx integer
---@param dy integer
function ViewObject:move(dx, dy)
    self:__onMove(dx, dy)
    for _, object in pairs(self.children) do
        object:move(dx, dy)
    end
end

---event handler for when a move occurs
---should handle movement on the current view object
---@param dx integer
---@param dy integer
function ViewObject:__onMove(dx, dy)
end

---paint the view object and children
---@return Layer | nil, Dim | nil
function ViewObject:paint()
    for _, child in pairs(self.children) do
        self.theory:repaint(child.tag)
    end

    return self:__onPaintLayer()
end

---event handler for when paint occurs
---should return the layer for the current view object
---@return Layer, Dim
---@overload fun(): nil
---@protected
function ViewObject:__onPaintLayer()
end

---get the string representation of the object
---@return string
function ViewObject:tostring()
    return self.type
        .. (self.id and (" #" .. tostring(self.id)) or "")
        .. (self.tag and (" @" .. tostring(self.tag)) or "")
end

instanceMt.__tostring = ViewObject.tostring


return ViewObject
