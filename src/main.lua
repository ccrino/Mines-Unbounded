-- luacheck: std +love
PROF_CAPTURE = false
local jprof = require "jprof"

require "common"
local Config = require "config"
local AxisControl = require "axisControl"
local Theory = require "AsciiTheory"
local TheorySymbols = require "AsciiTheory/SymbolDictionary"
local Scene = require "scene"
local Board = require "board"

local commands = {}
local mine = {}

---@class gameState
---@field xAxisControl AxisControl
---@field yAxisControl AxisControl
---@field SCALE integer
---@field MAP_SCALE integer
---@field VIEW_OFFSET_X integer
---@field VIEW_OFFSET_Y integer
---@field VIEW_WIDTH integer
---@field VIEW_HEIGHT integer
---@field SCREEN_HEIGHT integer
---@field SCREEN_WIDTH integer
---@field UIStateCanvas table<UI_STATE, love.Canvas>
---@field boardCanvas love.Canvas
---@field mapCanvas love.Canvas
---@field demoCanvas love.Canvas
---@field boardText love.Text
---@field exampleText love.Text
---@field demoText love.Text
---@field Demo { rawGetCell: fun(self, x: integer, y: integer): (Board.Cell | nil) }
---@field LossAnimationState table | nil
---@field AnimatingLoss boolean | nil
---@field keyboardNavigation boolean | nil
---@field isMenuNavigating boolean | nil
---@field mapMode boolean | nil
---@field updateGamemodeOnNewGame boolean | nil
local gameState = {}

---@enum UI_STATE
local UI_STATE = {
    GAME = 1,
    MENU = 2,
}

