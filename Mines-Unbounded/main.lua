-- luacheck: std +love
local Theory = require("AsciiTheory")

local commands = {}
--local colors = {}
local gameState = {}
local mine = {}

-- State Constants
local STATE = {
    UNSEEN = 0;
    SEEN = 1;
    FLAGGED = 2;
}


local VALUE = {
    MINE  = "*", [-1]="*", ["*"]=-1;
    NONE  = " ", [0]=" ", [" "]=0;
    ONE   = "1", [1]="1", ["1"]=1;
    TWO   = "2", [2]="2", ["2"]=2;
    THREE = "3", [3]="3", ["3"]=3;
    FOUR  = "4", [4]="4", ["4"]=4;
    FIVE  = "5", [5]="5", ["5"]=5;
    SIX   = "6", [6]="6", ["6"]=6;
    SEVEN = "7", [7]="7", ["7"]=7;
    EIGHT = "8", [8]="8", ["8"]=8;
}

--temp colors from previous version
local colors = {
	blue = { 0.0, 0.5, 1.0 };
	green = { 0.0, 1.0, 0.0 };
	yellow = { 1.0, 1.0, 0.0 };
	orange = { 1.0, 0.5, 0.0 };
	red = { 1.0, 0.0, 0.0 };
	magenta = { 1.0, 0.0, 0.5 };
	pink = { 1.0, 0.0, 1.0 };
	purple = { 0.5, 0.0, 1.0 };
	white = { 1.0, 1.0, 1.0 };
	black = { 0.0, 0.0, 0.0 };
	bgdark = {   0,  32/255,  64/255};
	bglite = {   0,  41/255, 83/255};
	tiledark = {   0,  70/255, 140/255};
	tilelite = {   0,  89/255, 178/255};
	halodark = { 163/255, 0, 217/255};
	halolite = { 191/255, 0, 255/255};
}
-- mine indicator colors
colors[-1]= colors.white
colors[0] = colors.white
colors[1] = colors.blue
colors[2] = colors.green
colors[3] = colors.yellow
colors[4] = colors.orange
colors[5] = colors.red
colors[6] = colors.magenta
colors[7] = colors.pink
colors[8] = colors.purple

