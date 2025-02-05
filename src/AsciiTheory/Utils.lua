utf8 = require "utf8"

local Utils = {}

---splits a string into multiple pieces by a delimiter
---@param text string
---@param delim string
---@return string[]
local function splitString(text, delim)
    ---@type string[]
    local lines = {}
    local start = 1

    local finish = text:find(delim, start, true)
    while finish do
        table.insert(lines, text:sub(start, finish - 1))
        start = finish + 1
        finish = text:find(delim, start, true)
    end

    table.insert(lines, text:sub(start))

    return lines
end

---Iterator which returns each delimited substring of
--  text and its index in the string
---@param text string
---@param delim string
---@return fun(table: string[], i?: integer):(integer, string), string[], integer
local function iDelimedLines(text, delim)
    return ipairs(splitString(text, delim))
end

---splits a string into a collection of lines where no lines exceed max length
---@param text string
---@param maxLength integer
---@return string[]
local function wrapWords(text, maxLength)
    ---@type string[]
    local lines = {}

    local line = ""
    for _, word in iDelimedLines(text, " ") do
        if utf8.len(line) == 0 then
            -- first word on a line
            -- split really long words as necessary
            while utf8.len(word) >= maxLength - 1 do
                table.insert(lines, word:sub(1, utf8.offset(word, maxLength + 1) - 1))
                word = word:sub(utf8.offset(word, maxLength + 1))
            end
            line = word
        elseif utf8.len(line) + utf8.len(word) + 1 <= maxLength then
            -- new word in line, which doesn't need to wrap
            line = line .. " " .. word
            -- if long enough or close enough, flush into list
            if utf8.len(line) >= maxLength - 1 then
                table.insert(lines, line)
                line = ""
            end
        elseif utf8.len(word) < maxLength - 1 then
            -- line is too long for a new word, and new word is reasonably sized
            table.insert(lines, line)
            line = word
        else
            -- else line is too long, and word is too long to keep as a unit
            local leftoverSpace = maxLength - 1 - utf8.len(line)
            table.insert(lines, line .. " " .. word:sub(1, utf8.offset(word, leftoverSpace + 1) - 1))
            word = word:sub(utf8.offset(word, leftoverSpace + 1))
            -- split really long words as necessary
            while utf8.len(word) >= maxLength - 1 do
                table.insert(lines, word:sub(1, utf8.offset(word, maxLength + 1) - 1))
                word = word:sub(utf8.offset(word, maxLength + 1))
            end
            line = word
        end
    end

    -- handle leftover line
    if line:len() > 0 then
        table.insert(lines, line)
    end

    return lines
end


---Splits a string into a collection of lines
---@param text string
---@param maxWidth integer - the max width for a line
---@return string[]
function Utils.SplitTextIntoLines(text, maxWidth)
    ---@type string[]
    local lines = {}

    for _, line in iDelimedLines(text, "\n") do
        if utf8.len(line) > maxWidth then
            for _, subline in ipairs(wrapWords(line, maxWidth)) do
                table.insert(lines, subline)
            end
        else
            table.insert(lines, line)
        end
    end

    return lines
end

---calculate the offset to start from in order to align an object
--- in a space with the desired alignment type
---@param alignType "min" | "center" | "max" - alignment type, min is aligned to 0, and max is aligned to max
---@param size integer - size of the object being aligned
---@param max integer - available space to align within
---@return integer
function Utils.GetOffsetForAlignment(alignType, size, max)
    if not alignType or size > max or alignType == "min" then
        return 0
    elseif alignType == "max" then
        return max - size
    elseif alignType == "center" then
        return math.floor((max - size) / 2)
    else
        error("invalid alignment type '" .. alignType .. "'")
    end
end

return Utils
