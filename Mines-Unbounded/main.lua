-- luacheck: std +love

--evil workaround
-- luacheck: ignore ColorSets colorIndex
ColorSets = {};
colorIndex = 1;
local loveSetColor = love.graphics.setColor
function love.graphics.setColor(rgba, ...) -- luacheck: ignore
    if type(rgba) == "table" then
        loveSetColor(rgba)
    elseif type(rgba) == "string" then
        loveSetColor(ColorSets[colorIndex][rgba])
    else
        loveSetColor(rgba, ...)
    end
end

local Theory = require("AsciiTheory")

local commands = {}
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

colors[1] = colors.white
colors[2] = colors.blue
colors[3] = colors.green
colors[4] = colors.yellow
colors[5] = colors.orange
colors[6] = colors.red
colors[7] = colors.magenta
colors[8] = colors.pink
colors[9] = colors.purple

local colorSettings = {
    [-2] = 6; [-1] = 1; [ 0] = 1;
    [ 1] = 2; [ 2] = 3; [ 3] = 4;
    [ 4] = 5; [ 5] = 6; [ 6] = 7;
    [ 7] = 8; [ 8] = 9;
}

ColorSets = {
    { --anxiety
        darkest = {  34/255,  19/255,  48/255 };
        dark    = {  41/255,  52/255,  82/255 };
        normal  = {  50/255,  84/255,  94/255 };
        light   = {  68/255, 122/255,  90/255 };
        lightest= {  84/255, 141/255,  88/255 };
    },
    { --sodas and skateboards
        darkest = { 131/255,  29/255, 128/255 };
        dark    = { 109/255,  73/255, 168/255 };
        normal  = {  86/255, 125/255, 195/255 };
        light   = {  90/255, 182/255, 224/255 };
        lightest= { 106/255, 227/255, 244/255 };
    },
    { --guidance
        darkest = { 122/255, 105/255,  71/255 };
        dark    = { 249/255, 234/255, 141/255 };
        normal  = { 211/255, 216/255, 124/255 };
        light   = { 174/255, 187/255, 105/255 };
        lightest= { 140/255, 148/255,  88/255 };
    },
    { --constant rambling
        darkest = { 237/255, 143/255, 139/255 };
        dark    = { 243/255, 197/255, 164/255 };
        normal  = { 251/255, 232/255, 198/255 };
        light   = { 173/255, 214/255, 250/255 };
        lightest= { 144/255, 201/255, 257/255 };
    },
    { --the sweetest chill
        darkest = {  52/255,  52/255,  50/255 };
        dark    = { 100/255,  91/255, 158/255 };
        normal  = { 142/255, 132/255, 195/255 };
        light   = { 197/255, 174/255, 228/255 };
        lightest= { 228/255, 233/255, 230/255 };
    },
    { --saltwater tears
        darkest = "#dbf4bf";
        dark    = "#b7e4a1";
        normal  = "#60a581";
        light   = "#547b7d";
        lightest= "#446c6c";
    },
    { --damned if i do
        darkest = "#da8ba0";
        dark    = "#f0b6c1";
        normal  = "#fbeded";
        light   = "#e9e9e9";
        lightest= "#ccd2ce";
    },
    { --without a heart
        darkest = "#fae4e7";
        dark    = "#dfb8c1";
        normal  = "#8c98c1";
        light   = "#97a8e8";
        lightest= "#c8d1f8";
    },
    { --high fashion
        darkest = "#f6e06f";
        dark    = "#f3bf7c";
        normal  = "#e5968c";
        light   = "#bd72a1";
        lightest= "#946aa9";
    },
    { --im not alone yet
        darkest = "#9999a4";
        dark    = "#b1b4b9";
        normal  = "#d4d5ce";
        light   = "#fcfcfc";
        lightest= "#f3dfc4";
    },
    { --castle in the sky
        darkest = "#6b3238";
        dark    = "#d57d68";
        normal  = "#f2c99a";
        light   = "#f5e8ad";
        lightest= "#9bdab9";
    },
    { --pumpkaboo
        darkest = "#dfecf7";
        dark    = "#e0bc6f";
        normal  = "#b88246";
        light   = "#906146";
        lightest= "#532d20";
    },
    { --cherry soda
        darkest = "#221206";
        dark    = "#39160d";
        normal  = "#781b24";
        light   = "#932e44";
        lightest= "#fcf3e4";
    },
    { --i kinda like you back
        darkest = "#96f873";
        dark    = "#cdfa73";
        normal  = "#fcf475";
        light   = "#f2be6a";
        lightest= "#ed9660";
    },
    { --ominiferous
        darkest = "#e9f1b6";
        dark    = "#c1cb80";
        normal  = "#bd9d7c";
        light   = "#bb6582";
        lightest= "#ab3b85";
    },
    { --blooming
        darkest = "#f9fdda";
        dark    = "#d4f3b8";
        normal  = "#bcdead";
        light   = "#eea6b6";
        lightest= "#ee8d9e";
    },
    { --this is my swamp
        darkest = "#526c67";
        dark    = "#507d59";
        normal  = "#6c9460";
        light   = "#95c26f";
        lightest= "#cde09d";
    },
    { --what i gain i lose
        darkest = "#a39db7";
        dark    = "#e1d6e0";
        normal  = "#f4f1f8";
        light   = "#f9e3cd";
        lightest= "#f5bfb5";
    },
    { --cyberbullies
        darkest = "#acf8dc";
        dark    = "#84bfe0";
        normal  = "#5c82e6";
        light   = "#3240ed";
        lightest= "#0b04f0";
    },
    { --cool sunsets
        darkest = "#d5eea7";
        dark    = "#b5dbad";
        normal  = "#8bbc9e";
        light   = "#4f8587";
        lightest= "#22466a";
    },
    { --subtle melancholy
        darkest = "#7b6492";
        dark    = "#8f80a0";
        normal  = "#a8a7af";
        light   = "#b6c6be";
        lightest= "#c7ead2";
    },
    { --conversation hearts
        darkest = "#e43464";
        dark    = "#c95177";
        normal  = "#ae858d";
        light   = "#9cc0a1";
        lightest= "#95f8bb";
    },
    { --tuesdays
        darkest = "#a395f6";
        dark    = "#beb5f7";
        normal  = "#cfc7f9";
        light   = "#f9ebab";
        lightest= "#f9e278";
    },
}