function love.load()
    local font = love.graphics.newImageFont(
		"cp437_16x16.png",
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
    Theory:Init()
    Theory.commands = commands

    local canvas = Theory:canvas("UnboundedFrame.xp",0,0)
    Theory:buttonStyle("new","New_Button_Style.xp")

    Theory:parse({
        type = "base";
        {   type = "window";
            id = "win";
            layer = canvas.layers[1];
            {   type = "textField";
                id = "scoreLabel";
                text = "0000000";
                bg = { 48/255, 0/255, 64/255 };
                dim = Theory:dim(19,2,9,2);
                verticalAlign = "center";
                horizontalAlign = "center";
            },
            {   type = "button";
                id = "newButton";
                command = "newGame";
                style = Theory.styles.new;
                dim = Theory:dim(3,43,9,5);
            },
            {   type = "button";
                id = "saveButton";
                command = "saveGame";
                style = Theory.styles.new;
                dim = Theory:dim(35,43,9,5)
            }
        }
    })
    gameState = {
        --view constant
        SCALE = 16;
        VIEW_OFFSET_X = 7;
        VIEW_OFFSET_Y = 7;
        VIEW_WIDTH = 32;
        VIEW_HEIGHT = 32;
        --view variables
        boardOffsetX = 0;
        boardOffsetY = 0;
        checkShift = false;

        --game constants
        MINE_ESCALATION_RATE = 0.9999;
        --game variables
        mineWeight = 0.9999;
        cleared = 0;
        flagged = 0;
        begun = false;
        menu = false;
        isGameOver = true;
        doCheckers = true;
        Cells = {};

        --Interface variables
        mouseX = 0;
        mouseY = 0;
        motionX = 0;
        motionY = 0;
        time = 0;
    }
end

function commands.newGame()
    gameState.begun = false
    gameState.isGameOver = false
    gameState.flagged = 0
    gameState.cleared = 0
    Theory.idDict["scoreLabel"]:setText("0000000")
    gameState.Cells = {}
    gameState.mineWeight = gameState.MINE_ESCALATION_RATE
end

function mine.endGame()
    gameState.isGameOver = true
    
end

function love.update(dt)
    gameState.mouseX, gameState.mouseY = love.mouse.getPosition()
    Theory:update(dt)
    gameState.time = gameState.time + dt
    if gameState.time > 0.1 then
        gameState.time = gameState.time - 0.1

        gameState.boardOffsetX = gameState.boardOffsetX + gameState.motionX
        gameState.boardOffsetY = gameState.boardOffsetY + gameState.motionY
        if not math.abs(gameState.motionX) == math.abs(gameState.motionY) then
            gameState.checkShift = not gameState.checkShift
        end
    end
end

function love.draw()
    Theory:draw()
    if not gameState.menu then
        love.graphics.setColor(colors.white)
        mine.printBoard()
    end
end

function love.mousepressed(x, y, button)
    Theory:mousepressed(x, y, button)

    local viewX, viewY = math.floor( x / gameState.SCALE ), math.floor( y / gameState.SCALE )
    local boardX, boardY = mine.viewToBoard(viewX, viewY)
    
    if boardX == math.huge or boardY == math.huge then
        return
    end

    if button == 1 then
        if not gameState.begun then
            local newEmptyCell = function (lx,ly)
                if not gameState.Cells[ly] then
                    gameState.Cells[ly] = {}
                end
                gameState.Cells[ly][lx] = mine.makeCell(true)
            end
            newEmptyCell(boardX, boardY)
            mine.doNeighbor( boardX, boardY, newEmptyCell)
            gameState.begun = true
        end
        mine.revealCell( boardX, boardY )
    elseif button == 2 then
        local cell = mine.getCell(boardX, boardY)
        if cell.state == STATE.UNSEEN then
            cell.state = STATE.FLAGGED
        elseif cell.state == STATE.FLAGGED then
            cell.state = STATE.UNSEEN
        elseif cell.state == STATE.SEEN and VALUE[cell.value] > 0 then
            mine.doNeighbor( boardX, boardY, mine.revealCell)
        end
    end
end

function love.keypressed(key)
    if key == "w" or key == "up" then
        gameState.motionY = gameState.motionY - 1
    elseif key == "s" or key == "down" then
        gameState.motionY = gameState.motionY + 1
    elseif key == "a" or key == "left" then
        gameState.motionX = gameState.motionX - 1
    elseif key == "d" or key == "right" then
        gameState.motionX = gameState.motionX + 1
    elseif key == "rctrl" then
        debug.debug()
    end
end

function love.keyreleased(key)
    if key == "w" or key == "up" then
        gameState.motionY = gameState.motionY + 1
    elseif key == "s" or key == "down" then
        gameState.motionY = gameState.motionY - 1
    elseif key == "a" or key == "left" then
        gameState.motionX = gameState.motionX + 1
    elseif key == "d" or key == "right" then
        gameState.motionX = gameState.motionX - 1
    end
end

function mine.getCell( x, y )
    if not gameState.Cells[y] then
        gameState.Cells[y] = {}
    end
    if not gameState.Cells[y][x] then
        gameState.Cells[y][x] = mine.makeCell()
    end
    return gameState.Cells[y][x]
end

function mine.rawGetCell( x, y )
    if x == math.huge or y == math.huge then
        return nil
    elseif not gameState.Cells[y] or not gameState.Cells[y][x] then
        return nil
    end
    return gameState.Cells[y][x]
end

function mine.doNeighbor( x, y, callback )
    callback(x - 1, y - 1)
    callback(x - 1, y    )
    callback(x - 1, y + 1)
    callback(x,     y - 1)
    callback(x,     y + 1)
    callback(x + 1, y - 1)
    callback(x + 1, y    )
    callback(x + 1, y + 1)
end

function mine.isNeighbor( x1, y1, x2, y2 )
    return not (math.abs(x1-x2) > 1 or math.abs(y1-y2) > 1)
end

function mine.makeCell( forceClear )
    local cell = {}
    cell.state = STATE.UNSEEN
    if not forceClear and love.math.random() < 0.2 + (0.6*(1-gameState.mineWeight)) then
        cell.value = VALUE.MINE
    else
        cell.value = VALUE.NONE
    end
    gameState.mineWeight = gameState.mineWeight * gameState.MINE_ESCALATION_RATE
    return cell
end

function mine.calculateValue( x, y )
    local cell = mine.getCell(x,y)
    cell.value = 0
    local operation = function ( lx, ly )
        local neighborCell = mine.getCell(lx,ly)
        if neighborCell.value == VALUE.MINE then
            cell.value = cell.value + 1
        end
    end
    mine.doNeighbor( x, y, operation )
    cell.value = VALUE[cell.value]
end

function mine.revealCell( x, y )
    local cell = mine.getCell( x, y )
    if cell.state ~= STATE.UNSEEN then
        return
    end

    if cell.value == VALUE.MINE then
        cell.state = STATE.SEEN
        mine.endGame()
        gameState.isGameOver = true
    else
        mine.calculateValue(x,y)
        if cell.value == VALUE.NONE then
            mine.revealRegion( x, y )
        else
            cell.state = STATE.SEEN
            gameState.cleared = gameState.cleared+1
        end
        local label = Theory.idDict["scoreLabel"]
        local scoreStr = tostring(gameState.cleared)
        local pad = 7 - string.len(scoreStr)
        scoreStr = string.rep("0",pad) .. scoreStr
        label:setText(scoreStr)
    end
end

function mine.revealRegion( x, y )
    local queuePointer = 1
    local queue = { {x,y} }
    local insertToQueue = function (lx,ly) queue[#queue+1]={lx,ly} end
    while (queuePointer <= #queue) do
        local position = queue[queuePointer]
        local cell = mine.getCell(position[1],position[2])
        if cell.state == STATE.UNSEEN then
            cell.state = STATE.SEEN
            mine.calculateValue(position[1],position[2])
            gameState.cleared = gameState.cleared+1
            if cell.value == VALUE.NONE then
                mine.doNeighbor( position[1], position[2], insertToQueue)
            end
        end
        queuePointer = queuePointer + 1
    end
end

function mine.printBoard()
    local screenX, screenY = math.floor(gameState.mouseX/gameState.SCALE), math.floor(gameState.mouseY/gameState.SCALE)
    local boardX, boardY = mine.viewToBoard( screenX, screenY )
    for y = gameState.VIEW_OFFSET_Y, gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT do
        for x = gameState.VIEW_OFFSET_X, gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH do
            local check = (y+x+(gameState.checkShift and 1 or 0)) % 2 ~= 0
            local cellX, cellY = mine.viewToBoard( x, y )
            local cell = mine.rawGetCell(  cellX, cellY )
            local color = ( gameState.doCheckers and check )
                and ( mine.isNeighbor( cellX, cellY, boardX, boardY) and colors.halodark or colors.tiledark )
                or  ( mine.isNeighbor( cellX, cellY, boardX, boardY) and colors.halolite or colors.tilelite )
            if not cell or cell.state == STATE.UNSEEN then
                mine.printToBoard( "█", color, x, y )
            elseif cell.state == STATE.FLAGGED then
                mine.printToBoard( "!", colors.red, x, y, color )
            else

                mine.printToBoard(
                    cell.value,
                    colors[VALUE[cell.value]],
                    x, y,
                    (gameState.doCheckers and check)
                        and colors.bglite
                        or  colors.bgdark
                )
            end
        end
    end
end

function mine.printToBoard( symbol, foreColor, x, y, backColor)
    if not symbol or not foreColor then
        print("sym: " .. (symbol and symbol or "F") .. "\tfore: " .. (foreColor and "T" or "F") )
        debug.debug()
    end
    x = gameState.SCALE * x
    y = gameState.SCALE * y
	if backColor then
		love.graphics.print( { backColor, "█" }, x, y )
    end
    if symbol then
        love.graphics.print( { foreColor, symbol }, x, y )
    else
        print("bad cell at [" .. x .. ", " .. y .. "]" )
        love.graphics.print( { colors.red, "█" }, x, y )
    end
end

function mine.viewToBoard( viewX, viewY )
    local boardX
    if viewX >= gameState.VIEW_OFFSET_X and viewX <= gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH then
        boardX = viewX - gameState.VIEW_OFFSET_X + gameState.boardOffsetX
    else
        boardX = math.huge
    end
    local boardY
    if viewY >= gameState.VIEW_OFFSET_Y and viewY <= gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT then
        boardY = viewY - gameState.VIEW_OFFSET_Y + gameState.boardOffsetY
    else
        boardY = math.huge
    end
    return boardX, boardY
end
