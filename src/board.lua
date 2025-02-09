require "common"
local MINE_ESCALATION_RATE = 0.9999

---@class Board.Cell
---@field state STATE
---@field value VALUE
---@field extra any


---@class Board
---@field onScoreChangeHandler fun(score: integer)?
---@field onCellGradualRevealHandler fun(x: integer, y: integer, depth: integer)?
---@field cells table<integer, table<integer, Board.Cell>>
---@field forceNoGuess boolean
local Board = {
    mineWeight = MINE_ESCALATION_RATE,
    cleared = 0,
    begun = false,
    isGameOver = false,
    cells = {},
    gameMode = GAME_MODE.NORMAL,
    forceNoGuess = false,
}

---sets the game mode flag
---@param gameMode GAME_MODE
function Board:setGameMode(gameMode)
    --make sure gamemode is not changed while running
    if self.begun then
        return
    end

    self.gameMode = gameMode

    if self.gameMode == GAME_MODE.NORMAL then
        self.forceNoGuess = false
    elseif self.gameMode == GAME_MODE.HARD then
        self.forceNoGuess = true
    end
end

---reset board to state of a new game
function Board:newGame()
    self.begun = false
    self.isGameOver = false
    self.cleared = 0
    self.cells = {}
    self.mineWeight = MINE_ESCALATION_RATE

    self:onScoreChange()
end

---starts the board, generating the starting region
---@param boardX integer x component of the center of starting area
---@param boardY integer y component of the center of starting area
function Board:beginGame(boardX, boardY)
    local newEmptyCell = function(lx, ly)
        if not self.cells[ly] then
            self.cells[ly] = {}
        end
        self.cells[ly][lx] = self:makeCell(true)
    end

    newEmptyCell(boardX, boardY)
    self:doNeighbor(boardX, boardY, newEmptyCell)

    self.begun = true
end

---sets the board to end state
---@param boardX integer x component of the losing cell move
---@param boardY integer y component of the losing cell move
function Board:endGame(boardX, boardY)
    self.isGameOver = true

    for ry, row in pairs(self.cells) do
        local yDist = math.abs(boardY - ry)
        for rx, cell in pairs(row) do
            if cell.value == VALUE.MINE then
                local priorState = cell.state
                cell.state = STATE.SEEN
                self:onCellExplodeReveal(rx, ry, math.max(math.abs(boardX - rx), yDist), priorState)
            end
        end
    end
end

---event called when score value changes
function Board:onScoreChange()
    if self.onScoreChangeHandler then
        self.onScoreChangeHandler(self.cleared)
    end
end

---sets an external function to be called when board score changes
---@param handler fun(score: integer) handler to run
function Board:setScoreChangeHandler(handler)
    self.onScoreChangeHandler = handler
end

---event called when a cell is revealed 'gradually'
---@param x integer
---@param y integer
---@param depth integer the depth from triggering reveal
function Board:onCellGradualReveal(x, y, depth)
    if self.onCellGradualRevealHandler then
        self.onCellGradualRevealHandler(x, y, depth)
    end
end

---sets an external function to be called when a cell is revealed 'gradually'
---@param handler fun(x: integer, y: integer, depth: integer)
function Board:setCellGradualRevealHandler(handler)
    self.onCellGradualRevealHandler = handler
end

---event called when a cell is revealed 'explosively'
---@param x integer
---@param y integer
---@param distance integer the distance from the triggering reveal
---@param priorState STATE
function Board:onCellExplodeReveal(x, y, distance, priorState)
    if self.onCellExplodeRevealHandler then
        self.onCellExplodeRevealHandler(x, y, distance, priorState)
    end
end

---sets an external function to be called when a cell is revealed 'explosively'
---@param handler fun(x: integer, y: integer, distance: integer, priorState: STATE)
function Board:setCellExplodeRevealHandler(handler)
    self.onCellExplodeRevealHandler = handler
end

---entry point for primary mouse action event(s)
---@param x integer
---@param y integer
function Board:primaryAction(x, y)
    if self.isGameOver then
        return
    end

    if not self.begun then
        self:beginGame(x, y)
    end

    self:revealCell(x, y)
