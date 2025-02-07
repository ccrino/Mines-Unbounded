---@class AxisControl
---@field private keyDownCount integer
---@field private holdDirection direction
---@field private heldKey table<direction, boolean>
---@field private heldStick direction
---@field private holdDuration number
---@field private position integer
---@field private motionSmoothingOffset number
---@field private speed integer
local AxisControl = {}

---constructs an axis control object
---@return AxisControl
function AxisControl:new()
    local o = {
        heldKey = {
            [1] = false,
            [-1] = false,
        },
        heldStick = 0,
        keyDownCount = 0,
        holdDirection = 0,
        holdDuration = 0.0,
        position = 0,
        motionSmoothingOffset = 0.0,
        speed = 1,
    }
    ---@type AxisControl
    return setmetatable(o, { __index = AxisControl })
end

---update the state of the control
---@param dt number seconds in update tick
function AxisControl:update(dt)
    if self.keyDownCount ~= 0 then
        self.position = self.position + self.keyDownCount * self.speed
        self.motionSmoothingOffset = self.motionSmoothingOffset + self.keyDownCount * self.speed
        self.holdDuration = 0
        self.keyDownCount = 0
    elseif self.holdDirection ~= 0 then
        self.holdDuration = self.holdDuration + dt

        if self.holdDuration > 0.1 then
            local times = math.floor(self.holdDuration * 10)
            self.holdDuration = self.holdDuration - (times * 0.1)
            self.position = self.position + (times * self.holdDirection * self.speed)
            self.motionSmoothingOffset = self.motionSmoothingOffset + (times * self.holdDirection * self.speed)
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

---set control movement speed
---@param speed integer
function AxisControl:setSpeed(speed)
    self.speed = math.floor(speed)
end

---get control movement speed
---@return integer
function AxisControl:getSpeed()
    return self.speed
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
    if not self.heldKey[direction] then
        self.heldKey[direction] = true

        self.keyDownCount = self.keyDownCount + direction
        self.holdDirection = Utils.clamp(
            self.heldStick + (self.heldKey[-1] and -1 or 0) + (self.heldKey[1] and 1 or 0),
            -1, 1)
    end
end

---event hook for when the key up occurs for an axis
---@param direction direction
function AxisControl:keyUp(direction)
    if self.heldKey[direction] then
        self.heldKey[direction] = false

        self.holdDirection = Utils.clamp(
            self.heldStick + (self.heldKey[-direction] and -direction or 0),
            -1, 1)
    end
end

---event hook for when a gamepad or joystick pushes an axis direction
---@param direction integer
function AxisControl:axisUpdate(direction)
    if self.heldStick ~= 0 and math.abs(direction) < 0.5 then
        self.heldStick = 0
        self.holdDirection = Utils.clamp(
            (self.heldKey[-1] and -1 or 0) + (self.heldKey[1] and 1 or 0),
            -1, 1)
    elseif self.heldStick == 0 and math.abs(direction) >= 0.5 then
        local normalizedDirection = (direction < 0 and -1 or 1)
        self.heldStick = normalizedDirection
        self.keyDownCount = self.keyDownCount + normalizedDirection
        self.holdDirection = Utils.clamp(
            self.heldStick + (self.heldKey[-1] and -1 or 0) + (self.heldKey[1] and 1 or 0),
            -1, 1)
    end
end

return AxisControl
