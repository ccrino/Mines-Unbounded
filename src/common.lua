---@alias direction -1|0|1

-- State Constants
---@enum STATE
STATE = {
    UNSEEN = 0,
    SEEN = 1,
    FLAGGED = 2,
}

-- Value Constants
---@enum VALUE
VALUE = {
    MINE = "*",
    [-1] = "*",
    ["*"] = -1,
    NONE = " ",
    [0] = " ",
    [" "] = 0,
    ONE = "1",
    [1] = "1",
    ["1"] = 1,
    TWO = "2",
    [2] = "2",
    ["2"] = 2,
    THREE = "3",
    [3] = "3",
    ["3"] = 3,
    FOUR = "4",
    [4] = "4",
    ["4"] = 4,
    FIVE = "5",
    [5] = "5",
    ["5"] = 5,
    SIX = "6",
    [6] = "6",
    ["6"] = 6,
    SEVEN = "7",
    [7] = "7",
    ["7"] = 7,
    EIGHT = "8",
    [8] = "8",
    ["8"] = 8,
    FLAG = "!", -- false value for consistency
}

--temp colors from previous version
---@enum COLORS
COLORS = {
    blue = { 0.0, 0.5, 1.0 },
    green = { 0.0, 1.0, 0.0 },
    yellow = { 1.0, 1.0, 0.0 },
    orange = { 1.0, 0.5, 0.0 },
    red = { 1.0, 0.0, 0.0 },
    magenta = { 1.0, 0.0, 0.5 },
    pink = { 1.0, 0.0, 1.0 },
    purple = { 0.5, 0.0, 1.0 },
    white = { 1.0, 1.0, 1.0 },
    black = { 0.0, 0.0, 0.0 },
    -- bgdark = {   0,  32/255,  64/255};
    -- bglite = {   0,  41/255,  83/255};
    -- tiledark = {   0,  70/255, 140/255};
    -- tilelite = {   0,  89/255, 178/255};
    -- halodark = { 163/255, 0, 217/255};
    -- halolite = { 191/255, 0, 255/255};
    -- bghalodark = {  81/255, 0, 107/255};
    -- bghalolite = {  96/255, 0, 128/255};
}

COLORS[1] = COLORS.white
COLORS[2] = COLORS.blue
COLORS[3] = COLORS.green
COLORS[4] = COLORS.yellow
COLORS[5] = COLORS.orange
COLORS[6] = COLORS.red
COLORS[7] = COLORS.magenta
COLORS[8] = COLORS.pink
COLORS[9] = COLORS.purple

Utils = {}

---clamps input between a min and max
---@param x number
---@param min number
---@param max number
---@return number
function Utils.clamp(x, min, max)
    return
        x <= min and min or
        x >= max and max or
        x
end

---wraps input between min and max
---@param x number
---@param min number
---@param max number
---@return number
function Utils.wrap(x, min, max)
    return
        ((x - min) % (max - min + 1)) + min
end

---converts a linear parameter value to exponential ease curve
---@param x number parameter in range [0..1]
---@return number
function Utils.easeInOutExp(x)
    return
        x <= 0 and 0 or
        x >= 1 and 1 or
        x < 0.5 and math.pow(2, 20 * x - 10) / 2 or
        (2 - math.pow(2, -20 * x + 10)) / 2
end

---zero pads a string or number to length
---@param string string|number
---@param length integer
---@return string
function Utils.zeroLeftPad(string, length)
    string = tostring(string)
    local pad = length - string:len()
    return ("0"):rep(pad) .. string
end

---binds a function to its parent object
---@param obj table
---@param func fun(...: any[]): any
---@return fun(...: any[]): any
function Utils.bind(obj, func)
    return function(...)
        return func(obj, ...)
    end
end

---creates a timer lambda, which when called with an elapsed time will
--- evaluate true if the desired repeat time has occured
---@param repeat_time number time in seconds between evaluation
---@return function
function Utils.new_timer(repeat_time)
    local counter = 0

    return function(dt)
        counter = counter + dt

        if counter > repeat_time then
            counter = counter - repeat_time
            return true
        end

        return false
    end
end