end

---entry point for secondary mouse action event(s)
---@param x integer
---@param y integer
function Board:secondaryAction(x, y)
    if self.isGameOver then
        return
    end

    local cell = self:getCell(x, y)
    if cell.state == STATE.UNSEEN then
        cell.state = STATE.FLAGGED
    elseif cell.state == STATE.FLAGGED then
        cell.state = STATE.UNSEEN
    elseif cell.state == STATE.SEEN and VALUE[cell.value] > 0 then
        local flaggedNeighbors = 0
        self:doNeighbor(x, y, function(...)
            if self:getCell(...).state == STATE.FLAGGED then
                flaggedNeighbors = flaggedNeighbors + 1
            end
        end)

        if flaggedNeighbors == VALUE[cell.value] then
            self:doNeighbor(x, y, Utils.bind(self, self.revealCell))
        end
    end
end

---reveal a single cell on the board
---@param x integer
---@param y integer
function Board:revealCell(x, y)
    local cell, isNew = self:getCell(x, y)
    if cell.state ~= STATE.UNSEEN then
        return
    end

    -- if forcing no guess, newly generated cells being revealed are always mines
    if isNew and self.forceNoGuess then
        cell.value = VALUE.MINE
    end

    if cell.value == VALUE.MINE then
        cell.state = STATE.SEEN
        self:endGame(x, y)
    else
        self:calculateValue(x, y)
        if cell.value == VALUE.NONE then
            self:revealRegion(x, y)
        else
            cell.state = STATE.SEEN
            self.cleared = self.cleared + 1
        end

        -- self:decayRegion(x, y)

        self:onScoreChange()
    end
end