for _, set in pairs(ColorSets) do
    for color, str in pairs(set) do
        if type(str) == "string" then
            set[color] = {
                tonumber(str:sub(2,3),16)/255;
                tonumber(str:sub(4,5),16)/255;
                tonumber(str:sub(6,7),16)/255;
            }
        end
    end
end

local BaseColorSet = {
    darkest = {   0/255,   0/255,  64/255 };
    dark    = {   0/255,   0/255, 178/255 };
    normal  = {   0/255,   0/255, 255/255 };
    light   = {  51/255,  51/255, 255/255 };
    lightest= { 102/255, 102/255, 255/255 };
}

local compareColor = function( color1, color2)
    if type(color1) ~= "table" or type(color2) ~= "table" then
        return false
    end
    return math.floor(color1[1]*255) == math.floor(color2[1]*255)
       and math.floor(color1[2]*255) == math.floor(color2[2]*255)
       and math.floor(color1[3]*255) == math.floor(color2[3]*255)
end

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

    mine.loadConfig()
    local paletteStr = tostring(colorIndex)
    local pad = 3 - string.len(paletteStr)
    paletteStr = string.rep("0",pad) .. paletteStr

    local canvas = Theory:canvas("Assets/UnboundedFrame.xp",0,0)
    Theory:buttonStyle("new","Assets/New_Button_Style.xp")
    Theory:buttonStyle("menu","Assets/Menu_Button_Style.xp")
    Theory:buttonStyle("back","Assets/Back_Button_Style.xp")
    Theory:buttonStyle("save","Assets/Save_Button_Style.xp")
    Theory:buttonStyle("reset","Assets/Reset_Button_Style.xp")
    Theory:buttonStyle("check","Assets/Check_Button_Style.xp")
    Theory:buttonStyle("up", "Assets/Up_Arrow_Style.xp")
    Theory:buttonStyle("down", "Assets/Down_Arrow_Style.xp")
    Theory:buttonStyle("left", "Assets/Left_Arrow_Style.xp")
    Theory:buttonStyle("right", "Assets/Right_Arrow_Style.xp")

    --local style = Theory.styles.new
    for _, style in pairs(Theory.styles) do
        for state in pairs(style.prototypes) do
            if style.prototypes[state].layer then
                for i = 1, style.prototypes[state].layer.height do
                    for j = 1, style.prototypes[state].layer.width do
                        local cell = style.prototypes[state].layer:getCell(j,i)
                        if cell then
                            for hue in pairs(BaseColorSet) do
                                if compareColor(cell.fg, BaseColorSet[hue]) then
                                    cell.fg = hue
                                end
                                if compareColor(cell.bg, BaseColorSet[hue]) then
                                    cell.bg = hue
                                end
                            end
                            style.prototypes[state].layer:setCell( j, i, cell)
                        end
                    end
                end
            end
        end
    end

    Theory:parse({
        type = "base";
        {   type = "window";
            id = "win";
            layer = canvas.layers[1];
            {   type = "textField";
                id = "scoreLabel";
                text = "0000000";
                fg = "lightest";
                bg = "darkest";
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
                id = "menuButton";
                command = "openMenu";
                style = Theory.styles.menu;
                dim = Theory:dim(35,43,9,5)
            },

            {   type = "button";
                command = "up";
                param = 1;
                style = Theory.styles.up;
                dim = Theory:dim(59,13,1,1);
            },
            {   type = "button";
                command = "down";
                param = 1;
                style = Theory.styles.down;
                dim = Theory:dim(59,15,1,1);
            },
            {   type = "button";
                command = "up";
                param = 2;
                style = Theory.styles.up;
                dim = Theory:dim(63,13,1,1);
            },
            {   type = "button";
                command = "down";
                param = 2;
                style = Theory.styles.down;
                dim = Theory:dim(63,15,1,1);
            },
            {   type = "button";
                command = "up";
                param = 3;
                style = Theory.styles.up;
                dim = Theory:dim(67,13,1,1);
            },
            {   type = "button";
                command = "down";
                param = 3;
                style = Theory.styles.down;
                dim = Theory:dim(67,15,1,1);
            },
            {   type = "button";
                command = "up";
                param = 4;
                style = Theory.styles.up;
                dim = Theory:dim(71,13,1,1);
            },
            {   type = "button";
                command = "down";
                param = 4;
                style = Theory.styles.down;
                dim = Theory:dim(71,15,1,1);
            },
            {   type = "button";
                command = "up";
                param = 5;
                style = Theory.styles.up;
                dim = Theory:dim(75,13,1,1);
            },
            {   type = "button";
                command = "down";
                param = 5;
                style = Theory.styles.down;
                dim = Theory:dim(75,15,1,1);
            },
            {   type = "button";
                command = "toggleCheck";
                style = Theory.styles.check;
                dim = Theory:dim(78,13,5,3);
            },
            {   type = "button";
                command = "up";
                param = 6;
                style = Theory.styles.up;
                dim = Theory:dim(59,17,1,1);
            },
            {   type = "button";
                command = "down";
                param = 6;
                style = Theory.styles.down;
                dim = Theory:dim(59,19,1,1);
            },
            {   type = "button";
                command = "up";
                param = 7;
                style = Theory.styles.up;
                dim = Theory:dim(63,17,1,1);
            },
            {   type = "button";
                command = "down";
                param = 7;
                style = Theory.styles.down;
                dim = Theory:dim(63,19,1,1);
            },
            {   type = "button";
                command = "up";
                param = 8;
                style = Theory.styles.up;
                dim = Theory:dim(67,17,1,1);
            },
            {   type = "button";
                command = "down";
                param = 8;
                style = Theory.styles.down;
                dim = Theory:dim(67,19,1,1);
            },
            {   type = "button";
                command = "up";
                param = -2;
                style = Theory.styles.up;
                dim = Theory:dim(71,17,1,1);
            },
            {   type = "button";
                command = "down";
                param = -2;
                style = Theory.styles.down;
                dim = Theory:dim(71,19,1,1);
            },
            {   type = "button";
                command = "up";
                param = -1;
                style = Theory.styles.up;
                dim = Theory:dim(75,17,1,1);
            },
            {   type = "button";
                command = "down";
                param = -1;
                style = Theory.styles.down;
                dim = Theory:dim(75,19,1,1);
            },
            {   type = "button";
                command = "setToDefault";
                style = Theory.styles.reset;
                dim = Theory:dim(78,17,5,3);
            },
            {   type = "button";
                command = "leftPalette";
                style = Theory.styles.left;
                dim = Theory:dim(59,29,1,1);
            },
            {   type = "textField";
                id = "paletteReadout";
                text = paletteStr;
                fg = "lightest";
                bg = "darkest";
                dim = Theory:dim(60,29,3,1);
                verticalAlign = "center";
                horizontalAlign = "center";
            },
            {   type = "button";
                command = "rightPalette";
                style = Theory.styles.right;
                dim = Theory:dim(63,29,1,1);
            },
            {   type = "button";
                id = "saveButton";
                command = "saveGame";
                style = Theory.styles.save;
                dim = Theory:dim(50,43,9,5);
            },
            {   type = "button";
                id = "backButton";
                command = "closeMenu";
                style = Theory.styles.back;
                dim = Theory:dim(82,43,9,5)
            }
        }
    })

    local window = Theory.idDict.win
    for i = 1, window.layer.height do
        for j = 1, window.layer.width do
            local cell = window.layer:getCell(j,i)
            if cell then
                for hue in pairs(BaseColorSet) do
                    if compareColor(cell.fg, BaseColorSet[hue]) then
                        cell.fg = hue
                    end
                    if compareColor(cell.bg, BaseColorSet[hue]) then
                        cell.bg = hue
                    end
                end
            end
            window.layer:setCell( j, i, cell)
        end
    end

    love.graphics.setBackgroundColor(ColorSets[colorIndex].darkest)
    gameState = {
        --view constant
        SCALE = 16;
        VIEW_OFFSET_X = 7;
        VIEW_OFFSET_Y = 7;
        VIEW_WIDTH = 32;
        VIEW_HEIGHT = 32;
        MENU_OFFSET = 47;
        --view variables
        boardOffsetX = 0;
        boardOffsetY = 0;
        checkShift = false;
        menuAnimation = 0;
        screenSlide = 0;
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
        demoPainted = false;
        demoCanvas = love.graphics.newCanvas();

        --game constants
        MINE_ESCALATION_RATE = 0.9999;
        --game variables
        mineWeight = 0.9999;
        cleared = 0;
        begun = false;
        menu = false;
        isGameOver = false;
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
    gameState.cleared = 0
    Theory.idDict.scoreLabel:setText("0000000")
    gameState.Cells = {}
    gameState.mineWeight = gameState.MINE_ESCALATION_RATE
end

function commands.openMenu()
    gameState.menu = true
end

function commands.closeMenu()
    gameState.menu = false
end

function commands.up(param)
    if param then
        local setting = colorSettings[param] + 1
        if setting > 9 then
            setting = 1
        end
        colorSettings[param] = setting
    end
end

function commands.down(param)
    if param then
        local setting = colorSettings[param] - 1
        if setting < 1 then
            setting = 9
        end
        colorSettings[param] = setting
    end
end

function commands.toggleCheck()
    gameState.doCheckers = not gameState.doCheckers
end

function commands.setToDefault()
    colorSettings = {
        [-2] = 6; [-1] = 1; [ 0] = 1;
        [ 1] = 2; [ 2] = 3; [ 3] = 4;
        [ 4] = 5; [ 5] = 6; [ 6] = 7;
        [ 7] = 8; [ 8] = 9;
    }
end

function commands.leftPalette()
    colorIndex = colorIndex - 1
    if colorIndex < 1 then
        colorIndex = #ColorSets
    end
    local label = Theory.idDict.paletteReadout
    local paletteStr = tostring(colorIndex)
    local pad = 3 - string.len(paletteStr)
    paletteStr = string.rep("0",pad) .. paletteStr
    label:setText(paletteStr)
    Theory:forceRepaintAll()
end
function commands.rightPalette()
    colorIndex = colorIndex + 1
    if colorIndex > #ColorSets then
        colorIndex = 1
    end
    local label = Theory.idDict.paletteReadout
    local paletteStr = tostring(colorIndex)
    local pad = 3 - string.len(paletteStr)
    paletteStr = string.rep("0",pad) .. paletteStr
    label:setText(paletteStr)
    Theory:forceRepaintAll()
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

        if not gameState.menu then
            gameState.boardOffsetX = gameState.boardOffsetX + gameState.motionX
            gameState.boardOffsetY = gameState.boardOffsetY + gameState.motionY
            if not math.abs(gameState.motionX) == math.abs(gameState.motionY) then
                gameState.checkShift = not gameState.checkShift
            end
        end
    end

    if not gameState.menu and gameState.menuAnimation ~= 0 then
        local progress = gameState.menuAnimation
        local slide = gameState.screenSlide
        if progress > 0 then
            progress = progress - dt
        else
            progress = 0
        end
        slide = easeInOutExp(progress) * -gameState.MENU_OFFSET
        gameState.menuAnimation = progress
        gameState.screenSlide = slide
        Theory.offsetX = slide
    elseif gameState.menu and gameState.menuAnimation ~= 1 then
        local progress = gameState.menuAnimation
        local slide = gameState.screenSlide
        if progress < 1 then
            progress = progress + dt
        else
            progress = 1
        end
        slide = easeInOutExp(progress) * -gameState.MENU_OFFSET
        gameState.menuAnimation = progress
        gameState.screenSlide = slide
        Theory.offsetX = slide
    end

end

function easeInOutExp(x)
    return
        x <= 0 and 0 or
        x >= 1 and 1 or
        x <0.5 and math.pow(2,20*x - 10)/2 or
        (2 - math.pow(2,-20*x + 10))/2
end

function love.draw()
    Theory:draw()

    love.graphics.setColor(colors.white)
    mine.printBoard()

    mine.printToBoard("1",colors[colorSettings[1]],59 + gameState.screenSlide,14)
    mine.printToBoard("2",colors[colorSettings[2]],63 + gameState.screenSlide,14)
    mine.printToBoard("3",colors[colorSettings[3]],67 + gameState.screenSlide,14)
    mine.printToBoard("4",colors[colorSettings[4]],71 + gameState.screenSlide,14)
    mine.printToBoard("5",colors[colorSettings[5]],75 + gameState.screenSlide,14)
    mine.printToBoard("6",colors[colorSettings[6]],59 + gameState.screenSlide,18)
    mine.printToBoard("7",colors[colorSettings[7]],63 + gameState.screenSlide,18)
    mine.printToBoard("8",colors[colorSettings[8]],67 + gameState.screenSlide,18)
    mine.printToBoard("!",colors[colorSettings[-2]],71 + gameState.screenSlide,18)
    mine.printToBoard("*",colors[colorSettings[-1]],75 + gameState.screenSlide,18)
    mine.printDemoBoard()

    --[[
    local x,y = love.mouse.getPosition()
    x = math.floor( x / 16 )
    y = math.floor( y / 16 )
    love.graphics.print(x..", "..y,0,0)
    --]]
end

function love.mousepressed(x, y, button)
    Theory:mousepressed(x, y, button)

    if not gameState.menu and not gameState.isGameOver then
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

function mine.doNeighbor( x, y, callback, ... )
    callback(x - 1, y - 1, ...)
    callback(x - 1, y    , ...)
    callback(x - 1, y + 1, ...)
    callback(x,     y - 1, ...)
    callback(x,     y + 1, ...)
    callback(x + 1, y - 1, ...)
    callback(x + 1, y    , ...)
    callback(x + 1, y + 1, ...)
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
    cell.anim = 0
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
        local label = Theory.idDict.scoreLabel
        local scoreStr = tostring(gameState.cleared)
        local pad = 7 - string.len(scoreStr)
        scoreStr = string.rep("0",pad) .. scoreStr
        label:setText(scoreStr)
    end
end

function mine.revealRegion( x, y )
    local queuePointer = 1
    local queue = { {x,y,0} }
    local insertToQueue = function (lx,ly,a) queue[#queue+1]={lx,ly,a} end
    while (queuePointer <= #queue) do
        local position = queue[queuePointer]
        local cell = mine.getCell(position[1],position[2])
        if cell.state == STATE.UNSEEN then
            cell.state = STATE.SEEN
            cell.anim = position[3]
            mine.calculateValue(position[1],position[2])
            gameState.cleared = gameState.cleared+1
            if cell.value == VALUE.NONE then
                mine.doNeighbor( position[1], position[2], insertToQueue, position[3]+5)
            end
        end
        queuePointer = queuePointer + 1
    end
end

function mine.printBoard()

    if gameState.menuAnimation == 0 then
        love.graphics.setCanvas(gameState.boardCanvas)
        local screenX, screenY = math.floor(gameState.mouseX/gameState.SCALE), math.floor(gameState.mouseY/gameState.SCALE)
        local boardX, boardY = mine.viewToBoard( screenX, screenY )
        for y = gameState.VIEW_OFFSET_Y, gameState.VIEW_OFFSET_Y + gameState.VIEW_HEIGHT do
            for x = gameState.VIEW_OFFSET_X, gameState.VIEW_OFFSET_X + gameState.VIEW_WIDTH do
                local cellX, cellY = mine.viewToBoard( x, y )
                local cell = mine.rawGetCell(  cellX, cellY )
                local check = (y+x+(gameState.checkShift and 1 or 0)) % 2 ~= 0
                local color = ( gameState.doCheckers and check )
                    and ( mine.isNeighbor( cellX, cellY, boardX, boardY) and colors.halodark or colors.tiledark )
                    or  ( mine.isNeighbor( cellX, cellY, boardX, boardY) and colors.halolite or colors.tilelite )
                if not cell or cell.state == STATE.UNSEEN then
                    mine.printToBoard( "█", color, x, y )
                elseif cell.anim > 0 then
                    cell.anim = cell.anim - 1
                    mine.printToBoard( "█", color, x, y )
                elseif cell.state == STATE.FLAGGED then
                    mine.printToBoard( "!", colors[colorSettings[-2]], x, y, color )
                else
                    mine.printToBoard(
                        cell.value,
                        colors[colorSettings[VALUE[cell.value]]],
                        x, y,
                        (gameState.doCheckers and check)
                            and colors.bglite
                            or  colors.bgdark
                    )
                end
            end
        end
        love.graphics.setCanvas()
    end
    love.graphics.draw(gameState.boardCanvas,gameState.screenSlide*gameState.SCALE)
end

function mine.printDemoBoard()
    if gameState.menuAnimation == 1 or not gameState.demoPainted then
        gameState.demoPainted = true
        local viewOffsetX = 25
        local viewOffsetY = 26
        local viewWidth = 10
        local viewHeight = 10
        love.graphics.setCanvas(gameState.demoCanvas)
        local screenX, screenY = math.floor(gameState.mouseX/gameState.SCALE), math.floor(gameState.mouseY/gameState.SCALE)
        local boardX, boardY = mine.viewToBoard( screenX, screenY, viewOffsetX, viewOffsetY, viewWidth, viewHeight,1,0)
        for y = viewOffsetY, viewOffsetY + viewHeight do
            for x = viewOffsetX, viewOffsetX + viewHeight do
                local cellX, cellY = mine.viewToBoard( x, y, viewOffsetX, viewOffsetY, viewWidth, viewHeight,1,0)
                local cell = mine.rawGetDemoCell(  cellX, cellY )
                local check = (y+x+(gameState.checkShift and 1 or 0)) % 2 ~= 0
                local color = ( gameState.doCheckers and check )
                    and ( mine.isNeighbor( cellX, cellY, boardX, boardY) and colors.halodark or colors.tiledark )
                    or  ( mine.isNeighbor( cellX, cellY, boardX, boardY) and colors.halolite or colors.tilelite )
                if not cell or cell.state == STATE.UNSEEN then
                    mine.printToBoard( "█", color, x, y )
                elseif cell.state == STATE.FLAGGED then
                    mine.printToBoard( "!", colors[colorSettings[-2]], x, y, color )
                else
                    mine.printToBoard(
                        cell.value,
                        colors[colorSettings[VALUE[cell.value]]],
                        x, y,
                        (gameState.doCheckers and check)
                            and colors.bglite
                            or  colors.bgdark
                    )
                end
            end
        end
        love.graphics.setCanvas()
    end
    love.graphics.draw(gameState.demoCanvas, (gameState.MENU_OFFSET + gameState.screenSlide) * gameState.SCALE)
end

function mine.rawGetDemoCell( x, y )
    if x == math.huge or y == math.huge then
        return nil
    elseif not gameState.Demo[y] or not gameState.Demo[y][x] then
        return nil
    end
    return gameState.Demo[y][x]
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

function mine.viewToBoard( viewX, viewY, viewOffsetX, viewOffsetY, viewWidth, viewHeight, boardOffsetX, boardOffsetY )
    viewOffsetX = viewOffsetX or gameState.VIEW_OFFSET_X
    viewOffsetY = viewOffsetY or gameState.VIEW_OFFSET_Y
    viewWidth = viewWidth or gameState.VIEW_WIDTH
    viewHeight = viewHeight or gameState.VIEW_HEIGHT
    boardOffsetX = boardOffsetX or gameState.boardOffsetX
    boardOffsetY = boardOffsetY or gameState.boardOffsetY
    local boardX
    if viewX >= viewOffsetX and viewX <= viewOffsetX + viewWidth then
        boardX = viewX - viewOffsetX + boardOffsetX
    else
        boardX = math.huge
    end
    local boardY
    if viewY >= viewOffsetY and viewY <= viewOffsetY + viewHeight then
        boardY = viewY - viewOffsetY + boardOffsetY
    else
        boardY = math.huge
    end
    return boardX, boardY
end

function love.filedropped( file )
    local valid, weight, cleared, cells = mine.loadFromFile( file )
    if valid then
        gameState.mineWeight = weight
        gameState.cleared = cleared
        gameState.Cells = cells
        gameState.begun = true
        gameState.isGameOver = false
        local scoreStr = tostring(cleared)
        local pad = 7 - string.len(scoreStr)
        scoreStr = string.rep("0",pad) .. scoreStr
        Theory.idDict.scoreLabel:setText(scoreStr)
    end
end

function love.quit()
    if not gameState.isGameOver and gameState.begun then
		local result = love.window.showMessageBox( "Quit", "Are you sure you want to quit?", {
			"Quit",
			"Save and Quit",
			"Cancel",
			escapebutton = 3,
			enterbutton = 2,
			},"warning")
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
			mine.saveToFile( filename )
			love.window.showMessageBox("Saved", 'game saved as "' .. filename .. '"' )
        end
    end
    mine.saveConfig()
	return false
end

local savePack = {
    state ={ [0]=10, [1]=20, [2]=30 };
    value = {
		[" "]=0, [0]=" ";
		["1"]=1, [1]="1";
		["2"]=2, [2]="2";
		["3"]=3, [3]="3";
		["4"]=4, [4]="4";
		["5"]=5, [5]="5";
		["6"]=6, [6]="6";
		["7"]=7, [7]="7";
		["8"]=8, [8]="8";
		["*"]=9, [9]="*";
	}
}

function mine.saveToFile( filename )
    local file = io.open(filename, "wb")
    file:write( love.data.pack("string", "nn", gameState.mineWeight, gameState.cleared))
    for y, row in pairs(gameState.Cells) do
        file:write(love.data.pack("string","j",y))
        for x, cell in pairs(row) do
            file:write(love.data.pack("string","j",x))
            file:write(love.data.pack("string","B", savePack.state[cell.state] + savePack.value[cell.value]))
        end
        file:write(love.data.pack("string","jB",0,0))
    end
    file:close()
end

function mine.loadFromFile( file )
    if not file:open("r") then
		love.window.showMessageBox( "Error Reading", "could not load the provided file", "error")
		return false
    end
    local header = file:read(love.data.getPackedSize("nn"))
    local valid, weight, cleared = pcall( love.data.unpack, "nn", header)
    if not valid then
        love.window.showMessageBox( "Error Reading", "bad file header.", "error")
        return false
    end
    local cells = {}
    local sizej = love.data.getPackedSize("j")
    local sizejB = love.data.getPackedSize("jB")
    local seen = 0
    local data, good, y, x, d
    repeat
        data = file:read(sizej)
        good, y = pcall( love.data.unpack, "j", data )
        if good and y then
            cells[y] = {}
            repeat
                data = file:read(sizejB)
                good, x, d = pcall( love.data.unpack, "jB", data )
                if not good or not x or not d then
                    love.window.showMessageBox( "Error Reading", "corruption detected loading aborted", "error")
                    return false
                elseif d ~= 0 then
                    if d < 10 or d > 39 then
                        love.window.showMessageBox( "Error Reading", "corruption detected loading aborted", "error")
                        return false
                    end
                    cells[y][x] = {
                        state = math.floor(d/10 - 1);
                        value = savePack.value[d % 10];
                        anim = 0;
                    }
                    print("["..cells[y][x].state .. "," .. cells[y][x].value .."]")
                    if cells[y][x].state == STATE.SEEN then
                        seen = seen + 1
                    end
                end
            until d == 0
        end
    until not good or not y
    if seen ~= cleared then
        love.window.showMessageBox( "Invalid Board State",
        "board state contained discrepancies.",
        "error")
        return false
    end
    return true, weight, cleared, cells
end

function mine.saveConfig()
    local filename = "unbounded.config"
    local file = io.open( filename, "wb" )
    file:write( love.data.pack( "string", "HBBBBBBBBBBBB",
        colorIndex,
        colorSettings[-2], colorSettings[-1], colorSettings[0], colorSettings[1],
        colorSettings[2], colorSettings[3], colorSettings[4], colorSettings[5],
        colorSettings[6], colorSettings[7], colorSettings[8], gameState.doCheckers and 1 or 0))
    file:close()
end

function mine.loadConfig()
    local filename = "unbounded.config"
    local file = io.open( filename, "r" )
    if not file then return end
    local size = love.data.getPackedSize("HBBBBBBBBBBBB");
    local config = file:read(size)
    local valid
    valid, colorIndex, colorSettings[-2], colorSettings[-1], colorSettings[0], colorSettings[1],
    colorSettings[2], colorSettings[3], colorSettings[4], colorSettings[5], colorSettings[6],
    colorSettings[7], colorSettings[8], gameState.doCheckers = pcall( love.data.unpack, "HBBBBBBBBBBBB", config)
    gameState.doCheckers = gameState.doCheckers == 1
    if not valid then
        commands.setToDefault()
    end
end