local font
function love.load()
    font = love.graphics.newImageFont(
        "Assets/cp437_16x16.png",
        [[ ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼]] ..
        [[ !"#$%&'()*+,-./0123456789:;<=>?]] ..
        [[@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_]] ..
        [[`abcdefghijklmnopqrstuvwxyz{|}~⌂]] ..
        [[ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒ]] ..
        [[áíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐]] ..
        [[└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀]] ..
        [[αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ]]
    )
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    Theory:Init(47, 50)
    Theory:registerCommandHandlers(commands)

    Scene()

    Config:load()
    local paletteStr = Utils.zeroLeftPad(Config:getPaletteNumber(), 3)
    Theory:getElementById(ManagedObjects.PaletteReadout) --[[@as TextField]]
        :setText(paletteStr)

    local palette = Config:getPaletteBase()
    Theory:setMappedColors(palette)
    love.graphics.setBackgroundColor(palette.darkest)

    gameState = {
        --view constant
        SCALE = 16,
        MAP_SCALE = 4,
        VIEW_OFFSET_X = 7,
        VIEW_OFFSET_Y = 7,
        VIEW_WIDTH = 32,
        VIEW_HEIGHT = 32,
        SCREEN_HEIGHT = 50,
        SCREEN_WIDTH = 47,

        gameMode = GAME_MODE.NORMAL,

        --view variables
        boardCanvas = love.graphics.newCanvas(),
        boardText = love.graphics.newText(font),
        mapCanvas = love.graphics.newCanvas(),

        Demo = {
            [3] = {
                [4] = { state = 1, value = "3" },
                [5] = { state = 1, value = "4" },
                [6] = { state = 1, value = "5" },
                [7] = { state = 1, value = "6" },
                [8] = { state = 1, value = "7" },
                [9] = { state = 2, value = "*" }
            },
            [4] = {
                [4] = { state = 1, value = "1" },
                [5] = { state = 1, value = "1" },
                [6] = { state = 2, value = "*" },
                [7] = { state = 2, value = "*" },
                [8] = { state = 2, value = "*" },
                [9] = { state = 2, value = "*" }
            },
            [5] = {
                [4] = { state = 1, value = "1" },
                [5] = { state = 1, value = "1" },
                [6] = { state = 1, value = "4" },
                [7] = { state = 2, value = "*" },
                [8] = { state = 1, value = "8" },
                [9] = { state = 0, value = "*" }
            },
            [6] = {
                [4] = { state = 1, value = "1" },
                [5] = { state = 1, value = " " },
                [6] = { state = 1, value = "2" },
                [7] = { state = 2, value = "*" },
                [8] = { state = 0, value = "*" },
                [9] = { state = 1, value = "*" }
            },
            [7] = {
                [4] = { state = 1, value = "1" },
                [5] = { state = 1, value = "1" },
                [6] = { state = 1, value = "1" },
                [7] = { state = 1, value = "2" },
                [8] = { state = 1, value = "3" },
                [9] = { state = 1, value = "2" }
            },

            rawGetCell = function(self, x, y)
                if x == math.huge or y == math.huge then
                    return nil
                elseif not self[y] or not self[y][x] then
                    return nil
                end
                return self[y][x]
            end
        },

        previousUIState = nil,
        UIState = UI_STATE.GAME,
        UIStateCanvas = {
            [UI_STATE.GAME] = love.graphics.newCanvas(),
            [UI_STATE.MENU] = love.graphics.newCanvas(),
        },
        UIStateChangeCanvasesDrawn = false,
        UIStateChangeProgress = 1,
        slideDirection = nil,
        UIStateSlideX = 0,
        UIStateSlideY = 0,

        demoCanvas = love.graphics.newCanvas(),
        demoText = love.graphics.newText(font),
        exampleText = love.graphics.newText(font),

        animatingList = {},
        explodeList = {},

        --Interface variables
        mouseX = 0,
        mouseY = 0,

        xAxisControl = AxisControl:new(),
        yAxisControl = AxisControl:new(),
    }

    mine.updateGamemodeDisplay()
    mine.updateGamemode()

    Board:setScoreChangeHandler(function(score)
        local scoreStr = Utils.zeroLeftPad(score, 7)
        Theory:getElementById(ManagedObjects.ScoreLabel) --[[@as TextField]]
            :setText(scoreStr)
    end)
    Board:setCellGradualRevealHandler(function(x, y, depth)
        local cell = Board:getCell(x, y)
        gameState.animatingList[cell] = depth * 0.1
    end)
    Board:setCellExplodeRevealHandler(function(x, y, distance, priorState)
        local cell = Board:getCell(x, y)
        gameState.explodeList[cell] = { t = 1 + (distance / 4), x = x, y = y, ps = priorState }
    end)
    Board:newGame()
end

function commands.newGame()
    mine.hideLossAnimation()
    gameState.animatingList = {}
    gameState.explodeList = {}
    if gameState.updateGamemodeOnNewGame then
        gameState.updateGamemodeOnNewGame = nil
        mine.updateGamemode(true)
    end
    Board:newGame()
end

function commands.openMenu()
    if gameState.AnimatingLoss then
        return
    end
    mine.setUIState(UI_STATE.MENU)
end

function commands.closeMenu()
    mine.setUIState(UI_STATE.GAME)
end

function commands.up(param)
    Config:rotateSymbolColor(param, 1)
end

function commands.down(param)
    Config:rotateSymbolColor(param, -1)
end

function commands.toggleCheck()
    Config:toggleShowChecks()
end

function commands.setToDefault()
    Config:setDefault(true)
end

local function updatePalette()
    local palette = Config:getPaletteBase()
    Theory:setMappedColors(palette)
    love.graphics.setBackgroundColor(palette.darkest)
    local paletteStr = Utils.zeroLeftPad(Config:getPaletteNumber(), 3)
    Theory:getElementById(ManagedObjects.PaletteReadout) --[[@as TextField]]
        :setText(paletteStr)
end

function commands.leftPalette()
    Config:rotatePalette(-1)
    updatePalette()
end

function commands.rightPalette()
    Config:rotatePalette(1)
    updatePalette()
end

function mine.updateGamemode(forceSet)
    -- if in progress cache off game mode for later
    if Board.begun and not forceSet then
        gameState.updateGamemodeOnNewGame = true
        return
    end

    gameState.gameMode = Config:getGameMode()
    if gameState.gameMode == GAME_MODE.NORMAL then
        Board:setNoGuess(false)
    elseif gameState.gameMode == GAME_MODE.HARD then
        Board:setNoGuess(true)
    end
end

function mine.updateGamemodeDisplay()
    local gamemodeDisplay = Theory:getElementById(ManagedObjects.GamemodeDisplay) --[[@as TextField]]
    local gamemodeDescribe = Theory:getElementById(ManagedObjects.GamemodeDescribe) --[[@as TextField]]

    local selectedGamemode = Config:getGameMode()
    if selectedGamemode == GAME_MODE.NORMAL then
        gamemodeDisplay:setText("Normal")
        gamemodeDescribe:setText([[
            board = ∞

            * = lose
            _ = ₧
            ↑₧ = ↑*%

        ]])
    elseif selectedGamemode == GAME_MODE.HARD then
        gamemodeDisplay:setText("Hard")
        gamemodeDescribe:setText([[
            board = ∞

            * = lose
            _ = ₧
            ↑₧ = ↑*%
            no guesses
        ]])
    end
end

function commands.leftGamemode()
    Config:rotateGameMode(-1)
    mine.updateGamemodeDisplay()
    mine.updateGamemode()
end

function commands.rightGamemode()
    Config:rotateGameMode(1)
    mine.updateGamemodeDisplay()
    mine.updateGamemode()
end

function mine.setUIState(state)
    local currentState = gameState.UIState

    if gameState.isMenuNavigating then
        Theory:setFocused(
            state == UI_STATE.GAME
            and ManagedObjects.BtnOpenMenu
            or ManagedObjects.BtnCloseMenu)
    end

    gameState.UIStateChangeCanvasesDrawn = false
    gameState.UIStateChangeProgress = 0
    gameState.slideDirection = math.ceil(love.math.random() * 4)

    gameState.previousUIState = currentState
    gameState.UIState = state
end

function mine.isInChangeStateInProgress()
    return gameState.UIStateChangeProgress ~= 1
end

function mine.getCurrentUIState()
    return gameState.UIState
end

function mine.isInGameState()
    return gameState.UIState == UI_STATE.GAME and not mine.isInChangeStateInProgress()
end

function mine.isInMenuState()
    return gameState.UIState == UI_STATE.MENU and not mine.isInChangeStateInProgress()
end

function mine.showLossAnimation()
    if not mine.isInGameState() then
        return
    end

    gameState.AnimatingLoss = true
    gameState.LossAnimationState = {
        signalLostTimer = Utils.new_timer(0.5),
        expirationTimer = Utils.new_timer(2.5),
        animationTimer = Utils.new_timer(0.1),
        commandText = {},
        showBoard = true,
    }
end

function mine.updateLossAnimation(dt)
    if gameState.LossAnimationState.signalLostTimer then
        if gameState.LossAnimationState.signalLostTimer(dt) then
            local gameWindow = Theory:getElementById(ManagedObjects.GameWindow) --[[@as Window]]
            local signalLostWindow = Theory:getElementById(ManagedObjects.SignalLostWindow) --[[@as Window]]
            Theory:attach(gameWindow, signalLostWindow)
            Theory:forceRepaintAll()

            gameState.LossAnimationState.signalLostTimer = nil
            gameState.LossAnimationState.showBoard = false
        end
    elseif gameState.LossAnimationState.animationTimer(dt) then
        gameState.LossAnimationState.showBoard =
            love.math.random(0, 6) >=
            (gameState.LossAnimationState.showBoard and 5 or 6)
        local chunks = Utils.clamp(love.math.random(0, 2) + love.math.random(0, 2) + love.math.random(-1, 0), 0, 4)
        local commandString = ""
        for i = 1, chunks do
            for _ = 1, 3 do
                commandString = commandString .. TheorySymbols[love.math.random(1, 128)]
            end
            if i ~= chunks then
                commandString = commandString .. " "
            end
        end

        if #gameState.LossAnimationState.commandText > 13 then
            table.remove(gameState.LossAnimationState.commandText, 1)
        end
        table.insert(gameState.LossAnimationState.commandText, commandString)

        local commandsField = Theory:getElementById(ManagedObjects.SignalDump) --[[@as TextField]]
        commandsField:setText(table.concat(gameState.LossAnimationState.commandText, "\n"))
        Theory:forceRepaintAll()
    end
end

function mine.hideLossAnimation()
    gameState.AnimatingLoss = nil
    gameState.LossAnimationState = nil

    local signalLostWindow = Theory:getElementById(ManagedObjects.SignalLostWindow) --[[@as Window]]
    Theory:detach(signalLostWindow)
end

local was_exploding = false
local explode_velocity = 1
function love.update(dt)
    jprof.push "frame"
    jprof.push "update"

    if not gameState.keyboardNavigation then
        gameState.mouseX, gameState.mouseY = love.mouse.getPosition()
    end
    Theory:update(dt)

    if gameState.AnimatingLoss then
        if gameState.LossAnimationState.expirationTimer(dt) then
            mine.hideLossAnimation()
        else
            mine.updateLossAnimation(dt)
        end
    end

    if mine.isInGameState() then
        gameState.xAxisControl:update(dt)
        gameState.yAxisControl:update(dt)
    end

    for cell, time in pairs(gameState.animatingList) do
        time = time - dt
        if time <= 0 then
            gameState.animatingList[cell] = nil
        else
            gameState.animatingList[cell] = time
        end
    end

    if next(gameState.explodeList) ~= nil then
        if was_exploding then
            explode_velocity = explode_velocity + dt
        else
            explode_velocity = 1
        end

        for cell, o in pairs(gameState.explodeList) do
            o.t = o.t - (explode_velocity * dt)
            if o.t <= 0 then
                gameState.explodeList[cell] = nil
            end
        end

        was_exploding = true
    end

    mine.handleUIStateChange(dt)
    jprof.pop "update"
end

function mine.handleUIStateChange(dt)
    local progress = gameState.UIStateChangeProgress

    --update theory and render previous state
    if progress == 0 then
        -- render previous state before change
        love.graphics.setCanvas(gameState.UIStateCanvas[gameState.previousUIState])
        love.graphics.clear()
        mine.drawUIState(gameState.previousUIState)
        love.graphics.setCanvas()

        local prevStateElem = mine.getTheoryElementForState(gameState.previousUIState)
        local curStateElem = mine.getTheoryElementForState(gameState.UIState)
        Theory:detach(prevStateElem)
        Theory:attach(1, curStateElem)
    end

    progress = Utils.clamp(progress + dt, 0, 1)
    local slide = Utils.easeInOutExp(progress)

    local direction = gameState.slideDirection
    if direction == 1 then -- UP
        gameState.UIStateSlideX = 0
        gameState.UIStateSlideY = slide * -gameState.SCREEN_HEIGHT * gameState.SCALE
    elseif direction == 2 then -- RIGHT
        gameState.UIStateSlideX = slide * gameState.SCREEN_WIDTH * gameState.SCALE
        gameState.UIStateSlideY = 0
    elseif direction == 3 then -- DOWN
        gameState.UIStateSlideX = 0
        gameState.UIStateSlideY = slide * gameState.SCREEN_HEIGHT * gameState.SCALE
    elseif direction == 4 then -- LEFT
        gameState.UIStateSlideX = slide * -gameState.SCREEN_WIDTH * gameState.SCALE
        gameState.UIStateSlideY = 0
    end

    gameState.UIStateChangeProgress = progress
end

---returns a view element for a specified UI State
---@param state UI_STATE
---@return Window
function mine.getTheoryElementForState(state)
    if state == UI_STATE.GAME then
        return Theory:getElementById(ManagedObjects.GameWindow) --[[@as Window]]
    elseif state == UI_STATE.MENU then
        return Theory:getElementById(ManagedObjects.MenuWindow) --[[@as Window]]
    else
        error "Unknown UI state provided to get view element"
    end
end

function love.draw()
    if mine.isInChangeStateInProgress() then
        love.graphics.setCanvas(gameState.UIStateCanvas[gameState.UIState])
        love.graphics.clear()
        mine.drawUIState(mine.getCurrentUIState())
        love.graphics.setCanvas()

        love.graphics.draw(gameState.UIStateCanvas[gameState.previousUIState],
            gameState.UIStateSlideX, gameState.UIStateSlideY)
        love.graphics.draw(gameState.UIStateCanvas[gameState.UIState],
            mine.getCurrentUIStateLocation())
    else
        mine.drawUIState(mine.getCurrentUIState())
    end

    jprof.pop "frame"
end

function mine.getCurrentUIStateLocation()
    local direction = gameState.slideDirection
    if direction == 1 then     -- UP
        return gameState.UIStateSlideX, gameState.UIStateSlideY + (gameState.SCREEN_HEIGHT * gameState.SCALE)
    elseif direction == 2 then --RIGHT
        return gameState.UIStateSlideX - (gameState.SCREEN_WIDTH * gameState.SCALE), gameState.UIStateSlideY
    elseif direction == 3 then --DOWN
        return gameState.UIStateSlideX, gameState.UIStateSlideY - (gameState.SCREEN_HEIGHT * gameState.SCALE)
    elseif direction == 4 then --LEFT
        return gameState.UIStateSlideX + (gameState.SCREEN_WIDTH * gameState.SCALE), gameState.UIStateSlideY
    end
end

function mine.drawUIState(state)
    if state == UI_STATE.GAME then
        mine.drawUIStateGame()
    elseif state == UI_STATE.MENU then
        mine.drawUIStateMenu()
    end
end

function mine.drawUIStateGame()
    Theory:draw()

    love.graphics.setColor(COLORS.white)
    if gameState.AnimatingLoss and not gameState.LossAnimationState.showBoard then
        -- do nothing
    elseif not gameState.mapMode then
        mine.printBoard()
    else
        mine.printMapMode()
    end
end

function mine.drawUIStateMenu()
    Theory:draw()

    mine.printExampleNumbers()
    mine.printDemoBoard()
end

function mine.actOnBoard(x, y, isPrimary)
    if mine.isInGameState() and not gameState.mapMode then
        local viewX = math.floor(x / gameState.SCALE)
        local viewY = math.floor(y / gameState.SCALE)
        if not mine.isViewCoordWithinBoard(viewX, viewY) then
            return
        end

        local wasGameOver = Board.isGameOver
        local boardX, boardY = mine.viewToBoard(viewX, viewY)

        if isPrimary then
            Board:primaryAction(boardX, boardY)
        else
            Board:secondaryAction(boardX, boardY)
        end

        if not wasGameOver and Board.isGameOver then
            mine.showLossAnimation()
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState.isMenuNavigating or gameState.keyboardNavigation then
        gameState.isMenuNavigating = false
        gameState.keyboardNavigation = false
        return
    end

    Theory:mousepressed(x, y, button)

    mine.actOnBoard(x, y, button == 1)
end

local KeyBindings = {
    { -- primary binding
        UP = "w",
        DOWN = "s",
        LEFT = "a",
        RIGHT = "d",
        KEYBOARD_RIGHT_CLICK = "k",
        KEYBOARD_LEFT_CLICK = "j",
        KEYBOARD_NAVIGATE = "l",
        MOUSE_MODE = "m",
        MAP_MODE = "z",
        MAP_ZOOM_IN = "=",
        MAP_ZOOM_OUT = "-",
        DEBUG = "f12",
        INVERT = "f3",
        DUMP_COLOR = "f5",
    },
    { -- secondary binding
        UP = "up",
        DOWN = "down",
        LEFT = "left",
        RIGHT = "right",
    },
}

local GamePadBindings = {
    {
        UP = "dpup",
        DOWN = "dpdown",
        LEFT = "dpleft",
        RIGHT = "dpright",
        KEYBOARD_RIGHT_CLICK = "b",
        KEYBOARD_LEFT_CLICK = "a",
        KEYBOARD_NAVIGATE = "y",
        MAP_MODE = "x",
    },
    {}
}

local function bindingToMap(bindingList)
    local map = {}
    for i, binding in ipairs(bindingList) do
        map[i] = {}
        for bind, key in pairs(binding) do
            map[i][key] = bind
        end
    end
    return map
end

local KeyMap = bindingToMap(KeyBindings)
local GamePadMap = bindingToMap(GamePadBindings)

function love.keypressed(key)
    local bind = KeyMap[1][key] or KeyMap[2][key]
    mine.bindPressed(bind)
end

function love.keyreleased(key)
    local bind = KeyMap[1][key] or KeyMap[2][key]
    mine.bindReleased(bind)
end

function love.gamepadpressed(_joystick, button)
    local bind = GamePadMap[1][button] or GamePadMap[2][button]
    mine.bindPressed(bind)
end

function love.gamepadreleased(_joystick, button)
    local bind = GamePadMap[1][button] or GamePadMap[2][button]
    mine.bindReleased(bind)
end

function mine.bindPressed(bind)
    if not bind then return end

    if bind == "UP" then
        if gameState.isMenuNavigating then
            Theory:navigateKeyMode(THEORY_NAV_DIRECTION.UP)
        else
        gameState.yAxisControl:keyDown(-1)
        end
    elseif bind == "DOWN" then
        if gameState.isMenuNavigating then
            Theory:navigateKeyMode(THEORY_NAV_DIRECTION.DOWN)
        else
        gameState.yAxisControl:keyDown(1)
        end
    elseif bind == "LEFT" then
        if gameState.isMenuNavigating then
            Theory:navigateKeyMode(THEORY_NAV_DIRECTION.LEFT)
        else
        gameState.xAxisControl:keyDown(-1)
        end
    elseif bind == "RIGHT" then
        if gameState.isMenuNavigating then
            Theory:navigateKeyMode(THEORY_NAV_DIRECTION.RIGHT)
        else
        gameState.xAxisControl:keyDown(1)
        end
    elseif bind == "KEYBOARD_RIGHT_CLICK" then
        if gameState.isMenuNavigating then

        elseif gameState.keyboardNavigation then
            mine.actOnBoard(gameState.mouseX, gameState.mouseY, false)
        elseif not gameState.mapMode then
            gameState.keyboardNavigation = true
            gameState.mouseX = (gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH / 2) * gameState.SCALE
            gameState.mouseY = (gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT / 2) * gameState.SCALE
        end
    elseif bind == "KEYBOARD_LEFT_CLICK" then
        if gameState.isMenuNavigating then
            Theory:clickKeyMode()
        elseif gameState.keyboardNavigation then
            mine.actOnBoard(gameState.mouseX, gameState.mouseY, true)
        end
    elseif bind == "KEYBOARD_NAVIGATE" then
        if not gameState.isMenuNavigating then
            gameState.keyboardNavigation = false
            gameState.isMenuNavigating = true
            Theory:setMouseMode(false)
            Theory:setFocused(
                gameState.UIState == UI_STATE.GAME
                and ManagedObjects.BtnOpenMenu
                or ManagedObjects.BtnCloseMenu
            )
        else
            gameState.keyboardNavigation = true
            gameState.mouseX = (gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH / 2) * gameState.SCALE
            gameState.mouseY = (gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT / 2) * gameState.SCALE
            gameState.isMenuNavigating = false
            Theory:setMouseMode(true)
        end
    elseif bind == "MOUSE_MODE" then
        if gameState.keyboardNavigation then
            gameState.keyboardNavigation = false
            gameState.isMenuNavigating = false
        end
    elseif bind == "MAP_MODE" then
        gameState.mapMode = not gameState.mapMode
        if gameState.mapMode then
            gameState.xAxisControl:setSpeed(gameState.SCALE / gameState.MAP_SCALE)
            gameState.yAxisControl:setSpeed(gameState.SCALE / gameState.MAP_SCALE)
        else
            gameState.xAxisControl:setSpeed(1)
            gameState.yAxisControl:setSpeed(1)
        end
    elseif bind == "MAP_ZOOM_IN" then
        if gameState.mapMode and gameState.MAP_SCALE < 8 then
            gameState.MAP_SCALE = gameState.MAP_SCALE * 2
            gameState.xAxisControl:setSpeed(gameState.SCALE / gameState.MAP_SCALE)
            gameState.yAxisControl:setSpeed(gameState.SCALE / gameState.MAP_SCALE)
        end
    elseif bind == "MAP_ZOOM_OUT" then
        if gameState.mapMode and gameState.MAP_SCALE > 1 then
            gameState.MAP_SCALE = gameState.MAP_SCALE / 2
            gameState.xAxisControl:setSpeed(gameState.SCALE / gameState.MAP_SCALE)
            gameState.yAxisControl:setSpeed(gameState.SCALE / gameState.MAP_SCALE)
        end
    elseif bind == "INVERT" then
        Config:invertPalette()
        updatePalette()
    elseif bind == "DUMP_COLOR" then
        Config:dumpColors()
    elseif bind == "DEBUG" then
        debug.debug()
    end
end

function mine.bindReleased(bind)
    if not bind then return end

    if not gameState.isMenuNavigating then
    if bind == "UP" then
        gameState.yAxisControl:keyUp(-1)
    elseif bind == "DOWN" then
        gameState.yAxisControl:keyUp(1)
    elseif bind == "LEFT" then
        gameState.xAxisControl:keyUp(-1)
    elseif bind == "RIGHT" then
        gameState.xAxisControl:keyUp(1)
    end
    end
end

function love.gamepadaxis(_joystick, axis, value)
    if not gameState.isMenuNavigating then
    if axis == "leftx" then
        gameState.xAxisControl:axisUpdate(value)
    elseif axis == "lefty" then
        gameState.yAxisControl:axisUpdate(value)
        end
    end
end

function mine.printBoard()
    mine.printBoardInternal(
        gameState.boardCanvas,
        gameState.boardText,
        gameState.VIEW_OFFSET_X, gameState.VIEW_OFFSET_Y,
        gameState.VIEW_WIDTH, gameState.VIEW_HEIGHT,
        gameState.xAxisControl:getPosition(),
        gameState.yAxisControl:getPosition(),
        Board
    )
end

function mine.printMapMode()
    local doChecks = Config:getShowChecks()
    local paletteExt = Config:getPaletteExt()
    local RESCALE = gameState.MAP_SCALE

    local xmin = 0
    local xmax = ((gameState.VIEW_WIDTH + 1) * gameState.SCALE / RESCALE) - 1

    local ymin = 0
    local ymax = ((gameState.VIEW_HEIGHT + 1) * gameState.SCALE / RESCALE) - 1

    local xBoardZoomInset = math.floor((xmax - gameState.VIEW_WIDTH) / 2)
    local yBoardZoomInset = math.floor((ymax - gameState.VIEW_HEIGHT) / 2)

    local cellOffsetX = gameState.xAxisControl:getPosition()
        - xBoardZoomInset
        - math.floor(gameState.xAxisControl:getSmoothedPositionNudge())

    local cellOffsetY = gameState.yAxisControl:getPosition()
        - yBoardZoomInset
        - math.floor(gameState.yAxisControl:getSmoothedPositionNudge())

    local viewOffsetX = gameState.VIEW_OFFSET_X * gameState.SCALE
    local viewOffsetY = gameState.VIEW_OFFSET_Y * gameState.SCALE

    local previousCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(gameState.mapCanvas)

    for y = ymin, ymax do
        for x = xmin, xmax do
            local cellX = x + cellOffsetX
            local cellY = y + cellOffsetY

            local cell = Board:rawGetCell(cellX, cellY)
            local isChecker = doChecks and (cellX + cellY) % 2 ~= 0

            local color
            if not cell or cell.state == STATE.UNSEEN or gameState.animatingList[cell] then
                color = isChecker and paletteExt.tiledark or paletteExt.tilelite
            elseif cell.state == STATE.FLAGGED then
                color = Config:getSymbolColor(VALUE.FLAG)
            elseif cell.value == VALUE.NONE or cell.extra then
                color = isChecker and paletteExt.bgdark or paletteExt.bglite
            else
                color = Config:getSymbolColor(cell.value)
            end
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", viewOffsetX + x * RESCALE, viewOffsetY + y * RESCALE, RESCALE, RESCALE)
        end
    end

    love.graphics.setColor(COLORS.white)
    love.graphics.rectangle("line",
        viewOffsetX + xBoardZoomInset * RESCALE,
        viewOffsetY + yBoardZoomInset * RESCALE,
        (gameState.VIEW_WIDTH + 1) * RESCALE,
        (gameState.VIEW_HEIGHT + 1) * RESCALE)


    love.graphics.setCanvas(previousCanvas)
    love.graphics.draw(gameState.mapCanvas)
end

function mine.printExampleNumbers()
    gameState.exampleText:clear()

    local row1 = { VALUE.ONE, VALUE.TWO, VALUE.THREE, VALUE.FOUR, VALUE.FIVE }
    local row2 = { VALUE.SIX, VALUE.SEVEN, VALUE.EIGHT, VALUE.FLAG, VALUE.MINE }
    local palette = Config:getPaletteBase()

    for i = 1, 5 do
        local x = 11 + 3 * (i - 1)
        mine.printToText(gameState.exampleText, row1[i], Config:getSymbolColor(row1[i]), x, 32, palette.darkest)
        mine.printToText(gameState.exampleText, row2[i], Config:getSymbolColor(row2[i]), x, 35, palette.darkest)
    end

    love.graphics.draw(gameState.exampleText)
end

function mine.printDemoBoard()
    mine.printBoardInternal(
        gameState.demoCanvas,
        gameState.demoText,
        26, 12,
        10, 10,
        1, 0,
        gameState.Demo
    )
end

---internal shared implementation of print board, used by demo and normal board
---@param canvas love.Canvas
---@param textObject love.Text
---@param viewOffsetX integer
---@param viewOffsetY integer
---@param viewWidth integer
---@param viewHeight integer
---@param boardOffsetX integer
---@param boardOffsetY integer
---@param boardAccessor { rawGetCell: fun(self: any, x: integer, y: integer): (Board.Cell | nil) }
function mine.printBoardInternal(canvas, textObject,
                                 viewOffsetX, viewOffsetY,
                                 viewWidth, viewHeight,
                                 boardOffsetX, boardOffsetY,
                                 boardAccessor)
    local previousCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas({ canvas, stencil = true } --[[@as table]])

    textObject:clear()

    local mouseBoardX, mouseBoardY = mine.mouseToBoardCoords(
        viewOffsetX, viewOffsetY,
        viewWidth, viewHeight,
        boardOffsetX, boardOffsetY
    )
    local doChecks = Config:getShowChecks()

    -- handle normal cells
    for y = viewOffsetY - 1, viewOffsetY + viewHeight + 1 do
        for x = viewOffsetX - 1, viewOffsetX + viewWidth + 1 do
            local cellX, cellY = mine.viewToBoard(x, y, viewOffsetX, viewOffsetY, boardOffsetX, boardOffsetY)
            local cell = boardAccessor:rawGetCell(cellX, cellY)
            local isChecker = doChecks and (cellX + cellY) % 2 ~= 0
            local inHalo = Board:isNeighbor(cellX, cellY, mouseBoardX, mouseBoardY)

            mine.printCell(textObject, cell, x, y, isChecker, inHalo)
        end
    end

    -- handle exploding cells, must be after normal cells to get correct draw order
    for _, object in pairs(gameState.explodeList) do
        local objectScreenX = object.x + viewOffsetX - boardOffsetX
        local objectScreenY = object.y + viewOffsetY - boardOffsetY

        if object.t > 3 then
            -- initially fake the cells prior state
            local fakeCell = { value = VALUE.MINE, state = object.ps }
            local isChecker = doChecks and (object.x + object.y) % 2 ~= 0
            local inHalo = Board:isNeighbor(object.x, object.y, mouseBoardX, mouseBoardY)
            mine.printCell(textObject, fakeCell, objectScreenX, objectScreenY, isChecker, inHalo)
        elseif object.t > 1 then
            -- glitchy cell symbol rotation
            mine.printToText(
                textObject,
                TheorySymbols[love.math.random(1, 128)],
                Config:getSymbolColor(VALUE.MINE),
                objectScreenX, objectScreenY)
        elseif object.t < 1 then
            -- expanding mine symbol
            mine.printToText(
                textObject, VALUE.MINE,
                Config:getSymbolColor(VALUE.MINE),
                objectScreenX, objectScreenY,
                nil,
                math.floor(8 * (3 - 2 * object.t)) / 8)
        end
    end

    -- setup stencils to cull overdraw
    love.graphics.stencil(function()
        love.graphics.rectangle('fill',
            viewOffsetX * gameState.SCALE,
            viewOffsetY * gameState.SCALE,
            (viewWidth + 1) * gameState.SCALE,
            (viewHeight + 1) * gameState.SCALE)
    end)
    love.graphics.setStencilTest("greater", 0)

    -- draw board text object
    love.graphics.draw(textObject)

    -- draw hover outline
    local screenX = math.floor(gameState.mouseX / gameState.SCALE)
    local screenY = math.floor(gameState.mouseY / gameState.SCALE)

    if mine.isViewCoordWithinBoard(screenX, screenY, viewOffsetX, viewOffsetY, viewWidth, viewHeight) then
        local xPositionNudge = gameState.xAxisControl:getSmoothedPositionNudge()
        local yPositionNudge = gameState.yAxisControl:getSmoothedPositionNudge()

        local adjusted_x = math.floor(gameState.SCALE * (screenX - 1 + xPositionNudge))
        local adjusted_y = math.floor(gameState.SCALE * (screenY - 1 + yPositionNudge))

        love.graphics.rectangle("line", adjusted_x, adjusted_y,
            3 * gameState.SCALE, 3 * gameState.SCALE)
    end

    love.graphics.setStencilTest()
    love.graphics.setCanvas(previousCanvas)
    love.graphics.draw(canvas)
end

---print a cell
---@param text love.Text
---@param cell? Board.Cell
---@param x integer
---@param y integer
---@param isChecker boolean
---@param inHalo boolean
function mine.printCell(text, cell, x, y, isChecker, inHalo)
    local paletteExt = Config:getPaletteExt()
    local tileColor = isChecker
        and (inHalo and paletteExt.halodark or paletteExt.tiledark)
        or (inHalo and paletteExt.halolite or paletteExt.tilelite)
    local backColor = isChecker
        and (inHalo and paletteExt.bghalolite or paletteExt.bglite)
        or (inHalo and paletteExt.bghalodark or paletteExt.bgdark)

    if not cell then
        if Board.isGameOver and love.math.random(0, 100) == 100 then
            mine.printToText(text, TheorySymbols[love.math.random(1, 128)], COLORS.white, x, y,
                COLORS.black)
        else
            mine.printToText(text, "█", tileColor, x, y)
        end
    elseif gameState.explodeList[cell] then
        mine.printToText(text, "█", backColor, x, y)
    elseif cell.state == STATE.UNSEEN or gameState.animatingList[cell] then
        mine.printToText(text, "█", tileColor, x, y)
    elseif cell.state == STATE.FLAGGED then
        mine.printToText(text, VALUE.FLAG, Config:getSymbolColor(VALUE.FLAG), x, y, tileColor)
    elseif cell.extra then
        mine.printToText(text, VALUE.NONE, Config:getSymbolColor(VALUE.NONE), x, y, backColor)
    else
        mine.printToText(text, tostring(cell.value), Config:getSymbolColor(cell.value), x, y, backColor)
    end
end

---write a character to text
---@param text love.Text
---@param symbol string
---@param foreColor RGB
---@param x integer
---@param y integer
---@param backColor? RGB
---@param overScale? number
function mine.printToText(text, symbol, foreColor, x, y, backColor, overScale)
    if not symbol or not foreColor then
        print("sym: " .. (symbol and symbol or "F") .. "\tfore: " .. (foreColor and "T" or "F"))
        debug.debug()
    end

    local xPositionNudge = gameState.xAxisControl:getSmoothedPositionNudge()
    local yPositionNudge = gameState.yAxisControl:getSmoothedPositionNudge()

    if overScale then
        x = x - (overScale - 1) / 2
        y = y - (overScale - 1) / 2
    end

    x = math.floor(gameState.SCALE * (x + xPositionNudge))
    y = math.floor(gameState.SCALE * (y + yPositionNudge))

    if backColor then
        text:add({ backColor, "█" }, x, y)
    end
    if symbol then
        text:add({ foreColor, symbol }, x, y, 0, overScale, overScale)
    else
        print("bad cell at [" .. x .. ", " .. y .. "]")
        text:add({ COLORS.red, "█" }, x, y)
    end
end

---gets the mouse location within board space (or math.huge if not within board)
---@param viewOffsetX? integer
---@param viewOffsetY? integer
---@param viewWidth? integer
---@param viewHeight? integer
---@param boardOffsetX? integer
---@param boardOffsetY? integer
---@return integer
---@return integer
function mine.mouseToBoardCoords(
    viewOffsetX, viewOffsetY,
    viewWidth, viewHeight,
    boardOffsetX, boardOffsetY)
    local screenX = math.floor(gameState.mouseX / gameState.SCALE)
    local screenY = math.floor(gameState.mouseY / gameState.SCALE)

    if not mine.isViewCoordWithinBoard(
            screenX, screenY,
            viewOffsetX, viewOffsetY,
            viewWidth, viewHeight)
    then
        return math.huge, math.huge
    end

    return mine.viewToBoard(
        screenX, screenY,
        viewOffsetX, viewOffsetY,
        boardOffsetX, boardOffsetY)
end

---check if a screen tile coordinate is within view board region
---@param viewX integer
---@param viewY integer
---@param viewOffsetX? integer
---@param viewOffsetY? integer
---@param viewWidth? integer
---@param viewHeight? integer
---@return boolean
function mine.isViewCoordWithinBoard(viewX, viewY,
                                     viewOffsetX, viewOffsetY,
                                     viewWidth, viewHeight)
    viewOffsetX = viewOffsetX or gameState.VIEW_OFFSET_X
    viewOffsetY = viewOffsetY or gameState.VIEW_OFFSET_Y
    viewWidth = viewWidth or gameState.VIEW_WIDTH
    viewHeight = viewHeight or gameState.VIEW_HEIGHT

    return viewX >= viewOffsetX
        and viewX <= viewOffsetX + viewWidth
        and viewY >= viewOffsetY
        and viewY <= viewOffsetY + viewHeight
end

---converts screen tile coordinates to board coordinates
---@param viewX integer
---@param viewY integer
---@param viewOffsetX? integer
---@param viewOffsetY? integer
---@param boardOffsetX? integer
---@param boardOffsetY? integer
---@return integer
---@return integer
function mine.viewToBoard(viewX, viewY,
                          viewOffsetX, viewOffsetY,
                          boardOffsetX, boardOffsetY)
    viewOffsetX = viewOffsetX or gameState.VIEW_OFFSET_X
    viewOffsetY = viewOffsetY or gameState.VIEW_OFFSET_Y
    boardOffsetX = boardOffsetX or gameState.xAxisControl:getPosition()
    boardOffsetY = boardOffsetY or gameState.yAxisControl:getPosition()

    return
        viewX - viewOffsetX + boardOffsetX,
        viewY - viewOffsetY + boardOffsetY
end

function love.filedropped(file)
    Board:loadFromFile(file)
end

function love.quit()
    if not Board.isGameOver and Board.begun then
        local result = love.window.showMessageBox(
            "Quit",
            "Are you sure you want to quit?",
            {
                "Quit",
                "Save and Quit",
                "Cancel",
                escapebutton = 3,
                enterbutton = 2,
            },
            "warning")

        if result == 3 then     -- cancel
            return true
        elseif result == 2 then -- save and quit
            local filename = "unbounded.save"
            local i = 0
            local file = io.open(filename)
            while file do
                file:close()
                i = i + 1
                filename = "unbounded" .. i .. ".save"
                file = io.open(filename)
            end
            Board:saveToFile(filename)
            love.window.showMessageBox("Saved", 'game saved as "' .. filename .. '"')
        end
    end
    Config:save()
    jprof.write("prof.mpack")
    return false
end
