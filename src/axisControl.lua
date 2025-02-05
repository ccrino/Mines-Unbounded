---@class AxisControl
---@field private keyDownCount integer
---@field private holdDirection direction
---@field private holdDuration number
---@field private position integer
---@field private motionSmoothingOffset number
local AxisControl = {}

---constructs an axis control object
---@return AxisControl
function AxisControl:new()
    local o = {
        keyDownCount = 0,
        holdDirection = 0,
        holdDuration = 0.0,
        position = 0,
        motionSmoothingOffset = 0.0,
    }
    ---@type AxisControl
    return setmetatable(o, { __index = AxisControl })
end

---update the state of the control
---@param dt number seconds in update tick
function AxisControl:update(dt)
    if self.keyDownCount ~= 0 then
        self.position = self.position + self.keyDownCount
        self.motionSmoothingOffset = self.motionSmoothingOffset + self.keyDownCount
        self.holdDuration = 0
        self.keyDownCount = 0
    elseif self.holdDirection ~= 0 then
        self.holdDuration = self.holdDuration + dt

        if self.holdDuration > 0.1 then
            local times = math.floor(self.holdDuration * 10)
            self.holdDuration = self.holdDuration - (times * 0.1)
            self.position = self.position + (times * self.holdDirection)
            self.motionSmoothingOffset = self.motionSmoothingOffset + (times * self.holdDirection)
        end
    else
        self.holdDuration = 0
    end

    if self.motionSmoothingOffset ~= 0 then
        local sign = self.motionSmoothingOffset > 0 and 1 or -1
        local absoluteSmoothingOffset = math.abs(self.motionSmoothingOffset)

        absoluteSmoothingOffset = absoluteSmoothingOffset - (10 * dt * math.max(absoluteSmoothingOffset, 1))
        self.motionSmoothingOffset =
            (absoluteSmoothingOffset >= 0.0625)
            and absoluteSmoothingOffset * sign
            or 0
    end
end

---gets the position for the control
---@return integer
function AxisControl:getPosition()
    return self.position
end

---gets the smoothed position offset for the control
---@return integer
function AxisControl:getSmoothedPositionOffset()
    local integerPiece = math.modf(self.motionSmoothingOffset)
    return integerPiece
end

---gets the sub-position offset for the control
---@return number
function AxisControl:getSmoothedPositionNudge()
    local _, fractionalPiece = math.modf(self.motionSmoothingOffset)
    return fractionalPiece
end

---event hook for when the key down is pressed for an axis
---@param direction direction
function AxisControl:keyDown(direction)
    self.keyDownCount = self.keyDownCount + direction
    self.holdDirection = self.holdDirection + direction
end

---event hook for when the key up occurs for an axis
---@param direction direction
function AxisControl:keyUp(direction)
    self.holdDirection = self.holdDirection - direction
end

return AxisControl
