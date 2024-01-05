-- luacheck: std +love
PROF_CAPTURE = false
local jprof = require "jprof"

require "common"
local Config = require "config"
local AxisControl = require "axisControl"
local Theory = require "AsciiTheory"
local Scene = require "scene"
local Board = require "board"

local commands = {}
local gameState = {}
local mine = {}

---@enum
local UI_STATE = {
    GAME = 1;
    MENU = 2;
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
	love.graphics.setFont(font)
    love.graphics.setDefaultFilter("nearest","nearest",0)
    Theory:Init(94, 50)
    Theory:registerCommandHandlers(commands)

    Scene()

    Config:load()
    local paletteStr = Utils.zeroLeftPad(Config:getPaletteNumber(), 3)
    Theory:getElementById("paletteReadout"):setText(paletteStr)

    local palette = Config:getPaletteBase()
    Theory:setMappedColors(palette)
    love.graphics.setBackgroundColor(palette.darkest)

    gameState = {
        --view constant
        SCALE = 16;
        VIEW_OFFSET_X = 7;
        VIEW_OFFSET_Y = 7;
        VIEW_WIDTH = 32;
        VIEW_HEIGHT = 32;
        SCREEN_HEIGHT = 50;
        SCREEN_WIDTH = 47;
        --view variables
        boardPainted = false;
        boardCanvas = love.graphics.newCanvas();
        Demo = {
            [3]={ [4]={state=1, value="3"}, [5]={state=1, value="4"}, [6]={state=1, value="5"},
                  [7]={state=1, value="6"}, [8]={state=1, value="7"}, [9]={state=2, value="*"}};
            [4]={ [4]={state=1, value="1"}, [5]={state=1, value="1"}, [6]={state=2, value="*"},
                  [7]={state=2, value="*"}, [8]={state=2, value="*"}, [9]={state=2, value="*"}};
            [5]={ [4]={state=1, value="1"}, [5]={state=1, value="1"}, [6]={state=1, value="4"},
                  [7]={state=2, value="*"}, [8]={state=1, value="8"}, [9]={state=0, value="*"}};
            [6]={ [4]={state=1, value="1"}, [5]={state=1, value=" "}, [6]={state=1, value="2"},
                  [7]={state=2, value="*"}, [8]={state=0, value="*"}, [9]={state=1, value="*"}};
            [7]={ [4]={state=1, value="1"}, [5]={state=1, value="1"}, [6]={state=1, value="1"},
                  [7]={state=1, value="2"}, [8]={state=1, value="3"}, [9]={state=1, value="2"}};
        };

        previousUIState = nil;
        UIState = UI_STATE.GAME;
        UIStateCanvas = {
            [UI_STATE.GAME] = love.graphics.newCanvas();
            [UI_STATE.MENU] = love.graphics.newCanvas();
        };
        UIStateChangeCanvasesDrawn = false;
        UIStateChangeProgress = 1;
        slideDirection = nil;
        UIStateSlideX = 0;
        UIStateSlideY = 0;

        demoPainted = false;
        demoCanvas = love.graphics.newCanvas();

        animatingList = {};

        --Interface variables
        mouseX = 0;
        mouseY = 0;

        xAxisControl = AxisControl:new();
        yAxisControl = AxisControl:new();
    }


    Board:setScoreChangeHandler(function (score)
        local scoreStr = Utils.zeroLeftPad(score, 7)
        Theory:getElementById("scoreLabel")
            :setText(scoreStr)
    end)
    Board:setCellGradualRevealHandler(function (x, y, depth)
        local cell = Board:getCell(x, y)
        gameState.animatingList[cell] = depth * 0.1
    end)
    Board:newGame()
end

function commands.newGame()
    Board:newGame()
end

function commands.openMenu()
    mine.setUIState(UI_STATE.MENU)
end

function commands.closeMenu()
    mine.setUIState(UI_STATE.GAME)
end

function commands.up(param)
    Config:rotateSymbolColor(param, 1)
    gameState.boardPainted = false
    gameState.demoPainted = false
end

function commands.down(param)
    Config:rotateSymbolColor(param, -1)
    gameState.boardPainted = false
    gameState.demoPainted = false
end

function commands.toggleCheck()
    Config:toggleShowChecks()
    gameState.boardPainted = false
    gameState.demoPainted = false
end

function commands.setToDefault()
    Config:setDefault()
    gameState.boardPainted = false
    gameState.demoPainted = false
end

local function updatePalette()
    local palette = Config:getPaletteBase()
    Theory:setMappedColors(palette)
    love.graphics.setBackgroundColor(palette.darkest)
    local paletteStr = Utils.zeroLeftPad(Config:getPaletteNumber(), 3)
    Theory:getElementById("paletteReadout")
        :setText(paletteStr)
    gameState.boardPainted = false
    gameState.demoPainted = false
end

function commands.leftPalette()
    Config:rotatePalette(-1)
    updatePalette()
end

function commands.rightPalette()
    Config:rotatePalette(1)
    updatePalette()
end

function mine.setUIState(state)
    local currentState = gameState.UIState

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

function love.update(dt)
    jprof.push "frame"
    jprof.push "update"

    if not gameState.keyboardNavigation then
        gameState.mouseX, gameState.mouseY = love.mouse.getPosition()
    end
    Theory:update(dt)

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

function mine.getTheoryElementForState(state)
    if state == UI_STATE.GAME then
        return Theory:getElementById("gameWindow")
    elseif state == UI_STATE.MENU then
        return Theory:getElementById("menuWindow")
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
    if direction == 1 then -- UP
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
    if not gameState.mapMode then
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

function love.mousepressed(x, y, button)
    Theory:mousepressed(x, y, button)

    if mine.isInGameState() then
        local viewX = math.floor(x / gameState.SCALE)
        local viewY = math.floor(y / gameState.SCALE)
        if not mine.isViewCoordWithinBoard(viewX, viewY) then
            return
        end

        local boardX, boardY = mine.viewToBoard(viewX, viewY)

        if button == 1 then
            Board:primaryAction(boardX, boardY)
        elseif button == 2 then
            Board:secondaryAction(boardX, boardY)
        end
    end
end

local KeyBindings = {
    { -- primary binding
        UP = "w";
        DOWN = "s";
        LEFT = "a";
        RIGHT = "d";
        KEYBOARD_RIGHT_CLICK = "k";
        KEYBOARD_LEFT_CLICK = "j";
        MOUSE_MODE = "m";
        MAP_MODE = "z";
    },
    { -- secondary binding
        UP = "up";
        DOWN = "down";
        LEFT = "left";
        RIGHT = "right";
    },
}

local KeyMap = {}
for i, binding in ipairs(KeyBindings) do
    KeyMap[i] = {}
    for bind, key in pairs(binding) do
        KeyMap[i][key] = bind
    end
end

function love.keypressed(key)
    local bind = KeyMap[1][key] or KeyMap[2][key]

    if not bind then return end

    if bind == "UP" then
        gameState.yAxisControl:keyDown(-1)
    elseif bind == "DOWN" then
        gameState.yAxisControl:keyDown(1)
    elseif bind == "LEFT" then
        gameState.xAxisControl:keyDown(-1)
    elseif bind == "RIGHT" then
        gameState.xAxisControl:keyDown(1)
    elseif bind == "KEYBOARD_RIGHT_CLICK" then
        if gameState.keyboardNavigation then
            love.mousepressed(gameState.mouseX, gameState.mouseY, 2)
        else
            gameState.keyboardNavigation = true
            gameState.mouseX = (gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH / 2) * gameState.SCALE
            gameState.mouseY = (gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT / 2) * gameState.SCALE
        end
    elseif bind == "KEYBOARD_LEFT_CLICK" then
        if gameState.keyboardNavigation then
            love.mousepressed(gameState.mouseX, gameState.mouseY, 1)
        end
    elseif bind == "MOUSE_MODE" then
        if gameState.keyboardNavigation then
            gameState.keyboardNavigation = false
        end
    elseif bind == "MAP_MODE" then
        gameState.mapMode = not gameState.mapMode
    end
end

function love.keyreleased(key)
    local bind = KeyMap[1][key] or KeyMap[2][key]
    if not bind then return end

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

function mine.printBoard()
    local previousCanvas = love.graphics.getCanvas()

    love.graphics.setCanvas{gameState.boardCanvas, stencil = true}
    local text = love.graphics.newText(font)

    local mouseBoardX, mouseBoardY = mine.mouseToBoardCoords()
    local doChecks = Config:getShowChecks()

    local xPositionAdjust = gameState.xAxisControl:getSmoothedPositionOffset()
    local yPositionAdjust = gameState.yAxisControl:getSmoothedPositionOffset()

    for y = gameState.VIEW_OFFSET_Y - 1, gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT + 1 do
        for x = gameState.VIEW_OFFSET_X - 1, gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH + 1 do
            local cellX, cellY = mine.viewToBoard(x, y)
            local cell = Board:rawGetCell(cellX + xPositionAdjust, cellY + yPositionAdjust)
            local isChecker = doChecks and (cellX + cellY) % 2 ~= 0
            local inHalo = Board:isNeighbor(cellX, cellY, mouseBoardX, mouseBoardY)

            mine.printCell(text, cell, x, y, isChecker, inHalo)
        end
    end

    love.graphics.stencil(function()
        love.graphics.rectangle('fill',
            gameState.VIEW_OFFSET_X * gameState.SCALE,
            gameState.VIEW_OFFSET_Y * gameState.SCALE,
            (gameState.VIEW_WIDTH + 1) * gameState.SCALE,
            (gameState.VIEW_HEIGHT + 1)* gameState.SCALE)
    end)

    love.graphics.setStencilTest("greater", 0)
    love.graphics.draw(text)
    love.graphics.setStencilTest()

    love.graphics.setCanvas(previousCanvas)
    love.graphics.draw(gameState.boardCanvas)
end

local mapCanvas = love.graphics.newCanvas()
function mine.printMapMode()
    local doChecks = Config:getShowChecks()
    local paletteExt = Config:getPaletteExt()
    local RESCALE = 4

    local xmin = 0
    local xmax = ((gameState.VIEW_WIDTH + 1) * gameState.SCALE / RESCALE) - 1

    local ymin = 0
    local ymax = ((gameState.VIEW_HEIGHT + 1) * gameState.SCALE / RESCALE) - 1

    local cellOffsetX = gameState.xAxisControl:getPosition()
        - (gameState.VIEW_WIDTH / 2) * (gameState.SCALE / RESCALE)
        + (gameState.VIEW_WIDTH / 2)

    local cellOffsetY = gameState.yAxisControl:getPosition()
        - (gameState.VIEW_HEIGHT / 2) * (gameState.SCALE / RESCALE)
        + (gameState.VIEW_HEIGHT / 2)

    local viewOffsetX = gameState.VIEW_OFFSET_X * gameState.SCALE
    local viewOffsetY = gameState.VIEW_OFFSET_Y * gameState.SCALE

    local previousCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(mapCanvas)

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
            elseif cell.value == VALUE.NONE then
                color = isChecker and paletteExt.bgdark or paletteExt.bglite
            else
                color = Config:getSymbolColor(cell.value)
            end
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", viewOffsetX + x * RESCALE, viewOffsetY + y * RESCALE, RESCALE, RESCALE)
        end
    end

    love.graphics.setColor(COLORS.white)
    love.graphics.setCanvas(previousCanvas)
    love.graphics.draw(mapCanvas)
end

function mine.printExampleNumbers()
    local text = love.graphics.newText(font)

    local row1 = { VALUE.ONE, VALUE.TWO, VALUE.THREE, VALUE.FOUR, VALUE.FIVE }
    local row2 = { VALUE.SIX, VALUE.SEVEN, VALUE.EIGHT, VALUE.FLAG, VALUE.MINE }
    local palette = Config:getPaletteBase()

    for i = 1, 5 do
        local x = 12 + 4 * (i - 1)
        mine.printToText(text, row1[i], Config:getSymbolColor(row1[i]), x, 14, palette.darkest)
        mine.printToText(text, row2[i], Config:getSymbolColor(row2[i]), x, 18, palette.darkest)
    end

    love.graphics.draw(text)
end

function mine.printDemoBoard()
    local viewOffsetX = 25
    local viewOffsetY = 26
    local viewWidth = 10
    local viewHeight = 10
    local previousCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(gameState.demoCanvas)
    local demoText = love.graphics.newText(font)

    local mouseBoardX, mouseBoardY = mine.mouseToBoardCoords(
        viewOffsetX, viewOffsetY,
        viewWidth, viewHeight,
        1, 0
    )
    local doChecks = Config:getShowChecks()
    for y = viewOffsetY, viewOffsetY + viewHeight do
        for x = viewOffsetX, viewOffsetX + viewHeight do
            local cellX, cellY = mine.viewToBoard(x, y, viewOffsetX, viewOffsetY, 1, 0)
            local cell = mine.rawGetDemoCell(cellX, cellY)
            local isChecker = doChecks and (cellX + cellY) % 2 ~= 0
            local isHalo = Board:isNeighbor(cellX, cellY, mouseBoardX, mouseBoardY)

            mine.printCell(demoText, cell, x, y, isChecker, isHalo)
        end
    end
    love.graphics.draw(demoText)
    love.graphics.setCanvas(previousCanvas)

    love.graphics.draw(gameState.demoCanvas)
end

function mine.rawGetDemoCell(x, y)
    if x == math.huge or y == math.huge then
        return nil
    elseif not gameState.Demo[y] or not gameState.Demo[y][x] then
        return nil
    end
    return gameState.Demo[y][x]
end

function mine.printCell(text, cell, x, y, isChecker, inHalo)
    local paletteExt = Config:getPaletteExt()
    local tileColor = isChecker
        and (inHalo and paletteExt.halodark or paletteExt.tiledark)
        or  (inHalo and paletteExt.halolite or paletteExt.tilelite)
    local backColor = isChecker
        and (inHalo and paletteExt.bghalolite or paletteExt.bglite)
        or  (inHalo and paletteExt.bghalodark or paletteExt.bgdark)

    if not cell or cell.state == STATE.UNSEEN or gameState.animatingList[cell] then
        mine.printToText(text, "█", tileColor, x, y)
    elseif cell.state == STATE.FLAGGED then
        mine.printToText(text, VALUE.FLAG, Config:getSymbolColor(VALUE.FLAG), x, y, tileColor)
    else
        mine.printToText(text, cell.value, Config:getSymbolColor(cell.value), x, y, backColor)
    end
end

function mine.printToText( text, symbol, foreColor, x, y, backColor)
    if not symbol or not foreColor then
        print("sym: " .. (symbol and symbol or "F") .. "\tfore: " .. (foreColor and "T" or "F"))
        debug.debug()
    end

    local xPositionNudge = gameState.xAxisControl:getSmoothedPositionNudge()
    local yPositionNudge = gameState.yAxisControl:getSmoothedPositionNudge()

    x = math.floor(gameState.SCALE * (x + xPositionNudge))
    y = math.floor(gameState.SCALE * (y + yPositionNudge))

	if backColor then
        text:add({ backColor, "█" }, x, y)
    end
    if symbol then
        text:add({ foreColor, symbol }, x, y)
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

    return  viewX >= viewOffsetX
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
function mine.viewToBoard( viewX, viewY,
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

function love.filedropped( file )
    Board:loadFromFile(file)
end

function love.quit()
    if not Board.isGameOver and Board.begun then
		local result = love.window.showMessageBox(
            "Quit",
            "Are you sure you want to quit?",
            {
                "Quit", "Save and Quit", "Cancel",
			    escapebutton = 3, enterbutton = 2,
			},
            "warning")

		if result == 3 then -- cancel
			return true
		elseif result == 2 then -- save and quit
			local filename = "unbounded.save"
			local i = 0
			local file = io.open( filename )
			while file do
				file:close()
				i = i + 1
				filename = "unbounded" .. i .. ".save"
				file = io.open( filename )
			end
            Board:saveToFile(filename)
			love.window.showMessageBox("Saved", 'game saved as "' .. filename .. '"' )
        end
    end
    Config:save()
    jprof.write("prof.mpack")
	return false
end