---reveal a region of cells on the board
---@param x integer
---@param y integer
function Board:revealRegion(x, y)
    local queuePointer = 1
    local queue = { { x, y, 0 } }
    local function insertToQueue(lx, ly, depth)
        table.insert(queue, { lx, ly, depth })
    end
    while (queuePointer <= #queue) do
        local lx, ly, depth = unpack(queue[queuePointer])
        local cell = self:getCell(lx, ly)
        if cell.state == STATE.UNSEEN then
            cell.state = STATE.SEEN

            self:onCellGradualReveal(lx, ly, depth)

            self:calculateValue(lx, ly)
            self.cleared = self.cleared + 1
            if cell.value == VALUE.NONE then
                self:doNeighbor(lx, ly, insertToQueue, depth + 1)
            end
        end
        queuePointer = queuePointer + 1
    end
end

---decay mines within a region
---@param x integer
---@param y integer
function Board:decayRegion(x, y)
    local queuePointer = 1
    local queue = { { x, y, 1 } }
    local function insertToQueue(lx, ly, depth)
        table.insert(queue, { lx, ly, depth })
    end

    self:doNeighbor(x, y, insertToQueue, 2)

    local neighborsSatisfied = true
    local function checkSatisfied(lx, ly)
        local lcell = self:getCell(lx, ly)
        if lcell.value ~= VALUE.MINE then
            local unseenNeighbors = 0
            local mineNeighbors = 0
            self:doNthDistanceNeighbors(2, lx, ly, function(llx, lly)
                local llcell = self:getCell(llx, lly)
                if llcell.state ~= STATE.SEEN then
                    unseenNeighbors = unseenNeighbors + 1
                end
                if llcell.value == VALUE.MINE then
                    mineNeighbors = mineNeighbors + 1
                end
            end)

            if unseenNeighbors ~= mineNeighbors then
                neighborsSatisfied = false
            end
        end
    end

    local function recalcValue(lx, ly)
        local lcell = self:getCell(lx, ly)
        if lcell.value ~= VALUE.MINE then
            self:calculateValue(lx, ly)
        end
    end

    while (queuePointer <= #queue) do
        local lx, ly, depth = unpack(queue[queuePointer])
        local cell = self:getCell(lx, ly)
        if not cell.extra then
            neighborsSatisfied = true
            self:doNeighbor(lx, ly, checkSatisfied)

            if neighborsSatisfied then
                cell.extra = true
                cell.value = VALUE.NONE
                cell.state = STATE.SEEN

                self:calculateValue(lx, ly)
                self:doNeighbor(lx, ly, recalcValue)

                self:doNeighbor(lx, ly, insertToQueue, depth + 1)
            end
        end
        queuePointer = queuePointer + 1
    end
end

---get the cell at the specified coordinates
---if not present, generates a new cell on demand
---@param x integer
---@param y integer
---@return Board.Cell, boolean
function Board:getCell(x, y)
    local isNew = false
    if not self.cells[y] then
        self.cells[y] = {}
    end
    if not self.cells[y][x] then
        self.cells[y][x] = self:makeCell()
        isNew = true
    end
    return self.cells[y][x], isNew
end

---get the cell without generating on demand
---@param x integer
---@param y integer
---@return Board.Cell?
function Board:rawGetCell(x, y)
    if x == math.huge or y == math.huge then
        return nil
    elseif not self.cells[y] or not self.cells[y][x] then
        return nil
    end
    return self.cells[y][x]
end

---updates the cell value at the specified coordinates
---@param x integer
---@param y integer
function Board:calculateValue(x, y)
    local cell = self:getCell(x, y)
    cell.value = 0
    local function count(lx, ly)
        local neighborCell = self:getCell(lx, ly)
        if neighborCell.value == VALUE.MINE then
            cell.value = cell.value + 1
        end
    end

    self:doNeighbor(x, y, count)
    cell.value = VALUE[cell.value]
end

---creates a cell
---@param forceClear boolean? flag to prevent mine generation
---@return Board.Cell
function Board:makeCell(forceClear)
    local cell = {}
    cell.state = STATE.UNSEEN

    if not forceClear and love.math.random() < 0.2 + (0.6 * (1 - self.mineWeight)) then
        cell.value = VALUE.MINE
    else
        cell.value = VALUE.NONE
    end

    self.mineWeight = self.mineWeight * MINE_ESCALATION_RATE
    return cell
end

---performs a provided callback on all neighbors of a coordinate location
---@param x integer
---@param y integer
---@param callback fun(x: integer, y: integer, ...: any)
---@param ... any additional parameters for callback
function Board:doNeighbor(x, y, callback, ...)
    callback(x - 1, y - 1, ...)
    callback(x - 1, y, ...)
    callback(x - 1, y + 1, ...)
    callback(x, y - 1, ...)
    callback(x, y + 1, ...)
    callback(x + 1, y - 1, ...)
    callback(x + 1, y, ...)
    callback(x + 1, y + 1, ...)
end

---performs a provided callback on all 2 distance neighbors of a coordinate location
---@param n integer
---@param x integer
---@param y integer
---@param callback fun(x: integer, y: integer, ...: any)
---@param ... any additional parameters for callback
function Board:doNthDistanceNeighbors(n, x, y, callback, ...)
    for ix = -n, n do
        for iy = -n, n do
            if ix ~= 0 or iy ~= 0 then
                callback(x + ix, y + iy, ...)
            end
        end
    end
end

---checks if two coordinate pairs are adjacent
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@return boolean
function Board:isNeighbor(x1, y1, x2, y2)
    return not (math.abs(x1 - x2) > 1 or math.abs(y1 - y2) > 1)
end

local savePack = {
    state = {
        [0] = 10,
        [10] = 0,
        [1] = 20,
        [20] = 1,
        [2] = 30,
        [30] = 2,
    },
    value = {
        [" "] = 0,
        [0] = " ",
        ["1"] = 1,
        [1] = "1",
        ["2"] = 2,
        [2] = "2",
        ["3"] = 3,
        [3] = "3",
        ["4"] = 4,
        [4] = "4",
        ["5"] = 5,
        [5] = "5",
        ["6"] = 6,
        [6] = "6",
        ["7"] = 7,
        [7] = "7",
        ["8"] = 8,
        [8] = "8",
        ["*"] = 9,
        [9] = "*",
    },
}

---loads the board state
---@param file love.File
function Board:loadFromFile(file)
    local valid, weight, cleared, cells, settings = self:loadFromFileInternal(file)
    if valid then
        self:setGameMode(settings.gameMode)

        self.mineWeight = weight
        self.cleared = cleared
        self.cells = cells

        self.begun = true
        self.isGameOver = false

        self:onScoreChange()
    end
end

BOARD_FILE_VERSION_NUMBER = 1

---loads the board state from a file.
---@param file love.File
---@return true flag indicating validity
---@return number weight
---@return integer cleared
---@return table<integer, table<integer, Board.Cell>> cells
---@return table settings
---@overload fun(file: love.File): false
function Board:loadFromFileInternal(file)
    if not file:isOpen() and not file:open("r") then
        love.window.showMessageBox("Error Reading", "could not load the provided file", "error")
        return false
    end
    local header = file:read(love.data.getPackedSize("Bnn"))
    local valid, version, weight, cleared = pcall(love.data.unpack, "Bnn", header)
    if not valid or version ~= BOARD_FILE_VERSION_NUMBER or type(weight) ~= "number" or type(cleared) ~= "number" then
        love.window.showMessageBox("Error Reading", "bad file header.", "error")
        return false
    end
    local valid, settings = self:loadSettings(file)
    if not valid then
        love.window.showMessageBox("Error Reading Save", "bad settings header.", "error")
        return false
    end

    local cells = {}
    local sizej = love.data.getPackedSize("j")
    local sizejB = love.data.getPackedSize("jB")
    local seen = 0
    local data, good, y, x, d
    repeat
        data = file:read(sizej)
        good, y = pcall(love.data.unpack, "j", data)
        if good and y then
            cells[y] = {}
            repeat
                data = file:read(sizejB)
                good, x, d = pcall(love.data.unpack, "jB", data)
                if not good or not x or not d then
                    love.window.showMessageBox("Error Reading", "corruption detected loading aborted", "error")
                    return false
                elseif d ~= 0 then
                    if d < 10 or d > 39 then
                        love.window.showMessageBox("Error Reading", "corruption detected loading aborted", "error")
                        return false
                    end
                    cells[y][x] = {
                        state = savePack.state[d - (d % 10)],
                        value = savePack.value[d % 10],
                        anim = 0,
                    }
                    if cells[y][x].state == STATE.SEEN then
                        seen = seen + 1
                    end
                end
            until d == 0
        end
    until not good or not y
    if seen ~= cleared then
        love.window.showMessageBox("Invalid Board State",
            "board state contained discrepancies.",
            "error")
        return false
    end
    return true, weight, cleared, cells, settings
end

---loads settings from file
---@param file love.File
---@return boolean
---@return table
function Board:loadSettings(file)
    local settings = {}
    local settingHeader = file:read(love.data.getPackedSize("B"))
    local valid, gameMode = pcall(love.data.unpack, "B", settingHeader)

    if valid then
        if gameMode > GAME_MODE_COUNT then valid = false end
        settings.gameMode = gameMode
    end

    return valid, settings
end

function Board:saveToFile(filename)
    local file = love.filesystem.newFile(filename)
    if not file:open("w") then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    file:write(love.data.pack("string", "Bnn", BOARD_FILE_VERSION_NUMBER, self.mineWeight, self.cleared))
    self:saveSettings(file)
    for y, row in pairs(self.cells) do
        ---@diagnostic disable-next-line: param-type-mismatch
        file:write(love.data.pack("string", "j", y))
        for x, cell in pairs(row) do
            ---@diagnostic disable-next-line: param-type-mismatch
            file:write(love.data.pack("string", "j", x))
            ---@diagnostic disable-next-line: param-type-mismatch
            file:write(love.data.pack("string", "B", savePack.state[cell.state] + savePack.value[cell.value]))
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        file:write(love.data.pack("string", "jB", 0, 0))
    end
    file:close()
end

---save game settings required
---@param file love.File
function Board:saveSettings(file)
    local settingsHeader = love.data.pack("string", "B", self.gameMode) --[[@as string]]
    file:write(settingsHeader)
end

return Board
